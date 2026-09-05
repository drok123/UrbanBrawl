extends CharacterBody3D

@export var max_health: float = 300.0
@export var knockback_drag: float = 13.0

var health: float
var spawn_position: Vector3
var hit_scale_time := 0.09

@onready var mesh: MeshInstance3D = $Mesh
@onready var health_label: Label3D = $HealthLabel

func _ready() -> void:
	add_to_group("damageable")
	health = max_health
	spawn_position = global_position
	_update_health_label()

func _physics_process(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, knockback_drag * delta)
	velocity.z = move_toward(velocity.z, 0.0, knockback_drag * delta)
	velocity.y = 0.0
	move_and_slide()

func apply_hit(damage: float, impulse: Vector3 = Vector3.ZERO) -> void:
	health = max(health - damage, 0.0)
	velocity += Vector3(impulse.x, 0.0, impulse.z)
	_hit_feedback()
	_update_health_label()

	if health <= 0.0:
		_reset_dummy()

func _hit_feedback() -> void:
	var tween := create_tween()
	tween.tween_property(mesh, "scale", Vector3(1.18, 0.78, 1.18), hit_scale_time)
	tween.tween_property(mesh, "scale", Vector3.ONE, hit_scale_time)

func _reset_dummy() -> void:
	health = max_health
	velocity = Vector3.ZERO
	global_position = spawn_position
	_update_health_label()

func _update_health_label() -> void:
	if health_label:
		health_label.text = "%d / %d" % [int(health), int(max_health)]
