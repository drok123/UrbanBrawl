class_name CombatAnimationDriver3D
extends Node3D

@export_file("*.glb") var character_scene_path: String = "res://assets/third_party/kaykit_adventurers/Rogue.glb"
@export var visual_offset: Vector3 = Vector3(0.0, -0.95, 0.0)
@export var visual_rotation_degrees: Vector3 = Vector3(0.0, 180.0, 0.0)
@export var visual_scale: Vector3 = Vector3.ONE
@export var fallback_mesh_path: NodePath = NodePath("../Mesh")
@export var blend_time: float = 0.08

var _actor: CharacterBody3D = null
var _character_root: Node3D = null
var _animation_player: AnimationPlayer = null
var _animation_names: PackedStringArray = PackedStringArray()
var _last_phase: String = ""
var _current_animation: StringName = &""

func _ready() -> void:
	_actor = get_parent() as CharacterBody3D
	_load_character_visual()
	if _animation_player != null:
		_animation_names = _animation_player.get_animation_list()
		_play_loop(_idle_candidates())

func _physics_process(_delta: float) -> void:
	if _actor == null or _animation_player == null:
		return

	var phase: String = str(_actor.call("get_combat_phase_name"))
	var horizontal_velocity: Vector3 = Vector3(_actor.velocity.x, 0.0, _actor.velocity.z)
	var speed: float = horizontal_velocity.length()

	if phase == "DOWN":
		if _last_phase != "DOWN":
			_play_once([&"Death_A", &"Death_B", &"Defeat"])
		_last_phase = phase
		return

	if phase == "HITSTUN":
		if _last_phase != "HITSTUN":
			_play_once([&"Hit_A", &"Hit_B"])
		_last_phase = phase
		return

	if phase == "WINDUP":
		if _last_phase != "WINDUP":
			_play_attack_for_current_input()
		_last_phase = phase
		return

	if phase == "ACTIVE" or phase == "RECOVERY":
		_last_phase = phase
		return

	if phase == "DODGE I-FRAMES" and speed > 8.0:
		if _last_phase != "DODGE I-FRAMES":
			_play_once(_dodge_candidates(horizontal_velocity))
		_last_phase = phase
		return

	if speed > 0.45:
		_play_loop([&"Running_A", &"Run", &"Walking_A", &"Walk"])
	else:
		_play_loop(_idle_candidates())

	_last_phase = phase

func _load_character_visual() -> void:
	if character_scene_path.is_empty() or not ResourceLoader.exists(character_scene_path):
		push_warning("Animated character dependency not installed: %s" % character_scene_path)
		return

	var resource: Resource = ResourceLoader.load(character_scene_path)
	var packed_scene: PackedScene = resource as PackedScene
	if packed_scene == null:
		push_warning("Character resource is not an instantiable scene: %s" % character_scene_path)
		return

	var instance: Node = packed_scene.instantiate()
	var node_3d: Node3D = instance as Node3D
	if node_3d == null:
		instance.queue_free()
		push_warning("Character scene root is not Node3D: %s" % character_scene_path)
		return

	_character_root = node_3d
	_character_root.name = "AnimatedRig"
	_character_root.position = visual_offset
	_character_root.rotation_degrees = visual_rotation_degrees
	_character_root.scale = visual_scale
	add_child(_character_root)

	_animation_player = _find_animation_player(_character_root)
	if _animation_player == null:
		push_warning("No AnimationPlayer found in character scene: %s" % character_scene_path)
		_character_root.queue_free()
		_character_root = null
		return

	var fallback: GeometryInstance3D = get_node_or_null(fallback_mesh_path) as GeometryInstance3D
	if fallback != null:
		fallback.visible = false

func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node as AnimationPlayer
	for child: Node in node.get_children():
		var found: AnimationPlayer = _find_animation_player(child)
		if found != null:
			return found
	return null

func _play_attack_for_current_input() -> void:
	var weapon_name: String = _weapon_name()

	if weapon_name.contains("BASEBALL BAT"):
		if Input.is_action_pressed(&"cleave"):
			_play_once([&"2H_Melee_Attack_Spinning", &"2H_Melee_Attack_Spin", &"2H_Melee_Attack_Chop"])
		elif Input.is_action_pressed(&"charge"):
			_play_once([&"2H_Melee_Attack_Stab", &"2H_Melee_Attack_Chop"])
		else:
			_play_once([&"2H_Melee_Attack_Slice", &"2H_Melee_Attack_Chop", &"1H_Melee_Attack_Slice_Horizontal"])
		return

	if weapon_name.contains("KNIFE"):
		if Input.is_action_pressed(&"cleave"):
			_play_once([&"1H_Melee_Attack_Slice_Horizontal", &"1H_Melee_Attack_Slice_Diagonal", &"1H_Melee_Attack_Chop"])
		elif Input.is_action_pressed(&"charge"):
			_play_once([&"1H_Melee_Attack_Stab", &"1H_Melee_Attack_Slice_Diagonal"])
		else:
			_play_once([&"1H_Melee_Attack_Slice_Diagonal", &"1H_Melee_Attack_Stab", &"1H_Melee_Attack_Chop"])
		return

	if Input.is_action_pressed(&"cleave"):
		_play_once([&"Unarmed_Melee_Attack_Kick", &"Unarmed_Melee_Attack_Punch_B", &"Heavy Attack"])
	elif Input.is_action_pressed(&"charge"):
		_play_once([&"Unarmed_Melee_Attack_Punch_B", &"Unarmed_Melee_Attack_Punch_A", &"Attack (1h)"])
	else:
		_play_once([&"Unarmed_Melee_Attack_Punch_A", &"Unarmed_Melee_Attack_Punch_B", &"Attack (1h)"])

func _idle_candidates() -> Array[StringName]:
	var weapon_name: String = _weapon_name()
	if weapon_name.contains("BASEBALL BAT"):
		return [&"2H_Melee_Idle", &"Idle", &"Unarmed_Idle"]
	if weapon_name.contains("KNIFE"):
		return [&"Idle", &"Unarmed_Idle", &"Unarmed_Pose"]
	return [&"Unarmed_Idle", &"Idle", &"Unarmed_Pose"]

func _weapon_name() -> String:
	if _actor != null and _actor.has_method("get_equipped_weapon_name"):
		return str(_actor.call("get_equipped_weapon_name"))
	return "UNARMED"

func _dodge_candidates(world_velocity: Vector3) -> Array[StringName]:
	if world_velocity.length_squared() < 0.001 or _actor == null:
		return [&"Dodge_Forward", &"Roll"]

	var direction: Vector3 = world_velocity.normalized()
	var forward: Vector3 = -_actor.global_transform.basis.z.normalized()
	var right: Vector3 = _actor.global_transform.basis.x.normalized()
	var forward_dot: float = direction.dot(forward)
	var right_dot: float = direction.dot(right)

	if absf(forward_dot) >= absf(right_dot):
		if forward_dot >= 0.0:
			return [&"Dodge_Forward", &"Roll"]
		return [&"Dodge_Backward", &"Dodge_Back", &"Roll"]
	if right_dot >= 0.0:
		return [&"Dodge_Right", &"Roll"]
	return [&"Dodge_Left", &"Roll"]

func _play_loop(candidates: Array[StringName]) -> void:
	var animation_name: StringName = _resolve_animation(candidates)
	if animation_name == &"" or animation_name == _current_animation:
		return
	_current_animation = animation_name
	_animation_player.play(animation_name, blend_time)

func _play_once(candidates: Array[StringName]) -> void:
	var animation_name: StringName = _resolve_animation(candidates)
	if animation_name == &"":
		return
	_current_animation = animation_name
	_animation_player.play(animation_name, blend_time)

func _resolve_animation(candidates: Array[StringName]) -> StringName:
	for candidate: StringName in candidates:
		if _animation_player.has_animation(candidate):
			return candidate

	for candidate: StringName in candidates:
		var normalized_candidate: String = _normalize_animation_name(String(candidate))
		for available: String in _animation_names:
			var normalized_available: String = _normalize_animation_name(available)
			if normalized_available == normalized_candidate or normalized_available.ends_with(normalized_candidate):
				return StringName(available)
	return &""

func _normalize_animation_name(value: String) -> String:
	return value.to_lower().replace(" ", "_").replace("-", "_").replace("(", "").replace(")", "")
