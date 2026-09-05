extends Camera3D

@export var target_path: NodePath
@export var height: float = 15.0
@export var distance: float = 13.0
@export var follow_speed: float = 8.0

@onready var target: Node3D = get_node_or_null(target_path)

func _ready() -> void:
	_update_camera(1.0)

func _process(delta: float) -> void:
	_update_camera(delta)

func _update_camera(delta: float) -> void:
	if target == null:
		return

	var desired := target.global_position + Vector3(0.0, height, distance)
	global_position = global_position.lerp(desired, clamp(follow_speed * delta, 0.0, 1.0))
	look_at(target.global_position, Vector3.UP)
