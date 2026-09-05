extends CharacterBody3D

@export var move_speed: float = 7.0
@export var acceleration: float = 30.0
@export var rotation_speed: float = 18.0

var aim_point: Vector3 = Vector3.ZERO

func _physics_process(delta: float) -> void:
	_update_movement(delta)
	_update_aim(delta)
	move_and_slide()

func _update_movement(delta: float) -> void:
	var input := Vector2.ZERO
	if Input.is_key_pressed(KEY_A):
		input.x -= 1.0
	if Input.is_key_pressed(KEY_D):
		input.x += 1.0
	if Input.is_key_pressed(KEY_W):
		input.y -= 1.0
	if Input.is_key_pressed(KEY_S):
		input.y += 1.0

	input = input.normalized()
	var desired := Vector3(input.x, 0.0, input.y) * move_speed
	velocity.x = move_toward(velocity.x, desired.x, acceleration * delta)
	velocity.z = move_toward(velocity.z, desired.z, acceleration * delta)
	velocity.y = 0.0

func _update_aim(delta: float) -> void:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return

	var mouse := get_viewport().get_mouse_position()
	var ray_origin := camera.project_ray_origin(mouse)
	var ray_end := ray_origin + camera.project_ray_normal(mouse) * 1000.0
	var query := PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	query.exclude = [self]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return

	aim_point = hit.position
	var flat_direction := aim_point - global_position
	flat_direction.y = 0.0
	if flat_direction.length_squared() < 0.0001:
		return

	var target_yaw := atan2(-flat_direction.x, -flat_direction.z)
	rotation.y = lerp_angle(rotation.y, target_yaw, clamp(rotation_speed * delta, 0.0, 1.0))
