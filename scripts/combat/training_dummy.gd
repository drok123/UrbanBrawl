extends CharacterBody3D

@export var max_health: float = 300.0
@export var knockback_drag: float = 13.0
@export var wall_stun_duration: float = 0.75

var health: float = 0.0
var spawn_position: Vector3 = Vector3.ZERO
var hit_scale_time: float = 0.09
var _wall_stun_window_left: float = 0.0
var _stun_left: float = 0.0
var _hitstop_left: float = 0.0

@onready var mesh: MeshInstance3D = $Mesh
@onready var health_label: Label3D = $HealthLabel

func _ready() -> void:
	add_to_group("damageable")
	health = max_health
	spawn_position = global_position
	_update_health_label()

func _physics_process(delta: float) -> void:
	if _hitstop_left > 0.0:
		_hitstop_left = maxf(_hitstop_left - delta, 0.0)
		return

	_wall_stun_window_left = maxf(_wall_stun_window_left - delta, 0.0)
	_stun_left = maxf(_stun_left - delta, 0.0)

	if _stun_left > 0.0:
		velocity = Vector3.ZERO
		_update_health_label()
		return

	velocity.x = move_toward(velocity.x, 0.0, knockback_drag * delta)
	velocity.z = move_toward(velocity.z, 0.0, knockback_drag * delta)
	velocity.y = 0.0
	move_and_slide()
	_check_for_wall_stun()
	_update_health_label()

func apply_hit(
	damage: float,
	impulse: Vector3 = Vector3.ZERO,
	wall_stun_window: float = 0.0,
	hitstop: float = 0.0
) -> void:
	health = maxf(health - damage, 0.0)
	velocity += Vector3(impulse.x, 0.0, impulse.z)
	_wall_stun_window_left = maxf(_wall_stun_window_left, wall_stun_window)
	_hitstop_left = maxf(_hitstop_left, hitstop)
	_hit_feedback()
	_update_health_label()

	if health <= 0.0:
		_reset_dummy()

func _check_for_wall_stun() -> void:
	if _wall_stun_window_left <= 0.0:
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
			_trigger_wall_stun()
			return

func _trigger_wall_stun() -> void:
	_wall_stun_window_left = 0.0
	_stun_left = wall_stun_duration
	velocity = Vector3.ZERO
	var tween: Tween = create_tween()
	tween.tween_property(mesh, "scale", Vector3(1.28, 0.68, 1.28), 0.055)
	tween.tween_property(mesh, "scale", Vector3.ONE, 0.10)
	_update_health_label()

func _hit_feedback() -> void:
	var tween: Tween = create_tween()
	tween.tween_property(mesh, "scale", Vector3(1.18, 0.78, 1.18), hit_scale_time)
	tween.tween_property(mesh, "scale", Vector3.ONE, hit_scale_time)

func _reset_dummy() -> void:
	health = max_health
	velocity = Vector3.ZERO
	_wall_stun_window_left = 0.0
	_stun_left = 0.0
	_hitstop_left = 0.0
	global_position = spawn_position
	_update_health_label()

func _update_health_label() -> void:
	if health_label == null:
		return
	if _stun_left > 0.0:
		health_label.text = "STUNNED  %.1fs\n%d / %d" % [_stun_left, int(health), int(max_health)]
	else:
		health_label.text = "%d / %d" % [int(health), int(max_health)]
