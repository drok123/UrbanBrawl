class_name QuaterniusAssetLocator
extends RefCounted

const CITY_ROOT: String = "res://assets/third_party/quaternius_city"
const CHARACTER_ROOT: String = "res://assets/third_party/quaternius_characters"
const UAL_ROOT: String = "res://assets/third_party/quaternius_ual"

const BUILDING_TOKENS: Array[String] = ["example", "prebuilt", "assembled", "building", "apartment", "office", "store", "shop"]
const BUILDING_REJECT: Array[String] = ["facade", "wall", "window", "door", "roof", "trim", "column", "floor", "sidewalk", "road", "street", "prop", "sign"]

static func city_file_count() -> int:
	return _scene_files(CITY_ROOT).size()

static func character_file_count() -> int:
	return _scene_files(CHARACTER_ROOT).size()

static func animation_file_count() -> int:
	return _scene_files(UAL_ROOT).size()

static func city_building_candidate_count() -> int:
	return _ranked_city_candidates(BUILDING_TOKENS, BUILDING_REJECT, true).size()

static func find_best_city_building() -> String:
	return find_city_building_variant(0)

static func find_city_building_variant(variant_index: int = 0, preferred_tokens: Array[String] = []) -> String:
	var tokens: Array[String] = preferred_tokens if not preferred_tokens.is_empty() else BUILDING_TOKENS
	var candidates: Array[String] = _ranked_city_candidates(tokens, BUILDING_REJECT, true)
	if candidates.is_empty() and tokens != BUILDING_TOKENS:
		# District naming in the Standard pack can differ, but a complete generic
		# building is still valid. Never promote a facade/wall into a whole building.
		candidates = _ranked_city_candidates(BUILDING_TOKENS, BUILDING_REJECT, true)
	if candidates.is_empty():
		return ""
	return candidates[_stable_variant_index(candidates.size(), variant_index, tokens, 13)]

static func find_city_prop(tokens: Array[String], variant_index: int = 0) -> String:
	var reject: Array[String] = ["building", "example", "prebuilt", "assembled", "wall", "floor", "roof"]
	var candidates: Array[String] = _ranked_city_candidates(tokens, reject, false)
	if candidates.is_empty():
		return ""
	return candidates[_stable_variant_index(candidates.size(), variant_index, tokens, 11)]

static func find_character_scene(variant_index: int = 0) -> String:
	var files: Array[String] = _scene_files(CHARACTER_ROOT)
	var preferred: Array[String] = []
	var fallback: Array[String] = []
	for path: String in files:
		var text: String = path.to_lower()
		if "hair" in text or "hairstyle" in text:
			continue
		if "regular" in text and ("male" in text or "female" in text):
			preferred.append(path)
		elif "character" in text or "base" in text or "male" in text or "female" in text:
			fallback.append(path)
	preferred.sort()
	fallback.sort()
	var candidates: Array[String] = preferred if not preferred.is_empty() else fallback
	if candidates.is_empty():
		candidates = files
		candidates.sort()
	if candidates.is_empty():
		return ""
	return candidates[posmod(variant_index, candidates.size())]

static func find_best_character_scene() -> String:
	return find_character_scene(0)

static func find_animation_sources(max_files: int = 48) -> Array[String]:
	var files: Array[String] = _scene_files(UAL_ROOT)
	if files.is_empty():
		return []

	var preferred: Array[String] = []
	var fallback: Array[String] = []
	for path: String in files:
		var text: String = path.to_lower()
		var is_preferred: bool = (
			"idle" in text
			or "walk" in text
			or "jog" in text
			or "run" in text
			or "sprint" in text
			or "punch" in text
			or "kick" in text
			or "attack" in text
			or "melee" in text
			or "combo" in text
			or "hit" in text
			or "impact" in text
			or "death" in text
			or "fall" in text
			or "dodge" in text
			or "roll" in text
			or "shoot" in text
			or "aim" in text
			or "gun" in text
			or "pistol" in text
		)
		if is_preferred:
			preferred.append(path)
		else:
			fallback.append(path)

	preferred.sort()
	fallback.sort()
	for path: String in fallback:
		if preferred.size() >= max_files:
			break
		preferred.append(path)
	if preferred.size() > max_files:
		preferred.resize(max_files)
	return preferred

static func has_visual_pack() -> bool:
	return city_file_count() > 0 or character_file_count() > 0 or animation_file_count() > 0

static func print_install_summary() -> void:
	print(
		"Urban Brawl: Quaternius catalog — city ", city_file_count(),
		" (", city_building_candidate_count(), " complete-building candidates), characters ", character_file_count(),
		", animation sources ", animation_file_count()
	)

static func _stable_variant_index(candidate_count: int, variant_index: int, tokens: Array[String], stride: int) -> int:
	if candidate_count <= 1:
		return 0
	var token_seed: int = 17
	for token: String in tokens:
		for byte_value: int in token.to_lower().to_utf8_buffer():
			token_seed = posmod(token_seed * 31 + byte_value, 2147483629)
	return posmod(token_seed + variant_index * stride, candidate_count)

static func _ranked_city_candidates(tokens: Array[String], reject_tokens: Array[String], require_strong_match: bool) -> Array[String]:
	var files: Array[String] = _scene_files(CITY_ROOT)
	var buckets: Dictionary = {}
	var scores: Array[int] = []
	for path: String in files:
		var text: String = path.to_lower()
		var rejected: bool = false
		for reject: String in reject_tokens:
			if reject in text:
				rejected = true
				break
		if rejected:
			continue

		var score: int = 0
		for token_index: int in range(tokens.size()):
			var token: String = tokens[token_index].to_lower()
			if token in text:
				score += maxi(22 - token_index * 3, 5)
		if "example" in text or "prebuilt" in text or "assembled" in text:
			score += 45
		if "building" in text:
			score += 10
		# Whole-building selection must have strong evidence. Generic unrelated GLBs
		# are never acceptable just because they survived the reject list.
		if require_strong_match and score < 10:
			continue
		if not require_strong_match and score <= 0:
			continue
		if not buckets.has(score):
			buckets[score] = []
		var list: Array = buckets[score]
		list.append(path)
		buckets[score] = list
		if not scores.has(score):
			scores.append(score)

	scores.sort()
	scores.reverse()
	var result: Array[String] = []
	for score: int in scores:
		var raw_list: Array = buckets[score]
		var paths: Array[String] = []
		for value: Variant in raw_list:
			paths.append(str(value))
		paths.sort()
		result.append_array(paths)
	return result

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
