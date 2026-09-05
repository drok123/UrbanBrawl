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
	for body in get_overlapping_bodies():
		if body is Node3D:
			_try_hit(body as Node3D)

func _on_body_entered(body: Node3D) -> void:
	_try_hit(body)

func _try_hit(body: Node3D) -> void:
	if _ability == null or _source == null:
		return
	if body == _source or _already_hit.has(body):
		return
	if not body.is_in_group("damageable") or not body.has_method("apply_hit"):
		return

	_already_hit.append(body)

	var push: Vector3 = body.global_position - _source.global_position
	push.y = 0.0
	if push.length_squared() < 0.001:
		push = -_source.global_transform.basis.z
	push = push.normalized()

	body.call(
		"apply_hit",
		_ability.damage,
		push * _ability.knockback,
		_ability.wall_stun_window,
		_ability.hitstop
	)

	var impact_position: Vector3 = body.global_position + Vector3.UP * 0.7
	hit_landed.emit(impact_position, _ability.hitstop)
