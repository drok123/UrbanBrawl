class_name MeleeHitbox3D
extends Area3D

signal hit_landed(impact_position: Vector3, hitstop: float)

var _ability: CombatAbility
var _source: Node3D
var _already_hit: Array[Node3D] = []

@onready var _collision_shape: CollisionShape3D = $CollisionShape3D

func _ready() -> void:
	monitoring = false
	monitorable = false
	body_entered.connect(_on_body_entered)

func activate(ability: CombatAbility, source: Node3D) -> void:
	_ability = ability
	_source = source
	_already_hit.clear()

	if ability.mode == CombatAbility.AbilityMode.RANGED:
		monitoring = false
		_fire_ranged()
		_ability = null
		_source = null
		return

	var sphere: SphereShape3D = _collision_shape.shape as SphereShape3D
	if sphere != null:
		sphere.radius = ability.radius

	position = Vector3(0.0, 0.0, -ability.range_distance)
	monitoring = true
	call_deferred("_resolve_existing_overlaps")

func deactivate() -> void:
	monitoring = false
	_already_hit.clear()
	_ability = null
	_source = null

func _resolve_existing_overlaps() -> void:
	if not monitoring:
		return
	for body: Node3D in get_overlapping_bodies():
		_try_hit(body)

func _on_body_entered(body: Node3D) -> void:
	_try_hit(body)

func _try_hit(body: Node3D) -> void:
	if _ability == null or _source == null:
		return
	if body == _source or _already_hit.has(body):
		return
	if not body.is_in_group("damageable"):
		return

	var supports_new_pipeline: bool = body.has_method("receive_hit")
	var supports_legacy_pipeline: bool = body.has_method("apply_hit")
	if not supports_new_pipeline and not supports_legacy_pipeline:
		return

	_already_hit.append(body)

	var push: Vector3 = body.global_position - _source.global_position
	push.y = 0.0
	if push.length_squared() < 0.001:
		push = -_source.global_transform.basis.z
	push = push.normalized()

	var combat_hit: CombatHit = _build_combat_hit(push)
	_apply_hit_to_body(body, combat_hit)

	var impact_position: Vector3 = body.global_position + Vector3.UP * 0.7
	hit_landed.emit(impact_position, _ability.hitstop)

func _fire_ranged() -> void:
	if _ability == null or _source == null or _source.get_world_3d() == null:
		return

	var forward: Vector3 = -_source.global_transform.basis.z
	forward.y = 0.0
	if forward.length_squared() < 0.001:
		forward = Vector3.FORWARD
	forward = forward.normalized()

	var origin: Vector3 = _source.global_position + Vector3.UP * 0.72 + forward * 0.35
	var end: Vector3 = origin + forward * maxf(_ability.range_distance, 0.5)
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(origin, end)
	query.exclude = [_source]
	query.collision_mask = collision_mask
	query.collide_with_areas = false
	query.collide_with_bodies = true

	var result: Dictionary = _source.get_world_3d().direct_space_state.intersect_ray(query)
	var impact_position: Vector3 = end
	var landed_damageable_hit: bool = false

	if not result.is_empty():
		var result_position: Variant = result.get("position", end)
		if result_position is Vector3:
			impact_position = result_position as Vector3

		var collider_value: Variant = result.get("collider", null)
		var body: Node3D = collider_value as Node3D
		if body != null and body != _source and body.is_in_group("damageable"):
			var supports_new_pipeline: bool = body.has_method("receive_hit")
			var supports_legacy_pipeline: bool = body.has_method("apply_hit")
			if supports_new_pipeline or supports_legacy_pipeline:
				var push: Vector3 = forward
				var combat_hit: CombatHit = _build_combat_hit(push)
				_apply_hit_to_body(body, combat_hit)
				landed_damageable_hit = true

	_spawn_tracer(origin, impact_position)
	if landed_damageable_hit:
		hit_landed.emit(impact_position, _ability.hitstop)

func _build_combat_hit(push_direction: Vector3) -> CombatHit:
	var combat_hit: CombatHit = CombatHit.new()
	combat_hit.source = _source
	combat_hit.ability_id = _ability.ability_id
	combat_hit.weapon_id = _ability.weapon_id
	combat_hit.damage_type = _ability.damage_type
	combat_hit.hit_location = _ability.hit_location
	combat_hit.damage = _ability.damage
	combat_hit.impulse = push_direction.normalized() * _ability.knockback
	combat_hit.wall_stun_window = _ability.wall_stun_window
	combat_hit.hitstop = _ability.hitstop
	combat_hit.gore_power = _ability.gore_power

	if _source.has_method("get_weapon_rarity_id"):
		var rarity_value: Variant = _source.call("get_weapon_rarity_id")
		combat_hit.weapon_rarity = StringName(str(rarity_value))
	elif _source.has_meta("weapon_rarity_id"):
		combat_hit.weapon_rarity = StringName(str(_source.get_meta("weapon_rarity_id")))
	return combat_hit

func _apply_hit_to_body(body: Node3D, combat_hit: CombatHit) -> void:
	if body.has_method("receive_hit"):
		body.call("receive_hit", combat_hit)
	elif body.has_method("apply_hit"):
		body.call(
			"apply_hit",
			combat_hit.damage,
			combat_hit.impulse,
			combat_hit.wall_stun_window,
			combat_hit.hitstop
		)

func _spawn_tracer(origin: Vector3, end: Vector3) -> void:
	var distance: float = origin.distance_to(end)
	if distance <= 0.01:
		return

	var tracer: MeshInstance3D = MeshInstance3D.new()
	tracer.name = "HitscanTracer"
	var box: BoxMesh = BoxMesh.new()
	box.size = Vector3(0.025, 0.025, distance)
	tracer.mesh = box

	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = Color(1.0, 0.82, 0.28, 0.92)
	material.emission_enabled = true
	material.emission = Color(1.0, 0.62, 0.12, 1.0)
	material.emission_energy_multiplier = 2.6
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	tracer.material_override = material

	var parent_node: Node = _source.get_parent()
	if parent_node == null:
		return
	parent_node.add_child(tracer)
	tracer.global_position = origin.lerp(end, 0.5)
	tracer.look_at(end, Vector3.UP)

	var tween: Tween = tracer.create_tween()
	tween.tween_interval(0.045)
	tween.tween_property(tracer, "scale", Vector3(0.2, 0.2, 1.0), 0.04)
	tween.tween_callback(Callable(tracer, "queue_free"))
