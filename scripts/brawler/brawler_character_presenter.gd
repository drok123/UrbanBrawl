extends Node3D

## Replaceable presentation layer for a brawler fighter.
##
## The fighter owns simulation state, collision, damage, and movement. This node
## owns meshes, materials, labels, pose offsets, and eventually AnimationTree.

var visual_root: Node3D
var body_material: StandardMaterial3D
var accent_material: StandardMaterial3D
var right_arm: MeshInstance3D
var left_arm: MeshInstance3D
var torso: MeshInstance3D
var name_label: Label3D


func _ready() -> void:
	initialize()


func initialize() -> void:
	if visual_root == null:
		_build_debug_visual()


func set_palette(body: Color, accent: Color) -> void:
	if body_material != null:
		body_material.albedo_color = body
	if accent_material != null:
		accent_material.albedo_color = accent


func set_nameplate(text: String) -> void:
	if name_label != null:
		name_label.text = text


func update_presentation(
	delta: float,
	facing: Vector3,
	planar_velocity: Vector3,
	move_speed: float,
	attack_kind: String,
	is_dashing: bool,
	is_flashing: bool
) -> void:
	if visual_root == null:
		return

	var target_yaw: float = atan2(-facing.x, -facing.z)
	visual_root.rotation.y = lerp_angle(visual_root.rotation.y, target_yaw, minf(1.0, delta * 20.0))

	var speed_ratio: float = clampf(planar_velocity.length() / maxf(0.01, move_speed), 0.0, 1.5)
	var time_seconds: float = float(Time.get_ticks_msec()) * 0.001
	visual_root.position.y = sin(time_seconds * 9.0) * 0.025 * speed_ratio

	right_arm.position.z = lerpf(right_arm.position.z, 0.0, minf(1.0, delta * 22.0))
	left_arm.position.z = lerpf(left_arm.position.z, 0.0, minf(1.0, delta * 22.0))
	torso.rotation.z = lerpf(torso.rotation.z, 0.0, minf(1.0, delta * 16.0))

	match attack_kind:
		"quick":
			right_arm.position.z = -0.38
			torso.rotation.z = -0.08
		"heavy":
			right_arm.position.z = -0.28
			left_arm.position.z = -0.22
			torso.rotation.z = -0.15
		"grab":
			right_arm.position.z = -0.28
			left_arm.position.z = -0.28

	var target_lean: float = -0.20 if is_dashing else 0.0
	var lean_speed: float = 24.0 if is_dashing else 18.0
	visual_root.rotation.x = lerpf(visual_root.rotation.x, target_lean, minf(1.0, delta * lean_speed))

	body_material.emission_enabled = is_flashing
	if is_flashing:
		body_material.emission = Color(1.0, 0.92, 0.78)
		body_material.emission_energy_multiplier = 1.5


func _build_debug_visual() -> void:
	visual_root = Node3D.new()
	visual_root.name = "DebugHumanoid"
	add_child(visual_root)

	body_material = StandardMaterial3D.new()
	body_material.roughness = 0.78
	accent_material = StandardMaterial3D.new()
	accent_material.roughness = 0.72

	torso = _make_box(Vector3(0.0, 0.28, 0.0), Vector3(0.74, 0.82, 0.42), body_material)
	_make_box(Vector3(0.0, -0.18, 0.0), Vector3(0.62, 0.26, 0.36), accent_material)
	_make_sphere(Vector3(0.0, 0.93, -0.02), Vector3(0.42, 0.46, 0.42), body_material)
	left_arm = _make_box(Vector3(-0.56, 0.28, 0.0), Vector3(0.22, 0.72, 0.22), body_material)
	right_arm = _make_box(Vector3(0.56, 0.28, 0.0), Vector3(0.22, 0.72, 0.22), body_material)
	_make_box(Vector3(-0.22, -0.67, 0.0), Vector3(0.27, 0.74, 0.29), body_material)
	_make_box(Vector3(0.22, -0.67, 0.0), Vector3(0.27, 0.74, 0.29), body_material)
	_make_box(Vector3(0.0, 0.35, -0.24), Vector3(0.28, 0.16, 0.08), accent_material)

	name_label = Label3D.new()
	name_label.position = Vector3(0.0, 1.55, 0.0)
	name_label.font_size = 42
	name_label.outline_size = 10
	name_label.pixel_size = 0.0075
	name_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(name_label)


func _make_box(at: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = material
	var instance := MeshInstance3D.new()
	instance.position = at
	instance.mesh = mesh
	visual_root.add_child(instance)
	return instance


func _make_sphere(at: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	mesh.material = material
	var instance := MeshInstance3D.new()
	instance.position = at
	instance.scale = size
	instance.mesh = mesh
	visual_root.add_child(instance)
	return instance
