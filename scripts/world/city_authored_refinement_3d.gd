class_name CityAuthoredRefinement3D
extends Node3D

@export var city_root_path: NodePath = NodePath("..")

const SIDEWALK_DEPTH := 1.65
const DETAIL_SURFACE_Y := 0.145

var _city: Node3D = null
var _layout: Dictionary = {}
var _districts: Dictionary = {}
var _anchors: Dictionary = {}
var _building_groups: Dictionary = {}
var _detail_serial: int = 0

func _ready() -> void:
	call_deferred("_apply_refinement")

func _apply_refinement() -> void:
	# CityWorld builds its generated children from the parent's _ready(). This node
	# is a scene child, so wait one frame and refine the completed result rather
	# than racing the procedural construction pass.
	await get_tree().process_frame
	_city = get_node_or_null(city_root_path) as Node3D
	if _city == null:
		return

	var layout_value: Variant = _city.get("_layout")
	if layout_value is Dictionary and not (layout_value as Dictionary).is_empty():
		_layout = (layout_value as Dictionary).duplicate(true)
	else:
		_layout = CityCrafterLayoutBridge.build_layout()

	var districts_value: Variant = _layout.get("districts", {})
	_districts = (districts_value as Dictionary).duplicate(true) if districts_value is Dictionary else {}
	var anchors_value: Variant = _city.get("_anchors")
	_anchors = (anchors_value as Dictionary).duplicate(true) if anchors_value is Dictionary else {}

	_index_city_buildings()
	_refine_single_building_blocks()
	_realign_gameplay_frontages()
	_add_faction_frontage_identity()
	_add_sparse_block_details()
	print("Urban Brawl: authored city refinement active — ", _building_groups.size(), " occupied blocks")

func _index_city_buildings() -> void:
	_building_groups.clear()
	for child: Node in _city.get_children():
		var building := child as QuaterniusCityBuilding3D
		if building == null:
			continue
		if not building.name.begins_with("CityBuilding_"):
			continue
		var block: Variant = _block_for_point(building.position)
		if not block is Vector2i:
			continue
		var grid_pos := block as Vector2i
		if not _building_groups.has(grid_pos):
			_building_groups[grid_pos] = []
		var group: Array = _building_groups[grid_pos] as Array
		group.append(building)
		_building_groups[grid_pos] = group

func _refine_single_building_blocks() -> void:
	for key_value: Variant in _building_groups.keys():
		if not key_value is Vector2i:
			continue
		var grid_pos := key_value as Vector2i
		var group_variant: Variant = _building_groups.get(grid_pos, [])
		var group: Array = group_variant as Array if group_variant is Array else []
		if group.size() != 1:
			continue
		var building := group[0] as QuaterniusCityBuilding3D
		if building == null:
			continue

		var rect: Dictionary = _block_rect(grid_pos)
		var district: String = str(_districts.get(grid_pos, "residential"))
		var direction: Vector3 = _frontage_direction(rect, district)
		var lateral := Vector3(-direction.z, 0.0, direction.x)
		var center: Vector3 = rect.get("center", Vector3.ZERO) as Vector3
		var width: float = float(rect.get("width", 22.0))
		var depth: float = float(rect.get("depth", 22.0))
		var front_half: float = width * 0.5 if absf(direction.x) > 0.5 else depth * 0.5
		var lateral_half: float = depth * 0.5 if absf(direction.x) > 0.5 else width * 0.5
		var front_extent: float = building.target_size.z * 0.5
		var lateral_extent: float = building.target_size.x * 0.5
		var setback: float = 2.0 if district == "commercial" else (2.65 if district == "industrial" else 2.35)
		var front_offset: float = maxf(front_half - front_extent - setback, 0.0)
		var max_lateral_shift: float = maxf(lateral_half - lateral_extent - SIDEWALK_DEPTH - 0.75, 0.0)
		var style_seed: int = _block_seed(grid_pos)
		var shift_sign: float = -1.0 if (style_seed & 1) == 0 else 1.0
		var shift_strength: float = 0.58 if district == "commercial" else (0.42 if district == "industrial" else 0.32)
		var lateral_shift: float = max_lateral_shift * shift_strength * shift_sign

		var old_y: float = building.position.y
		building.position = center + direction * front_offset + lateral * lateral_shift
		building.position.y = old_y
		building.rotation.y = atan2(direction.x, direction.z)

		_add_entrance_apron(building, direction, setback)
		_add_single_lot_character(rect, building, district, direction, style_seed)

func _realign_gameplay_frontages() -> void:
	_realign_objective_to_building("DrugBuyer", "BeatCopA", -2.8)
	_realign_objective_to_building("GunrunnerBuyer", "ContrabandGuardA", -2.8)
	_realign_objective_to_building("InterdictionCache", "ArmsGuardA", -2.8)

func _realign_objective_to_building(objective_name: String, guard_name: String, guard_lateral: float) -> void:
	var objective: Node3D = _city.get_node_or_null(NodePath(objective_name)) as Node3D
	if objective == null:
		return
	var block: Variant = _block_for_point(objective.position)
	if not block is Vector2i:
		return
	var grid_pos := block as Vector2i
	var group_variant: Variant = _building_groups.get(grid_pos, [])
	var group: Array = group_variant as Array if group_variant is Array else []
	if group.size() != 1:
		return
	var building := group[0] as QuaterniusCityBuilding3D
	if building == null:
		return
	var direction: Vector3 = building.transform.basis.z.normalized()
	direction.y = 0.0
	if direction.length_squared() <= 0.001:
		return
	var lateral := Vector3(-direction.z, 0.0, direction.x)
	var front: Vector3 = building.position + direction * (building.target_size.z * 0.5 + 1.25)
	var objective_y: float = objective.position.y
	objective.position = front
	objective.position.y = objective_y

	var guard: Node3D = _city.get_node_or_null(NodePath(guard_name)) as Node3D
	if guard != null:
		var guard_y: float = guard.position.y
		guard.position = front + lateral * guard_lateral - direction * 0.25
		guard.position.y = guard_y

func _add_entrance_apron(building: QuaterniusCityBuilding3D, direction: Vector3, setback: float) -> void:
	var front_face: Vector3 = building.position + direction * (building.target_size.z * 0.5)
	var apron_depth: float = clampf(setback + 0.65, 2.1, 3.4)
	var apron_center: Vector3 = front_face + direction * (apron_depth * 0.5)
	var size := Vector3(apron_depth, 0.025, 2.25) if absf(direction.x) > 0.5 else Vector3(2.25, 0.025, apron_depth)
	_add_surface("EntranceApron_%03d" % _detail_serial, apron_center + Vector3(0.0, DETAIL_SURFACE_Y, 0.0), size, Color(0.30, 0.295, 0.282, 1.0))
	_detail_serial += 1

func _add_single_lot_character(rect: Dictionary, building: QuaterniusCityBuilding3D, district: String, direction: Vector3, style_seed: int) -> void:
	var center: Vector3 = rect.get("center", Vector3.ZERO) as Vector3
	var width: float = float(rect.get("width", 22.0))
	var depth: float = float(rect.get("depth", 22.0))
	var lateral := Vector3(-direction.z, 0.0, direction.x)
	var side_sign: float = -1.0 if (style_seed & 2) == 0 else 1.0
	var lateral_span: float = (depth if absf(direction.x) > 0.5 else width) * 0.31
	var front_face: Vector3 = building.position + direction * (building.target_size.z * 0.5)
	var rear_half: float = width * 0.5 if absf(direction.x) > 0.5 else depth * 0.5
	var rear_edge: Vector3 = center - direction * maxf(rear_half - SIDEWALK_DEPTH * 0.5, 1.0)

	match district:
		"commercial":
			# One object near the entrance and another at the opposite corner makes
			# storefronts read as occupied without turning every sidewalk into clutter.
			_add_prop("ShopPlanter_%03d" % _detail_serial, front_face + lateral * side_sign * 2.6 + direction * 0.65, ["planter", "plant", "tree"], style_seed, 1.25, 1.25)
			_detail_serial += 1
			if posmod(style_seed, 3) == 0:
				_add_prop("ShopBench_%03d" % _detail_serial, front_face - lateral * side_sign * 2.8 + direction * 0.55, ["bench", "seat"], style_seed + 1, 0.92, 2.0, _yaw_for_direction(lateral))
				_detail_serial += 1
		"industrial":
			_add_driveway_cut(rear_edge, direction, 3.1)
			_add_prop("RearUtility_%03d" % _detail_serial, rear_edge + lateral * side_sign * minf(lateral_span, 4.4) - direction * 1.2, ["dumpster", "pallet", "crate", "box"], style_seed, 1.2, 1.9)
			_detail_serial += 1
			if posmod(style_seed, 4) == 1:
				_add_prop("IndustrialBarrier_%03d" % _detail_serial, rear_edge - lateral * side_sign * 2.7, ["barrier", "bollard", "cone"], style_seed + 2, 0.9, 1.5, _yaw_for_direction(lateral))
				_detail_serial += 1
		_:
			var side_position: Vector3 = center + lateral * side_sign * minf(lateral_span, 4.2) - direction * 0.8
			_add_prop("ResidentialTree_%03d" % _detail_serial, side_position, ["tree", "planter", "plant"], style_seed, 3.1, 2.3)
			_detail_serial += 1
			if posmod(style_seed, 5) == 0:
				_add_prop("ResidentialBench_%03d" % _detail_serial, front_face - lateral * side_sign * 2.4 + direction * 0.55, ["bench", "seat"], style_seed + 3, 0.92, 1.9, _yaw_for_direction(lateral))
				_detail_serial += 1

func _add_driveway_cut(edge_center: Vector3, direction: Vector3, width: float) -> void:
	var size := Vector3(SIDEWALK_DEPTH * 1.15, 0.03, width) if absf(direction.x) > 0.5 else Vector3(width, 0.03, SIDEWALK_DEPTH * 1.15)
	_add_surface("DrivewayCut_%03d" % _detail_serial, edge_center + Vector3(0.0, DETAIL_SURFACE_Y + 0.004, 0.0), size, Color(0.105, 0.108, 0.108, 1.0))
	_detail_serial += 1

func _add_faction_frontage_identity() -> void:
	_add_faction_identity("police", "PoliceHeadquarters", ["bollard", "barrier", "cone"])
	_add_faction_identity("contraband", "ContrabandHeadquarters", ["dumpster", "trash", "bin"])
	_add_faction_identity("arms", "ArmsHeadquarters", ["pallet", "crate", "barrier"])

func _add_faction_identity(faction: String, building_name: String, tokens: Array[String]) -> void:
	var building: QuaterniusCityBuilding3D = _city.get_node_or_null(NodePath(building_name)) as QuaterniusCityBuilding3D
	if building == null:
		return
	var direction: Vector3 = building.transform.basis.z.normalized()
	direction.y = 0.0
	if direction.length_squared() <= 0.001:
		direction = Vector3(0.0, 0.0, 1.0)
	var lateral := Vector3(-direction.z, 0.0, direction.x)
	var front_face: Vector3 = building.position + direction * (building.target_size.z * 0.5 + 0.8)
	var token_seed: int = 700 + faction.length() * 23
	for index: int in range(2):
		var side: float = -1.0 if index == 0 else 1.0
		_add_prop("%sFrontage_%d" % [faction.capitalize(), index], front_face + lateral * side * 2.0, tokens, token_seed + index, 0.95 if faction != "contraband" else 1.15, 1.5, _yaw_for_direction(lateral))

func _add_sparse_block_details() -> void:
	var active_variant: Variant = _layout.get("active_blocks", [])
	var active: Array = active_variant as Array if active_variant is Array else []
	for value: Variant in active:
		if not value is Vector2i:
			continue
		var grid_pos := value as Vector2i
		# Multi-building blocks already have strong perimeter composition. Add only
		# sparse courtyard/service objects there; single-building blocks were handled
		# above with their own lot character pass.
		var group_variant: Variant = _building_groups.get(grid_pos, [])
		var group: Array = group_variant as Array if group_variant is Array else []
		if group.size() <= 1:
			continue
		var rect: Dictionary = _block_rect(grid_pos)
		var district: String = str(_districts.get(grid_pos, "residential"))
		var seed_value: int = _block_seed(grid_pos)
		if posmod(seed_value, 3) != 0:
			continue
		var center: Vector3 = rect.get("center", Vector3.ZERO) as Vector3
		match district:
			"industrial":
				_add_prop("BlockPallet_%03d" % _detail_serial, center + Vector3(2.8, 0.0, -1.8), ["pallet", "crate", "box"], seed_value, 1.0, 1.7)
			"commercial":
				_add_prop("CourtyardPlanter_%03d" % _detail_serial, center + Vector3(-2.4, 0.0, 2.0), ["planter", "plant", "tree"], seed_value, 1.5, 1.6)
			_:
				_add_prop("CourtyardTree_%03d" % _detail_serial, center + Vector3(2.0, 0.0, 2.0), ["tree", "plant"], seed_value, 3.0, 2.2)
		_detail_serial += 1

func _frontage_direction(rect: Dictionary, district: String) -> Vector3:
	var center: Vector3 = rect.get("center", Vector3.ZERO) as Vector3
	var grid_pos: Vector2i = rect.get("grid_pos", Vector2i.ZERO) as Vector2i
	match district:
		"commercial":
			# Commercial frontage prefers the nearest central arterial. That produces
			# believable retail streets without forcing every building to point at the
			# same world origin.
			if absf(center.x) <= absf(center.z) and absf(center.x) > 0.01:
				return Vector3(-signf(center.x), 0.0, 0.0)
			if absf(center.z) > 0.01:
				return Vector3(0.0, 0.0, -signf(center.z))
		"industrial":
			return _direction_to_nearest_city_edge(center)
		_:
			# Alternate residential frontages across the grid. This breaks the radial
			# generator fingerprint while still forming coherent rows of street-facing
			# homes/apartments.
			var style: int = posmod(grid_pos.x * 3 + grid_pos.y * 5, 4)
			match style:
				0:
					return Vector3(0.0, 0.0, -1.0)
				1:
					return Vector3(1.0, 0.0, 0.0)
				2:
					return Vector3(0.0, 0.0, 1.0)
				_:
					return Vector3(-1.0, 0.0, 0.0)
	return Vector3(0.0, 0.0, -1.0)

func _direction_to_nearest_city_edge(center: Vector3) -> Vector3:
	var bounds_min: Vector2 = _layout.get("bounds_min", Vector2(-75.0, -75.0)) as Vector2
	var bounds_max: Vector2 = _layout.get("bounds_max", Vector2(75.0, 75.0)) as Vector2
	var west: float = absf(center.x - bounds_min.x)
	var east: float = absf(bounds_max.x - center.x)
	var north: float = absf(center.z - bounds_min.y)
	var south: float = absf(bounds_max.y - center.z)
	var minimum: float = minf(minf(west, east), minf(north, south))
	if is_equal_approx(minimum, west):
		return Vector3(-1.0, 0.0, 0.0)
	if is_equal_approx(minimum, east):
		return Vector3(1.0, 0.0, 0.0)
	if is_equal_approx(minimum, north):
		return Vector3(0.0, 0.0, -1.0)
	return Vector3(0.0, 0.0, 1.0)

func _block_seed(grid_pos: Vector2i) -> int:
	var value: int = grid_pos.x * 73856093
	value = value ^ (grid_pos.y * 19349663)
	return absi(value)

func _block_for_point(position_value: Vector3) -> Variant:
	var active_variant: Variant = _layout.get("active_blocks", [])
	var active: Array = active_variant as Array if active_variant is Array else []
	for value: Variant in active:
		if not value is Vector2i:
			continue
		var grid_pos := value as Vector2i
		var rect: Dictionary = _block_rect(grid_pos)
		var center: Vector3 = rect.get("center", Vector3.ZERO) as Vector3
		var width: float = float(rect.get("width", 0.0))
		var depth: float = float(rect.get("depth", 0.0))
		if absf(position_value.x - center.x) <= width * 0.5 + 0.2 and absf(position_value.z - center.z) <= depth * 0.5 + 0.2:
			return grid_pos
	return null

func _block_rect(grid_pos: Vector2i) -> Dictionary:
	var sizes_variant: Variant = _layout.get("block_sizes", {})
	var sizes: Dictionary = sizes_variant as Dictionary if sizes_variant is Dictionary else {}
	var grid_size: Vector2i = sizes.get(grid_pos, Vector2i.ONE)
	var block_size: float = float(_layout.get("block_size", 22.0))
	var street_width: float = float(_layout.get("street_width", 8.2))
	var stride: float = float(_layout.get("stride", block_size + street_width))
	var offset: Vector3 = _layout.get("origin_offset", Vector3.ZERO) as Vector3
	var width: float = float(grid_size.x) * block_size + float(grid_size.x - 1) * street_width
	var depth: float = float(grid_size.y) * block_size + float(grid_size.y - 1) * street_width
	var x0: float = float(grid_pos.x) * stride + offset.x
	var z0: float = float(grid_pos.y) * stride + offset.z
	return {
		"grid_pos": grid_pos,
		"grid_size": grid_size,
		"width": width,
		"depth": depth,
		"center": Vector3(x0 + width * 0.5, 0.0, z0 + depth * 0.5),
	}

func _add_surface(node_name: String, center: Vector3, size: Vector3, color: Color) -> void:
	var surface := MeshInstance3D.new()
	surface.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = size
	surface.mesh = mesh
	surface.position = center
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.98
	surface.material_override = material
	_city.add_child(surface)

func _add_prop(node_name: String, position_value: Vector3, tokens: Array[String], variant: int, height: float, width: float = 0.0, yaw: float = 0.0) -> void:
	var prop := QuaterniusCityProp3D.new()
	prop.name = node_name
	prop.position = position_value
	prop.search_tokens = tokens
	prop.variant_index = variant
	prop.target_height = height
	prop.target_width = width
	prop.yaw_degrees = yaw
	_city.add_child(prop)

func _yaw_for_direction(direction: Vector3) -> float:
	return rad_to_deg(atan2(direction.x, direction.z))
