class_name QuaterniusCharacterDriver3D
extends Node3D

@export var fallback_visual_path: NodePath = NodePath("../CharacterVisual")
@export var target_height: float = 1.88
@export var animation_blend: float = 0.10

var _actor: CharacterBody3D = null
var _fallback_visual: Node3D = null
var _character_root: Node3D = null
var _skeleton: Skeleton3D = null
var _animation_player: AnimationPlayer = null
var _animation_library: AnimationLibrary = null
var _weapon_attachment: BoneAttachment3D = null
var _active: bool = false
var _current_animation: StringName = &""
var _last_reaction_variant: int = -1

func _ready() -> void:
	_actor = get_parent() as CharacterBody3D
	_fallback_visual = get_node_or_null(fallback_visual_path) as Node3D
	call_deferred("_try_activate")

func _physics_process(_delta: float) -> void:
	if not _active or _actor == null:
		return
	_adopt_held_weapon()
	_update_animation()

func is_external_visual_active() -> bool:
	return _active

func _try_activate() -> void:
	var character_path: String = QuaterniusAssetLocator.find_best_character_scene()
	if character_path.is_empty():
		return

	var packed: PackedScene = load(character_path) as PackedScene
	if packed == null:
		return
	var instance: Node = packed.instantiate()
	_character_root = instance as Node3D
	if _character_root == null:
		instance.queue_free()
		return

	_character_root.name = "QuaterniusCharacter"
	add_child(_character_root)
	_skeleton = _find_skeleton(_character_root)
	if _skeleton == null:
		_character_root.queue_free()
		_character_root = null
		return

	_fit_character_height()
	_animation_player = AnimationPlayer.new()
	_animation_player.name = "UrbanAnimationPlayer"
	add_child(_animation_player)
	_animation_player.root_node = NodePath("..")
	_animation_library = _animation_player.get_animation_library(&"")
	if _animation_library == null:
		_animation_library = AnimationLibrary.new()
		_animation_player.add_animation_library(&"", _animation_library)

	var imported_count: int = _import_ual_animations()
	if imported_count <= 0:
		_character_root.queue_free()
		_animation_player.queue_free()
		_character_root = null
		_animation_player = null
		_animation_library = null
		return

	_create_weapon_attachment()
	if _fallback_visual != null:
		_fallback_visual.visible = false
		_fallback_visual.process_mode = Node.PROCESS_MODE_DISABLED
	_active = true
	set_meta(&"external_character", character_path)
	print("Urban Brawl: Quaternius player visual active — ", character_path, " / ", imported_count, " animations")
	_update_animation(true)

func _import_ual_animations() -> int:
	if _animation_library == null or _skeleton == null:
		return 0
	var imported: int = 0
	var target_bones: Dictionary = _bone_name_set(_skeleton)
	var target_skeleton_path: String = str(get_path_to(_skeleton))

	for source_path: String in QuaterniusAssetLocator.find_animation_sources():
		var packed: PackedScene = load(source_path) as PackedScene
		if packed == null:
			continue
		var donor: Node = packed.instantiate()
		var donor_skeleton: Skeleton3D = _find_skeleton(donor)
		var donor_players: Array[AnimationPlayer] = _find_animation_players(donor)
		if donor_skeleton == null or donor_players.is_empty():
			donor.free()
			continue
		if _bone_overlap_ratio(target_bones, donor_skeleton) < 0.62:
			donor.free()
			continue

		for donor_player: AnimationPlayer in donor_players:
			for donor_name: StringName in donor_player.get_animation_list():
				var source_animation: Animation = donor_player.get_animation(donor_name)
				if source_animation == null:
					continue
				var copied: Animation = source_animation.duplicate(true) as Animation
				if copied == null:
					continue
				_retarget_animation(copied, target_skeleton_path)
				if copied.get_track_count() <= 0:
					continue
				var unique_name: StringName = _unique_animation_name(source_path, donor_name)
				if _animation_library.has_animation(unique_name):
					continue
				_animation_library.add_animation(unique_name, copied)
				imported += 1
		donor.free()
	return imported

func _retarget_animation(animation: Animation, target_skeleton_path: String) -> void:
	for track_index: int in range(animation.get_track_count() - 1, -1, -1):
		var source_path: String = str(animation.track_get_path(track_index))
		var separator: int = source_path.find(":")
		if separator < 0:
			animation.remove_track(track_index)
			continue
		var bone_suffix: String = source_path.substr(separator)
		animation.track_set_path(track_index, NodePath(target_skeleton_path + bone_suffix))

func _update_animation(force: bool = false) -> void:
	if _animation_player == null or _animation_library == null or _actor == null:
		return
	var desired: StringName = _desired_animation()
	if desired == &"":
		return
	if not force and desired == _current_animation and _animation_player.is_playing():
		return
	_current_animation = desired
	_animation_player.play(desired, animation_blend)

func _desired_animation() -> StringName:
	var reaction: String = str(_actor.get_meta(&"hit_reaction_phase", &""))
	var reaction_variant: int = int(_actor.get_meta(&"hit_reaction_variant", 0))
	if not reaction.is_empty():
		if reaction_variant != _last_reaction_variant or _current_animation == &"":
			_last_reaction_variant = reaction_variant
		match reaction:
			"FALLBACK":
				return _find_animation(["knock", "fall", "hit"])
			"STUMBLE":
				return _find_animation(["hit", "impact", "stumble"])
			_:
				return _find_animation(["hit", "impact"])
	_last_reaction_variant = -1

	var phase: String = "READY"
	if _actor.has_method("get_combat_phase_name"):
		phase = str(_actor.call("get_combat_phase_name"))
	if phase == "DOWN":
		return _find_animation(["death", "down", "knock"])
	if phase == "DODGE I-FRAMES":
		return _find_animation(["dodge", "roll"])

	if phase == "WINDUP" or phase == "ACTIVE" or phase == "RECOVERY":
		var weapon: String = "UNARMED"
		if _actor.has_method("get_equipped_weapon_name"):
			weapon = str(_actor.call("get_equipped_weapon_name")).to_lower()
		if "pistol" in weapon:
			return _find_animation(["shoot", "gun", "aim"])
		if "knife" in weapon:
			return _find_animation(["knife", "melee", "attack", "stab"])
		if "bat" in weapon:
			return _find_animation(["melee", "attack", "swing"])
		return _find_animation(["punch", "attack", "melee"])

	var horizontal_speed: float = Vector2(_actor.velocity.x, _actor.velocity.z).length()
	if horizontal_speed > 5.2:
		return _find_animation(["run", "jog", "sprint"])
	if horizontal_speed > 0.35:
		return _find_animation(["walk", "jog", "run"])
	return _find_animation(["idle"])

func _find_animation(tokens: Array[String]) -> StringName:
	if _animation_player == null:
		return &""
	var names: PackedStringArray = _animation_player.get_animation_list()
	var best: StringName = &""
	var best_score: int = -100000
	for raw_name: String in names:
		var name: String = raw_name.to_lower()
		var score: int = 0
		for index: int in range(tokens.size()):
			if tokens[index] in name:
				score += 100 - index * 18
		if "root" in name:
			score -= 12
		if score > best_score:
			best_score = score
			best = StringName(raw_name)
	return best if best_score > 0 else &""

func _unique_animation_name(source_path: String, donor_name: StringName) -> StringName:
	var source: String = source_path.get_file().get_basename().to_lower()
	var animation: String = str(donor_name).to_lower()
	var combined: String = "%s__%s" % [source, animation]
	combined = combined.replace(" ", "_").replace("-", "_").replace(".", "_").replace("/", "_")
	return StringName(combined)

func _create_weapon_attachment() -> void:
	if _skeleton == null:
		return
	var bone_index: int = _find_right_hand_bone(_skeleton)
	if bone_index < 0:
		return
	_weapon_attachment = BoneAttachment3D.new()
	_weapon_attachment.name = "WeaponAttachment"
	_weapon_attachment.bone_idx = bone_index
	_skeleton.add_child(_weapon_attachment)

func _adopt_held_weapon() -> void:
	if _weapon_attachment == null or _actor == null:
		return
	var held_weapon: Node3D = _actor.get_node_or_null("HeldWeapon") as Node3D
	if held_weapon == null:
		return
	if held_weapon.get_parent() != _weapon_attachment:
		held_weapon.reparent(_weapon_attachment, false)
		held_weapon.position = Vector3(0.0, 0.0, -0.08)
		held_weapon.rotation_degrees = Vector3(0.0, 90.0, -10.0)

func _fit_character_height() -> void:
	if _character_root == null:
		return
	var bounds: AABB = _combined_bounds(_character_root)
	if bounds.size.y <= 0.001:
		return
	var scale_factor: float = clampf(target_height / bounds.size.y, 0.15, 5.0)
	_character_root.scale = Vector3.ONE * scale_factor
	var center_x: float = (bounds.position.x + bounds.size.x * 0.5) * scale_factor
	var center_z: float = (bounds.position.z + bounds.size.z * 0.5) * scale_factor
	var min_y: float = bounds.position.y * scale_factor
	_character_root.position = Vector3(-center_x, -0.95 - min_y, -center_z)

func _combined_bounds(root: Node3D) -> AABB:
	var initialized: bool = false
	var minimum: Vector3 = Vector3.ZERO
	var maximum: Vector3 = Vector3.ZERO
	for node: Node in root.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance: MeshInstance3D = node as MeshInstance3D
		if mesh_instance == null or mesh_instance.mesh == null:
			continue
		var bounds: AABB = mesh_instance.get_aabb()
		var to_root: Transform3D = root.global_transform.affine_inverse() * mesh_instance.global_transform
		for corner: Vector3 in _aabb_corners(bounds):
			var point: Vector3 = to_root * corner
			if not initialized:
				minimum = point
				maximum = point
				initialized = true
			else:
				minimum.x = minf(minimum.x, point.x)
				minimum.y = minf(minimum.y, point.y)
				minimum.z = minf(minimum.z, point.z)
				maximum.x = maxf(maximum.x, point.x)
				maximum.y = maxf(maximum.y, point.y)
				maximum.z = maxf(maximum.z, point.z)
	return AABB(minimum, maximum - minimum) if initialized else AABB()

func _aabb_corners(bounds: AABB) -> Array[Vector3]:
	var p: Vector3 = bounds.position
	var s: Vector3 = bounds.size
	return [
		p,
		p + Vector3(s.x, 0.0, 0.0),
		p + Vector3(0.0, s.y, 0.0),
		p + Vector3(0.0, 0.0, s.z),
		p + Vector3(s.x, s.y, 0.0),
		p + Vector3(s.x, 0.0, s.z),
		p + Vector3(0.0, s.y, s.z),
		p + s,
	]

func _find_skeleton(root: Node) -> Skeleton3D:
	if root is Skeleton3D:
		return root as Skeleton3D
	for child: Node in root.get_children():
		var found: Skeleton3D = _find_skeleton(child)
		if found != null:
			return found
	return null

func _find_animation_players(root: Node) -> Array[AnimationPlayer]:
	var result: Array[AnimationPlayer] = []
	_collect_animation_players(root, result)
	return result

func _collect_animation_players(root: Node, output: Array[AnimationPlayer]) -> void:
	if root is AnimationPlayer:
		output.append(root as AnimationPlayer)
	for child: Node in root.get_children():
		_collect_animation_players(child, output)

func _bone_name_set(skeleton: Skeleton3D) -> Dictionary:
	var result: Dictionary = {}
	for index: int in range(skeleton.get_bone_count()):
		result[skeleton.get_bone_name(index).to_lower()] = true
	return result

func _bone_overlap_ratio(target_bones: Dictionary, donor: Skeleton3D) -> float:
	if donor.get_bone_count() <= 0:
		return 0.0
	var matched: int = 0
	for index: int in range(donor.get_bone_count()):
		if target_bones.has(donor.get_bone_name(index).to_lower()):
			matched += 1
	return float(matched) / float(donor.get_bone_count())

func _find_right_hand_bone(skeleton: Skeleton3D) -> int:
	var fallback: int = -1
	for index: int in range(skeleton.get_bone_count()):
		var name: String = skeleton.get_bone_name(index).to_lower().replace(" ", "").replace("_", "").replace(".", "")
		if "righthand" in name or "handr" in name:
			return index
		if "hand" in name and ("right" in name or name.ends_with("r")):
			fallback = index
	return fallback
