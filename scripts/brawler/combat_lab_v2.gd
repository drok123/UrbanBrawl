extends Node3D

const Fighter = preload("res://scripts/brawler/brawler_fighter.gd")

const SPAWN_POINT := Vector3(0.0, 1.05, 5.5)

var player
var camera: Camera3D
var camera_center := Vector3.ZERO


func _ready() -> void:
	_build_environment()
	_build_movement_course()
	_build_camera()
	_build_hud()
	_spawn_brick()


func _process(delta: float) -> void:
	_update_camera(delta)


func _spawn_brick() -> void:
	player = Fighter.new()
	player.name = "BrickMovementTest"
	player.configure(Fighter.HERO_BRICK, true, self, SPAWN_POINT)
	add_child(player)


func get_opponents(_source) -> Array:
	return []


func get_nearest_enemy(_source):
	return null


func respawn_fighter(fighter) -> void:
	if fighter == player:
		fighter.reset_fighter(SPAWN_POINT)


func _build_environment() -> void:
	var world_environment := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.018, 0.024, 0.035)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.34, 0.41, 0.54)
	environment.ambient_light_energy = 0.9
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world_environment.environment = environment
	add_child(world_environment)

	var key_light := DirectionalLight3D.new()
	key_light.rotation_degrees = Vector3(-58.0, -32.0, 0.0)
	key_light.light_color = Color(1.0, 0.82, 0.68)
	key_light.light_energy = 1.25
	key_light.shadow_enabled = true
	add_child(key_light)

	var fill_light := OmniLight3D.new()
	fill_light.position = Vector3(0.0, 8.0, 1.0)
	fill_light.light_color = Color(0.28, 0.48, 1.0)
	fill_light.light_energy = 3.2
	fill_light.omni_range = 28.0
	add_child(fill_light)


func _build_movement_course() -> void:
	_add_static_box("LabFloor", Vector3(0.0, -0.25, 0.0), Vector3(28.0, 0.5, 20.0), Color(0.075, 0.085, 0.105))

	var wall_color := Color(0.17, 0.19, 0.23)
	_add_static_box("NorthWall", Vector3(0.0, 0.65, -10.0), Vector3(28.0, 1.3, 0.4), wall_color)
	_add_static_box("SouthWall", Vector3(0.0, 0.65, 10.0), Vector3(28.0, 1.3, 0.4), wall_color)
	_add_static_box("WestWall", Vector3(-14.0, 0.65, 0.0), Vector3(0.4, 1.3, 20.0), wall_color)
	_add_static_box("EastWall", Vector3(14.0, 0.65, 0.0), Vector3(0.4, 1.3, 20.0), wall_color)

	_add_visual_box(Vector3(0.0, 0.015, 0.0), Vector3(0.10, 0.03, 19.0), Color(0.88, 0.25, 0.12))
	_add_visual_box(Vector3(0.0, 0.016, 0.0), Vector3(27.0, 0.03, 0.055), Color(0.18, 0.55, 0.92))

	var marker_color := Color(0.19, 0.62, 0.72)
	_add_visual_box(Vector3(-5.0, 0.018, -6.0), Vector3(2.4, 0.035, 0.08), marker_color)
	_add_visual_box(Vector3(-5.0, 0.018, -3.0), Vector3(2.4, 0.035, 0.08), marker_color)
	_add_visual_box(Vector3(-5.0, 0.018, 0.0), Vector3(2.4, 0.035, 0.08), marker_color)
	_add_visual_box(Vector3(-5.0, 0.018, 3.0), Vector3(2.4, 0.035, 0.08), marker_color)
	_add_visual_box(Vector3(-5.0, 0.018, 6.0), Vector3(2.4, 0.035, 0.08), marker_color)

	var obstacle_color := Color(0.30, 0.33, 0.38)
	_add_static_box("SlalomA", Vector3(4.0, 0.7, -4.5), Vector3(1.4, 1.4, 1.4), obstacle_color)
	_add_static_box("SlalomB", Vector3(7.0, 0.7, -1.5), Vector3(1.4, 1.4, 1.4), obstacle_color)
	_add_static_box("SlalomC", Vector3(4.0, 0.7, 1.5), Vector3(1.4, 1.4, 1.4), obstacle_color)
	_add_static_box("SlalomD", Vector3(7.0, 0.7, 4.5), Vector3(1.4, 1.4, 1.4), obstacle_color)


func _build_camera() -> void:
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 19.5
	camera.position = Vector3(0.0, 16.0, 15.5)
	add_child(camera)
	camera.current = true
	camera.look_at(Vector3.ZERO, Vector3.UP)


func _update_camera(delta: float) -> void:
	if player == null or camera == null:
		return
	var target_center: Vector3 = player.global_position
	target_center.y = 0.0
	camera_center = camera_center.lerp(target_center * 0.22, minf(1.0, delta * 4.0))
	camera.position = camera_center + Vector3(0.0, 16.0, 15.5)
	camera.look_at(camera_center + Vector3(0.0, 0.4, 0.0), Vector3.UP)


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)

	var panel := ColorRect.new()
	panel.position = Vector2(20.0, 18.0)
	panel.size = Vector2(530.0, 152.0)
	panel.color = Color(0.018, 0.023, 0.034, 0.90)
	layer.add_child(panel)

	var title := Label.new()
	title.position = Vector2(40.0, 34.0)
	title.text = "COMBAT LAB V2 · CHECKPOINT 1"
	title.add_theme_font_size_override("font_size", 26)
	layer.add_child(title)

	var goal := Label.new()
	goal.position = Vector2(40.0, 75.0)
	goal.text = "MOVEMENT QUALITY GATE\nMove · stop · reverse · circle · aim · dash through the slalom"
	goal.add_theme_font_size_override("font_size", 18)
	layer.add_child(goal)

	var controls := Label.new()
	controls.position = Vector2(40.0, 130.0)
	controls.text = "WASD move  ·  mouse aim  ·  SPACE dash"
	controls.add_theme_font_size_override("font_size", 16)
	layer.add_child(controls)

	var status := Label.new()
	status.position = Vector2(1090.0, 30.0)
	status.text = "ONE HERO\nNO BOTS\nNO ABILITY EXPANSION"
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	status.size = Vector2(470.0, 100.0)
	status.add_theme_color_override("font_color", Color(0.35, 0.78, 0.88))
	status.add_theme_font_size_override("font_size", 17)
	layer.add_child(status)


func _add_static_box(node_name: String, at: Vector3, size: Vector3, color: Color) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = at

	var mesh := BoxMesh.new()
	mesh.size = size
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.9
	mesh.material = material
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = mesh
	body.add_child(mesh_instance)

	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	add_child(body)
	return body


func _add_visual_box(at: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.75
	mesh.material = material
	var instance := MeshInstance3D.new()
	instance.position = at
	instance.mesh = mesh
	add_child(instance)
	return instance
