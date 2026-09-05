class_name CombatAnimationDriver3D
extends Node3D

@export var body_color: Color = Color(0.72, 0.76, 0.82, 1.0)
@export var accent_color: Color = Color(0.22, 0.24, 0.28, 1.0)
@export var visual_offset: Vector3 = Vector3(0.0, -0.95, 0.0)
@export var pose_blend_speed: float = 15.0
@export var gait_speed: float = 9.0
@export var fallback_mesh_path: NodePath = NodePath("../Mesh")

var _actor: CharacterBody3D = null
var _model_root: Node3D = null
var _torso: Node3D = null
var _head: Node3D = null
var _left_shoulder: Node3D = null
var _right_shoulder: Node3D = null
var _left_elbow: Node3D = null
var _right_elbow: Node3D = null
var _left_hip: Node3D = null
var _right_hip: Node3D = null
var _left_knee: Node3D = null
var _right_knee: Node3D = null
var _weapon_anchor: Node3D = null

var _body_material: StandardMaterial3D = null
var _accent_material: StandardMaterial3D = null
var _time: float = 0.0
var _last_phase: String = ""
var _attack_style: StringName = &"unarmed_basic"

func _ready() -> void:
	_actor = get_parent() as CharacterBody3D
	_build_materials()
	_build_humanoid()
	_hide_legacy_visuals()

func _physics_process(delta: float) -> void:
	if _actor == null or _model_root == null:
		return

	_time += delta
	_adopt_held_weapon_visual()

	var phase: String = "READY"
	if _actor.has_method("get_combat_phase_name"):
		phase = str(_actor.call("get_combat_phase_name"))

	if phase == "WINDUP" and _last_phase != "WINDUP":
		_attack_style = _resolve_attack_style()

	_update_pose(delta, phase)
	_last_phase = phase

func get_weapon_anchor() -> Node3D:
	return _weapon_anchor

func _build_materials() -> void:
	_body_material = StandardMaterial3D.new()
	_body_material.albedo_color = body_color
	_body_material.roughness = 0.74

	_accent_material = StandardMaterial3D.new()
	_accent_material.albedo_color = accent_color
	_accent_material.roughness = 0.82

func _build_humanoid() -> void:
	_model_root = Node3D.new()
	_model_root.name = "ProceduralHumanoid"
	_model_root.position = visual_offset
	add_child(_model_root)

	_torso = Node3D.new()
	_torso.name = "Torso"
	_torso.position = Vector3(0.0, 1.38, 0.0)
	_model_root.add_child(_torso)
	_add_box(_torso, "Chest", Vector3(0.76, 0.82, 0.42), Vector3.ZERO, _body_material)
	_add_box(_torso, "Waist", Vector3(0.58, 0.28, 0.36), Vector3(0.0, -0.48, 0.0), _accent_material)

	_head = Node3D.new()
	_head.name = "Head"
	_head.position = Vector3(0.0, 1.98, 0.0)
	_model_root.add_child(_head)
	_add_sphere(_head, "HeadMesh", 0.28, Vector3.ZERO, _body_material)
	_add_box(_head, "Face", Vector3(0.24, 0.12, 0.06), Vector3(0.0, -0.02, -0.255), _accent_material)

	_left_shoulder = _build_arm("LeftArm", Vector3(-0.49, 1.66, 0.0), false)
	_right_shoulder = _build_arm("RightArm", Vector3(0.49, 1.66, 0.0), true)
	_left_hip = _build_leg("LeftLeg", Vector3(-0.22, 0.86, 0.0), false)
	_right_hip = _build_leg("RightLeg", Vector3(0.22, 0.86, 0.0), true)

func _build_arm(node_name: String, shoulder_position: Vector3, right_side: bool) -> Node3D:
	var shoulder: Node3D = Node3D.new()
	shoulder.name = node_name
	shoulder.position = shoulder_position
	_model_root.add_child(shoulder)
	_add_capsule(shoulder, "UpperArm", 0.115, 0.56, Vector3(0.0, -0.28, 0.0), _body_material)

	var elbow: Node3D = Node3D.new()
	elbow.name = "Elbow"
	elbow.position = Vector3(0.0, -0.55, 0.0)
	shoulder.add_child(elbow)
	_add_capsule(elbow, "Forearm", 0.10, 0.50, Vector3(0.0, -0.25, 0.0), _body_material)

	var hand: Node3D = Node3D.new()
	hand.name = "Hand"
	hand.position = Vector3(0.0, -0.50, 0.0)
	elbow.add_child(hand)
	_add_sphere(hand, "HandMesh", 0.13, Vector3.ZERO, _accent_material)

	if right_side:
		_right_elbow = elbow
		_weapon_anchor = Node3D.new()
		_weapon_anchor.name = "WeaponAnchor"
		_weapon_anchor.position = Vector3(0.0, -0.04, 0.0)
		hand.add_child(_weapon_anchor)
	else:
		_left_elbow = elbow

	return shoulder

func _build_leg(node_name: String, hip_position: Vector3, right_side: bool) -> Node3D:
	var hip: Node3D = Node3D.new()
	hip.name = node_name
	hip.position = hip_position
	_model_root.add_child(hip)
	_add_capsule(hip, "Thigh", 0.135, 0.66, Vector3(0.0, -0.33, 0.0), _body_material)

	var knee: Node3D = Node3D.new()
	knee.name = "Knee"
	knee.position = Vector3(0.0, -0.65, 0.0)
	hip.add_child(knee)
	_add_capsule(knee, "Shin", 0.115, 0.62, Vector3(0.0, -0.31, 0.0), _body_material)
	_add_box(knee, "Foot", Vector3(0.26, 0.14, 0.42), Vector3(0.0, -0.63, -0.10), _accent_material)

	if right_side:
		_right_knee = knee
	else:
		_left_knee = knee
	return hip

func _add_box(parent: Node3D, node_name: String, size: Vector3, local_position: Vector3, material: StandardMaterial3D) -> void:
	var mesh_instance: MeshInstance3D = MeshInstance3D.new()
	mesh_instance.name = node_name
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	mesh_instance.position = local_position
	mesh_instance.material_override = material
	parent.add_child(mesh_instance)

func _add_capsule(parent: Node3D, node_name: String, radius: float, height: float, local_position: Vector3, material: StandardMaterial3D) -> void:
	var mesh_instance: MeshInstance3D = MeshInstance3D.new()
	mesh_instance.name = node_name
	var mesh: CapsuleMesh = CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = height
	mesh.radial_segments = 12
	mesh.rings = 4
	mesh_instance.mesh = mesh
	mesh_instance.position = local_position
	mesh_instance.material_override = material
	parent.add_child(mesh_instance)

func _add_sphere(parent: Node3D, node_name: String, radius: float, local_position: Vector3, material: StandardMaterial3D) -> void:
	var mesh_instance: MeshInstance3D = MeshInstance3D.new()
	mesh_instance.name = node_name
	var mesh: SphereMesh = SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 16
	mesh.rings = 8
	mesh_instance.mesh = mesh
	mesh_instance.position = local_position
	mesh_instance.material_override = material
	parent.add_child(mesh_instance)

func _hide_legacy_visuals() -> void:
	var fallback: GeometryInstance3D = get_node_or_null(fallback_mesh_path) as GeometryInstance3D
	if fallback != null:
		fallback.visible = false
	var facing_marker: GeometryInstance3D = get_node_or_null(NodePath("../FacingMarker")) as GeometryInstance3D
	if facing_marker != null:
		facing_marker.visible = false

func _adopt_held_weapon_visual() -> void:
	if _weapon_anchor == null or _actor == null:
		return
	var held_weapon: Node3D = _actor.get_node_or_null("HeldWeapon") as Node3D
	if held_weapon == null or held_weapon.get_parent() == _weapon_anchor:
		return
	held_weapon.reparent(_weapon_anchor, false)
	held_weapon.position = Vector3(0.0, -0.08, 0.0)
	held_weapon.rotation_degrees = Vector3(0.0, 0.0, -8.0)

func _update_pose(delta: float, phase: String) -> void:
	var speed: float = Vector3(_actor.velocity.x, 0.0, _actor.velocity.z).length()
	var blend: float = clampf(pose_blend_speed * delta, 0.0, 1.0)

	var root_rotation: Vector3 = Vector3.ZERO
	var root_position: Vector3 = visual_offset
	var torso_rotation: Vector3 = Vector3.ZERO
	var head_rotation: Vector3 = Vector3.ZERO
	var left_shoulder_rotation: Vector3 = Vector3(0.0, 0.0, -0.08)
	var right_shoulder_rotation: Vector3 = Vector3(0.0, 0.0, 0.08)
	var left_elbow_rotation: Vector3 = Vector3.ZERO
	var right_elbow_rotation: Vector3 = Vector3.ZERO
	var left_hip_rotation: Vector3 = Vector3.ZERO
	var right_hip_rotation: Vector3 = Vector3.ZERO
	var left_knee_rotation: Vector3 = Vector3.ZERO
	var right_knee_rotation: Vector3 = Vector3.ZERO

	if phase == "DOWN":
		root_rotation.z = 1.52
		root_position.y -= 0.08
		left_shoulder_rotation.x = -0.65
		right_shoulder_rotation.x = 0.35
		left_hip_rotation.x = 0.35
		right_hip_rotation.x = -0.25
	elif phase == "HITSTUN":
		torso_rotation.x = -0.24
		head_rotation.x = 0.18
		left_shoulder_rotation.x = -0.55
		right_shoulder_rotation.x = -0.75
		left_shoulder_rotation.z = -0.36
		right_shoulder_rotation.z = 0.36
	elif phase == "DODGE I-FRAMES" and speed > 7.0:
		torso_rotation.x = 0.48
		left_shoulder_rotation.x = -0.82
		right_shoulder_rotation.x = -0.82
		left_hip_rotation.x = 0.28
		right_hip_rotation.x = 0.28
	elif phase == "WINDUP" or phase == "ACTIVE" or phase == "RECOVERY":
		var active: bool = phase == "ACTIVE"
		var windup: bool = phase == "WINDUP"
		match _attack_style:
			&"bat_heavy":
				if windup:
					torso_rotation.y = -0.68
					left_shoulder_rotation.x = -0.55
					right_shoulder_rotation.x = -0.72
				elif active:
					torso_rotation.y = 0.72
					left_shoulder_rotation.x = 1.12
					right_shoulder_rotation.x = 1.28
				else:
					torso_rotation.y = 0.18
					left_shoulder_rotation.x = 0.22
					right_shoulder_rotation.x = 0.28
				left_elbow_rotation.x = -0.28
				right_elbow_rotation.x = -0.38
			&"bat_charge":
				torso_rotation.x = 0.22 if active else 0.10
				left_shoulder_rotation.x = 0.72 if active else 0.30
				right_shoulder_rotation.x = 1.02 if active else 0.42
				left_hip_rotation.x = 0.18
				right_hip_rotation.x = -0.18
			&"bat_basic":
				if windup:
					torso_rotation.y = -0.42
					left_shoulder_rotation.x = -0.30
					right_shoulder_rotation.x = -0.58
				elif active:
					torso_rotation.y = 0.48
					left_shoulder_rotation.x = 0.78
					right_shoulder_rotation.x = 1.18
				else:
					torso_rotation.y = 0.12
					left_shoulder_rotation.x = 0.12
					right_shoulder_rotation.x = 0.18
				right_elbow_rotation.x = -0.32
			&"knife_heavy":
				if windup:
					torso_rotation.y = -0.34
					right_shoulder_rotation.x = -0.65
				elif active:
					torso_rotation.y = 0.46
					right_shoulder_rotation.x = 1.32
				else:
					torso_rotation.y = 0.08
					right_shoulder_rotation.x = 0.16
				right_shoulder_rotation.z = 0.30
				right_elbow_rotation.x = -0.44
			&"knife_charge":
				torso_rotation.x = 0.30 if active else 0.08
				right_shoulder_rotation.x = 1.42 if active else -0.16 if windup else 0.18
				right_elbow_rotation.x = -0.12
				left_shoulder_rotation.x = -0.42
			&"knife_basic":
				if windup:
					torso_rotation.y = -0.20
					right_shoulder_rotation.x = -0.42
				elif active:
					torso_rotation.y = 0.30
					right_shoulder_rotation.x = 1.18
				else:
					torso_rotation.y = 0.06
					right_shoulder_rotation.x = 0.14
				right_elbow_rotation.x = -0.38
			&"unarmed_heavy":
				torso_rotation.x = 0.10
				left_shoulder_rotation.x = -0.48
				right_shoulder_rotation.x = -0.35
				right_hip_rotation.x = 1.08 if active else -0.55 if windup else 0.20
				right_knee_rotation.x = 0.36 if active else 0.08
			&"unarmed_charge":
				torso_rotation.x = 0.34 if active else 0.12
				left_shoulder_rotation.x = 0.84 if active else 0.26
				right_shoulder_rotation.x = 0.84 if active else 0.26
				left_elbow_rotation.x = -0.24
				right_elbow_rotation.x = -0.24
			_:
				if windup:
					torso_rotation.y = -0.18
					right_shoulder_rotation.x = -0.46
				elif active:
					torso_rotation.y = 0.20
					right_shoulder_rotation.x = 1.34
				else:
					torso_rotation.y = 0.04
					right_shoulder_rotation.x = 0.12
				right_elbow_rotation.x = -0.52 if active else -0.18
	elif speed > 0.45:
		var gait: float = sin(_time * gait_speed)
		var gait_abs: float = absf(gait)
		left_shoulder_rotation.x = gait * 0.56
		right_shoulder_rotation.x = -gait * 0.56
		left_hip_rotation.x = -gait * 0.68
		right_hip_rotation.x = gait * 0.68
		left_knee_rotation.x = maxf(gait, 0.0) * 0.42
		right_knee_rotation.x = maxf(-gait, 0.0) * 0.42
		torso_rotation.z = gait * 0.035
		root_position.y += gait_abs * 0.045
	else:
		var breathe: float = sin(_time * 2.4)
		torso_rotation.z = breathe * 0.012
		left_shoulder_rotation.x = breathe * 0.025
		right_shoulder_rotation.x = -breathe * 0.025
		root_position.y += breathe * 0.012

	_blend_rotation(_model_root, root_rotation, blend)
	_model_root.position = _model_root.position.lerp(root_position, blend)
	_blend_rotation(_torso, torso_rotation, blend)
	_blend_rotation(_head, head_rotation, blend)
	_blend_rotation(_left_shoulder, left_shoulder_rotation, blend)
	_blend_rotation(_right_shoulder, right_shoulder_rotation, blend)
	_blend_rotation(_left_elbow, left_elbow_rotation, blend)
	_blend_rotation(_right_elbow, right_elbow_rotation, blend)
	_blend_rotation(_left_hip, left_hip_rotation, blend)
	_blend_rotation(_right_hip, right_hip_rotation, blend)
	_blend_rotation(_left_knee, left_knee_rotation, blend)
	_blend_rotation(_right_knee, right_knee_rotation, blend)

func _resolve_attack_style() -> StringName:
	var weapon_name: String = _weapon_name()
	var heavy_pressed: bool = Input.is_action_pressed(&"cleave")
	var charge_pressed: bool = Input.is_action_pressed(&"charge")

	if weapon_name.contains("BASEBALL BAT"):
		if heavy_pressed:
			return &"bat_heavy"
		if charge_pressed:
			return &"bat_charge"
		return &"bat_basic"

	if weapon_name.contains("KNIFE"):
		if heavy_pressed:
			return &"knife_heavy"
		if charge_pressed:
			return &"knife_charge"
		return &"knife_basic"

	if heavy_pressed:
		return &"unarmed_heavy"
	if charge_pressed:
		return &"unarmed_charge"
	return &"unarmed_basic"

func _weapon_name() -> String:
	if _actor != null and _actor.has_method("get_equipped_weapon_name"):
		return str(_actor.call("get_equipped_weapon_name"))
	return "UNARMED"

func _blend_rotation(node: Node3D, target: Vector3, blend: float) -> void:
	if node == null:
		return
	var current: Vector3 = node.rotation
	current.x = lerp_angle(current.x, target.x, blend)
	current.y = lerp_angle(current.y, target.y, blend)
	current.z = lerp_angle(current.z, target.z, blend)
	node.rotation = current
