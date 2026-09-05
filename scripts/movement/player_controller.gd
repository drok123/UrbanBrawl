extends CharacterBody3D

@export var move_speed: float = 7.0
@export var acceleration: float = 30.0
@export var rotation_speed: float = 18.0

@export_category("Dash")
@export var dash_speed: float = 18.0
@export var dash_duration: float = 0.14
@export var dash_cooldown: float = 0.85

enum CombatPhase {
	READY,
	WINDUP,
	ACTIVE,
	RECOVERY,
}

var basic_ability: CombatAbility = preload("res://resources/abilities/basic_attack.tres") as CombatAbility
var cleave_ability: CombatAbility = preload("res://resources/abilities/heavy_cleave.tres") as CombatAbility
var charge_ability: CombatAbility = preload("res://resources/abilities/shoulder_charge.tres") as CombatAbility

var aim_point: Vector3 = Vector3.ZERO
var last_move_direction: Vector3 = Vector3.FORWARD

var _current_ability: CombatAbility = null
var _combat_phase: CombatPhase = CombatPhase.READY
var _phase_time_left: float = 0.0
var _ability_forward: Vector3 = Vector3.FORWARD
var _cooldowns: Dictionary = {}

var _dash_cooldown_left: float = 0.0
var _dash_time_left: float = 0.0
var _dash_direction: Vector3 = Vector3.ZERO
var _hitstop_left: float = 0.0

var _hitbox: MeleeHitbox3D = null
var _telegraph: MeshInstance3D = null

func _ready() -> void:
	_cooldowns[basic_ability.ability_id] = 0.0
	_cooldowns[cleave_ability.ability_id] = 0.0
	_cooldowns[charge_ability.ability_id] = 0.0
	_setup_hitbox()

func _physics_process(delta: float) -> void:
	if _hitstop_left > 0.0:
		_hitstop_left = maxf(_hitstop_left - delta, 0.0)
		return

	_tick_cooldowns(delta)
	_dash_cooldown_left = maxf(_dash_cooldown_left - delta, 0.0)
	_dash_time_left = maxf(_dash_time_left - delta, 0.0)

	_update_aim(delta)
	_advance_combat_state(delta)
	_handle_combat_input()

	if _dash_time_left > 0.0:
		velocity = _dash_direction * dash_speed
	elif _current_ability != null and _combat_phase == CombatPhase.ACTIVE and _current_ability.mode == CombatAbility.AbilityMode.CHARGE:
		velocity = _ability_forward * _current_ability.charge_speed
	else:
		var movement_multiplier: float = 1.0
		if _current_ability != null:
			movement_multiplier = _current_ability.movement_multiplier
		_update_movement(delta, movement_multiplier)

	move_and_slide()
	_check_charge_wall_collision()

func _tick_cooldowns(delta: float) -> void:
	for key in _cooldowns.keys():
		_cooldowns[key] = maxf(float(_cooldowns[key]) - delta, 0.0)

func _update_movement(delta: float, speed_multiplier: float = 1.0) -> void:
	var input: Vector2 = _movement_input()
	if input.length_squared() > 0.0:
		last_move_direction = Vector3(input.x, 0.0, input.y).normalized()

	var desired: Vector3 = Vector3(input.x, 0.0, input.y) * move_speed * speed_multiplier
	velocity.x = move_toward(velocity.x, desired.x, acceleration * delta)
	velocity.z = move_toward(velocity.z, desired.z, acceleration * delta)
	velocity.y = 0.0

func _movement_input() -> Vector2:
	var input: Vector2 = Vector2.ZERO
	if Input.is_key_pressed(KEY_A):
		input.x -= 1.0
	if Input.is_key_pressed(KEY_D):
		input.x += 1.0
	if Input.is_key_pressed(KEY_W):
		input.y -= 1.0
	if Input.is_key_pressed(KEY_S):
		input.y += 1.0
	return input.normalized()

func _handle_combat_input() -> void:
	if _current_ability != null or _dash_time_left > 0.0:
		return

	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and get_cooldown_remaining(&"basic") <= 0.0:
		_start_ability(basic_ability)
		return

	if Input.is_key_pressed(KEY_Q) and get_cooldown_remaining(&"cleave") <= 0.0:
		_start_ability(cleave_ability)
		return

	# E is used for the shoulder charge because W remains movement.
	if Input.is_key_pressed(KEY_E) and get_cooldown_remaining(&"charge") <= 0.0:
		_start_ability(charge_ability)
		return

	if Input.is_key_pressed(KEY_SPACE) and _dash_cooldown_left <= 0.0:
		_start_dash()

func _start_ability(ability: CombatAbility) -> void:
	if ability == null:
		return
	if get_cooldown_remaining(ability.ability_id) > 0.0:
		return

	_current_ability = ability
	_combat_phase = CombatPhase.WINDUP
	_phase_time_left = ability.windup
	_ability_forward = -global_transform.basis.z.normalized()
	_cooldowns[ability.ability_id] = ability.cooldown
	_show_telegraph(ability)

func _advance_combat_state(delta: float) -> void:
	if _current_ability == null:
		return

	_phase_time_left = maxf(_phase_time_left - delta, 0.0)
	if _phase_time_left > 0.0:
		return

	match _combat_phase:
		CombatPhase.WINDUP:
			_enter_active_phase()
		CombatPhase.ACTIVE:
			_enter_recovery_phase()
		CombatPhase.RECOVERY:
			_finish_ability()

func _enter_active_phase() -> void:
	if _current_ability == null:
		return

	_combat_phase = CombatPhase.ACTIVE
	_phase_time_left = _current_ability.active_time
	_hide_telegraph()
	_hitbox.activate(_current_ability, self)

	if _current_ability.self_impulse > 0.0:
		velocity += _ability_forward * _current_ability.self_impulse

	match _current_ability.ability_id:
		&"basic":
			_pulse_player(Vector3(1.06, 0.94, 1.06), 0.055)
		&"cleave":
			_pulse_player(Vector3(1.14, 0.86, 1.14), 0.075)
		&"charge":
			_pulse_player(Vector3(0.90, 1.02, 1.20), 0.07)

func _enter_recovery_phase() -> void:
	if _current_ability == null:
		return
	_hitbox.deactivate()
	_combat_phase = CombatPhase.RECOVERY
	_phase_time_left = _current_ability.recovery

func _finish_ability() -> void:
	_hitbox.deactivate()
	_hide_telegraph()
	_current_ability = null
	_combat_phase = CombatPhase.READY
	_phase_time_left = 0.0

func _check_charge_wall_collision() -> void:
	if _current_ability == null:
		return
	if _combat_phase != CombatPhase.ACTIVE or _current_ability.mode != CombatAbility.AbilityMode.CHARGE:
		return

	for index: int in range(get_slide_collision_count()):
		var collision: KinematicCollision3D = get_slide_collision(index)
		if collision == null:
			continue
		var normal: Vector3 = collision.get_normal()
		if absf(normal.y) > 0.5:
			continue
		var collider: Object = collision.get_collider()
		if collider is StaticBody3D:
			_enter_recovery_phase()
			return

func _start_dash() -> void:
	_dash_cooldown_left = dash_cooldown
	_dash_time_left = dash_duration
	var input: Vector2 = _movement_input()
	if input.length_squared() > 0.0:
		_dash_direction = Vector3(input.x, 0.0, input.y).normalized()
	else:
		_dash_direction = -global_transform.basis.z.normalized()

func _setup_hitbox() -> void:
	var hitbox: MeleeHitbox3D = MeleeHitbox3D.new()
	hitbox.name = "MeleeHitbox"
	hitbox.collision_layer = 0
	hitbox.collision_mask = 1

	var collision: CollisionShape3D = CollisionShape3D.new()
	collision.name = "CollisionShape3D"
	var sphere: SphereShape3D = SphereShape3D.new()
	sphere.radius = 1.0
	collision.shape = sphere
	hitbox.add_child(collision)
	add_child(hitbox)

	_hitbox = hitbox
	_hitbox.hit_landed.connect(_on_hit_landed)

func _on_hit_landed(impact_position: Vector3, hitstop: float) -> void:
	_hitstop_left = maxf(_hitstop_left, hitstop)
	_spawn_impact_fx(impact_position)

func _show_telegraph(ability: CombatAbility) -> void:
	_hide_telegraph()

	var telegraph: MeshInstance3D = MeshInstance3D.new()
	telegraph.name = "AbilityTelegraph"

	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = ability.telegraph_color
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	telegraph.material_override = material

	if ability.telegraph_shape == CombatAbility.TelegraphShape.BOX:
		var box: BoxMesh = BoxMesh.new()
		var length: float = maxf(ability.telegraph_length, ability.range_distance * 2.0)
		box.size = Vector3(ability.radius * 2.0, 0.025, length)
		telegraph.mesh = box
		telegraph.position = Vector3(0.0, -0.88, -length * 0.5)
	else:
		var disc: CylinderMesh = CylinderMesh.new()
		disc.top_radius = ability.radius
		disc.bottom_radius = ability.radius
		disc.height = 0.025
		disc.radial_segments = 48
		telegraph.mesh = disc
		telegraph.position = Vector3(0.0, -0.88, -ability.range_distance)

	add_child(telegraph)
	_telegraph = telegraph

func _hide_telegraph() -> void:
	if _telegraph != null and is_instance_valid(_telegraph):
		_telegraph.queue_free()
	_telegraph = null

func _spawn_impact_fx(world_position: Vector3) -> void:
	var fx: MeshInstance3D = MeshInstance3D.new()
	fx.name = "ImpactFlash"

	var sphere: SphereMesh = SphereMesh.new()
	sphere.radius = 0.16
	sphere.height = 0.32
	fx.mesh = sphere

	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = Color(1.0, 0.82, 0.42, 0.95)
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fx.material_override = material

	var parent_node: Node = get_parent()
	parent_node.add_child(fx)
	fx.global_position = world_position
	fx.scale = Vector3(0.25, 0.25, 0.25)

	var tween: Tween = fx.create_tween()
	tween.tween_property(fx, "scale", Vector3(1.45, 1.45, 1.45), 0.07)
	tween.tween_property(fx, "scale", Vector3(0.0, 0.0, 0.0), 0.08)
	tween.tween_callback(Callable(fx, "queue_free"))

func _pulse_player(target_scale: Vector3, duration: float) -> void:
	var mesh: MeshInstance3D = get_node_or_null("Mesh") as MeshInstance3D
	if mesh == null:
		return
	var tween: Tween = create_tween()
	tween.tween_property(mesh, "scale", target_scale, duration)
	tween.tween_property(mesh, "scale", Vector3.ONE, duration)

func get_cooldown_remaining(ability_id: StringName) -> float:
	return float(_cooldowns.get(ability_id, 0.0))

func get_cooldown_total(ability_id: StringName) -> float:
	match ability_id:
		&"basic":
			return basic_ability.cooldown
		&"cleave":
			return cleave_ability.cooldown
		&"charge":
			return charge_ability.cooldown
	return 0.0

func get_dash_cooldown_remaining() -> float:
	return _dash_cooldown_left

func get_combat_phase_name() -> String:
	return CombatPhase.keys()[_combat_phase]

func _update_aim(delta: float) -> void:
	var camera: Camera3D = get_viewport().get_camera_3d()
	if camera == null:
		return

	var mouse: Vector2 = get_viewport().get_mouse_position()
	var ray_origin: Vector3 = camera.project_ray_origin(mouse)
	var ray_end: Vector3 = ray_origin + camera.project_ray_normal(mouse) * 1000.0
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	query.exclude = [self]
	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return

	aim_point = hit.position
	var flat_direction: Vector3 = aim_point - global_position
	flat_direction.y = 0.0
	if flat_direction.length_squared() < 0.0001:
		return

	if _current_ability != null:
		return

	var target_yaw: float = atan2(-flat_direction.x, -flat_direction.z)
	rotation.y = lerp_angle(rotation.y, target_yaw, clampf(rotation_speed * delta, 0.0, 1.0))
