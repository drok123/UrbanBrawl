class_name QuaterniusAssetLocator
extends RefCounted

const CITY_ROOT: String = "res://assets/third_party/quaternius_city"
const CHARACTER_ROOT: String = "res://assets/third_party/quaternius_characters"
const UAL_ROOT: String = "res://assets/third_party/quaternius_ual"

static func find_best_city_building() -> String:
	var files: Array[String] = _scene_files(CITY_ROOT)
	var best_path: String = ""
	var best_score: int = -100000
	for path: String in files:
		var name: String = path.get_file().to_lower()
		var score: int = 0
		if "example" in name or "prebuilt" in name or "assembled" in name:
			score += 100
		if "building" in name:
			score += 65
		if "apartment" in name or "office" in name or "store" in name:
			score += 35
		if "facade" in name:
			score -= 10
		if "wall" in name or "window" in name or "door" in name or "roof" in name:
			score -= 55
		if "prop" in name or "trash" in name or "streetlight" in name or "sign" in name or "sidewalk" in name or "road" in name:
			score -= 70
		if score > best_score:
			best_score = score
			best_path = path
	return best_path if best_score >= 45 else ""

static func find_best_character_scene() -> String:
	var files: Array[String] = _scene_files(CHARACTER_ROOT)
	var best_path: String = ""
	var best_score: int = -100000
	for path: String in files:
		var name: String = path.get_file().to_lower()
		var score: int = 0
		if "regular" in name:
			score += 80
		if "male" in name or "female" in name:
			score += 30
		if "base" in name or "character" in name:
			score += 25
		if "teen" in name:
			score -= 10
		if "superhero" in name:
			score -= 15
		if "hair" in name or "hairstyle" in name:
			score -= 80
		if score > best_score:
			best_score = score
			best_path = path
	return best_path if best_score > 0 else ""

static func find_animation_sources(max_files: int = 28) -> Array[String]:
	var files: Array[String] = _scene_files(UAL_ROOT)
	if files.is_empty():
		return []

	var preferred: Array[String] = []
	var fallback: Array[String] = []
	for path: String in files:
		var name: String = path.get_file().to_lower()
		var is_preferred: bool = (
			"idle" in name
			or "walk" in name
			or "jog" in name
			or "run" in name
			or "sprint" in name
			or "punch" in name
			or "kick" in name
			or "attack" in name
			or "melee" in name
			or "hit" in name
			or "impact" in name
			or "death" in name
			or "dodge" in name
			or "shoot" in name
			or "aim" in name
			or "gun" in name
		)
		if is_preferred:
			preferred.append(path)
		else:
			fallback.append(path)

	if preferred.size() < 3:
		preferred.append_array(fallback)

	preferred.sort()
	if preferred.size() > max_files:
		preferred.resize(max_files)
	return preferred

static func has_visual_pack() -> bool:
	return not find_best_city_building().is_empty() or not find_best_character_scene().is_empty()

static func _scene_files(root: String) -> Array[String]:
	var result: Array[String] = []
	_collect_scene_files(root, result)
	return result

static func _collect_scene_files(path: String, output: Array[String]) -> void:
	var dir: DirAccess = DirAccess.open(path)
	if dir == null:
		return
	dir.list_dir_begin()
	while true:
		var entry: String = dir.get_next()
		if entry.is_empty():
			break
		if entry.begins_with("."):
			continue
		var full_path: String = path.path_join(entry)
		if dir.current_is_dir():
			_collect_scene_files(full_path, output)
		else:
			var extension: String = entry.get_extension().to_lower()
			if extension == "glb" or extension == "gltf" or extension == "fbx":
				output.append(full_path)
	dir.list_dir_end()
