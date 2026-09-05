extends CharacterBody3D

@export var move_speed: float = 7.0
@export var acceleration: float = 30.0
@export var rotation_speed: float = 18.0

@export_category("Combat")
@export var basic_damage: float = 55.0
@export var basic_range: float = 1.55
@export var basic_radius: float = 0.95
@export var basic_cooldown: float = 0.32
@export var basic_knockback: float = 4.5
@export var cleave_damage: float = 110.0
@export var cleave_range: float = 1.65
@export var cleave_radius: float = 1.45
@export var cleave_cooldown: float = 1.8
@export var cleave_knockback: float = 8.0
@export var dash_speed: float = 18.0
@export var dash_duration: float = 0.14
@export var dash_cooldown: float = 0.85

var aim_point: Vector3 = Vector3.ZERO
var basic_timer: float = 0.0
var cleave_timer: float = 0.0
var dash_timer: float = 0.0
var dash_time_left: float = 0.0
var dash_direction: Vector3 = Vector3.ZERO
var last_move_direction: Vector3 = Vector3.FORWARD

func _physics_process(delta: float) -> void:
	basic_timer = max(basic_timer - delta, 0.0)
	cleave_timer = max(cleave_timer - delta, 0.0)
	dash_timer = max(dash_timer - delta, 0.0)
	dash_time_left = max(dash_time_left - delta, 0.0)

	_update_aim(delta)
	_handle_combat_input()

	if dash_time_left > 0.0:
		velocity = dash_direction * dash_speed
	else:
		_update_movement(delta)

	move_and_slide()

func _update_movement(delta: float) -> void:
	var input: Vector2 = _movement_input()
	if input.length_squared() > 0.0:
		last_move_direction = Vector3(input.x, 0.0, input.y).normalized()

	var desired: Vector3 = Vector3(input.x, 0.0, input.y) * move_speed
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
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and basic_timer <= 0.0:
		_basic_attack()

	if Input.is_key_pressed(KEY_Q) and cleave_timer <= 0.0:
		_cleave()

	if Input.is_key_pressed(KEY_SPACE) and dash_timer <= 0.0 and dash_time_left <= 0.0:
		_start_dash()

func _basic_attack() -> void:
	basic_timer = basic_cooldown
	var forward: Vector3 = -global_transform.basis.z.normalized()
	_perform_melee_hit(forward, basic_range, basic_radius, basic_damage, basic_knockback)
	_pulse_player(Vector3(1.06, 0.94, 1.06), 0.06)

func _cleave() -> void:
	cleave_timer = cleave_cooldown
	var forward: Vector3 = -global_transform.basis.z.normalized()
	_perform_melee_hit(forward, cleave_range, cleave_radius, cleave_damage, cleave_knockback)
	_pulse_player(Vector3(1.14, 0.86, 1.14), 0.08)

func _start_dash() -> void:
	dash_timer = dash_cooldown
	dash_time_left = dash_duration
	var input: Vector2 = _movement_input()
	if input.length_squared() > 0.0:
		dash_direction = Vector3(input.x, 0.0, input.y).normalized()
	else:
		dash_direction = -global_transform.basis.z.normalized()

func _perform_melee_hit(forward: Vector3, range_distance: float, radius: float, damage: float, knockback: float) -> void:
	var shape: SphereShape3D = SphereShape3D.new()
	shape.radius = radius

	var center: Vector3 = global_position + forward * range_distance
	center.y = global_position.y

	var query: PhysicsShapeQueryParameters3D = PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = Transform3D(Basis.IDENTITY, center)
	query.exclude = [get_rid()]
	query.collide_with_areas = true
	query.collide_with_bodies = true

	var hits: Array[Dictionary] = get_world_3d().direct_space_state.intersect_shape(query, 32)
	var hit_nodes: Dictionary = {}
	for hit: Dictionary in hits:
		var collider: Node3D = hit.get("collider") as Node3D
		if collider == null or collider == self:
			continue
		if hit_nodes.has(collider):
			continue
		hit_nodes[collider] = true
		if collider.is_in_group("damageable") and collider.has_method("apply_hit"):
			var push: Vector3 = collider.global_position - global_position
			push.y = 0.0
			if push.length_squared() < 0.001:
				push = forward
			collider.call("apply_hit", damage, push.normalized() * knockback)

func _pulse_player(target_scale: Vector3, duration: float) -> void:
	var mesh: MeshInstance3D = get_node_or_null("Mesh") as MeshInstance3D
	if mesh == null:
		return
	var tween: Tween = create_tween()
	tween.tween_property(mesh, "scale", target_scale, duration)
	tween.tween_property(mesh, "scale", Vector3.ONE, duration)

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

	var target_yaw: float = atan2(-flat_direction.x, -flat_direction.z)
	rotation.y = lerp_angle(rotation.y, target_yaw, clamp(rotation_speed * delta, 0.0, 1.0))
