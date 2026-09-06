class_name CityWorld3D
extends Node3D

@export var player_path: NodePath = NodePath("Player")

const LOT_HEIGHT := 0.045
const SIDEWALK_HEIGHT := 0.075

var _player: Node3D = null
var _plan: Dictionary = {}
var _blocks_by_role: Dictionary = {}
var _building_serial: int = 0
var _commons_block: Dictionary = {}

func _ready() -> void:
	_player = get_node_or_null(player_path) as Node3D
	QuaterniusAssetLocator.print_install_summary()
	_plan = CityMasterPlan.build_plan()
	_build_city()
	_restore_city_spawn()
	_update_territory()

func _process(_delta: float) -> void:
	_update_territory()

func _build_city() -> void:
	_index_blocks()
	var bounds_size: Vector2 = _plan.get("bounds_size", Vector2(240.0, 240.0)) as Vector2
	_add_static_box(
		"CityFoundation",
		Vector3(bounds_size.x, 0.24, bounds_size.y),
		Vector3(0.0, -0.14, 0.0),
		Color(0.082, 0.085, 0.088, 1.0)
	)

	var roads := CityRoadNetwork3D.new()
	roads.name = "StreetNetwork"
	roads.configure_from_plan(_plan)
	add_child(roads)

	var raw_blocks: Variant = _plan.get("blocks", [])
	if raw_blocks is Array:
		var blocks: Array = raw_blocks as Array
		for value: Variant in blocks:
			if value is Dictionary:
				_build_block(value as Dictionary)

	_place_gameplay_nodes()
	print("Urban Brawl: public city = ", _plan.get("source", "unknown"), " | blocks ", _blocks_by_role.size(), " | detail pass intentionally disabled")

func _index_blocks() -> void:
	_blocks_by_role.clear()
	var raw_blocks: Variant = _plan.get("blocks", [])
	if not raw_blocks is Array:
		return
	var blocks: Array = raw_blocks as Array
	for value: Variant in blocks:
		if not value is Dictionary:
			continue
		var block := value as Dictionary
		_blocks_by_role[str(block.get("role", "generic"))] = block
	_commons_block = _block("commons")

func _block(role: String) -> Dictionary:
	var value: Variant = _blocks_by_role.get(role, {})
	return (value as Dictionary).duplicate(true) if value is Dictionary else {}

func _build_block(block: Dictionary) -> void:
	_add_block_surfaces(block)
	var role: String = str(block.get("role", "generic"))
	var district: String = str(block.get("district", "mixed"))
	match role:
		"commons":
			_build_commons(block)
		"police":
			_build_police_block(block)
		"contraband":
			_build_contraband_block(block)
		"arms":
			_build_arms_block(block)
		_:
			_build_regular_block(block, district)

func _add_block_surfaces(block: Dictionary) -> void:
	var center: Vector3 = block.get("center", Vector3.ZERO) as Vector3
	var width: float = float(block.get("width", 40.0))
	var depth: float = float(block.get("depth", 40.0))
	var sidewalk: float = float(_plan.get("sidewalk_width", 2.15))
	var district: String = str(block.get("district", "mixed"))

	_add_surface_box(
		"Lot_%s" % str(block.get("id", "block")),
		center + Vector3(0.0, LOT_HEIGHT * 0.5, 0.0),
		Vector3(width, LOT_HEIGHT, depth),
		_lot_color(district)
	)

	var sidewalk_color := Color(0.30, 0.30, 0.292, 1.0)
	_add_surface_box("WalkN_%s" % str(block.get("id", "")), center + Vector3(0.0, SIDEWALK_HEIGHT * 0.5, -depth * 0.5 + sidewalk * 0.5), Vector3(width, SIDEWALK_HEIGHT, sidewalk), sidewalk_color)
	_add_surface_box("WalkS_%s" % str(block.get("id", "")), center + Vector3(0.0, SIDEWALK_HEIGHT * 0.5, depth * 0.5 - sidewalk * 0.5), Vector3(width, SIDEWALK_HEIGHT, sidewalk), sidewalk_color)
	_add_surface_box("WalkW_%s" % str(block.get("id", "")), center + Vector3(-width * 0.5 + sidewalk * 0.5, SIDEWALK_HEIGHT * 0.5, 0.0), Vector3(sidewalk, SIDEWALK_HEIGHT, maxf(depth - sidewalk * 2.0, 1.0)), sidewalk_color)
	_add_surface_box("WalkE_%s" % str(block.get("id", "")), center + Vector3(width * 0.5 - sidewalk * 0.5, SIDEWALK_HEIGHT * 0.5, 0.0), Vector3(sidewalk, SIDEWALK_HEIGHT, maxf(depth - sidewalk * 2.0, 1.0)), sidewalk_color)

func _lot_color(district: String) -> Color:
	match district:
		"civic":
			return Color(0.20, 0.205, 0.205, 1.0)
		"commercial":
			return Color(0.175, 0.178, 0.177, 1.0)
		"industrial":
			return Color(0.13, 0.132, 0.132, 1.0)
		"residential":
			return Color(0.155, 0.165, 0.153, 1.0)
		_:
			return Color(0.16, 0.162, 0.158, 1.0)

func _build_regular_block(block: Dictionary, district: String) -> void:
	var primary: Vector3 = block.get("primary_frontage", Vector3(0, 0, -1)) as Vector3
	match district:
		"commercial":
			_spawn_frontage_row(block, primary, 3, ["store", "shop", "office", "building"], 14.0, 1.35, 7.0)
		"industrial":
			_spawn_frontage_row(block, primary, 2, ["industrial", "warehouse", "factory", "building"], 17.0, 2.4, 6.2)
			_add_service_yard(block, -primary, 0.32)
		"residential":
			_spawn_frontage_row(block, primary, 2, ["apartment", "residential", "building"], 15.0, 2.0, 6.0)
			_add_courtyard(block, 0.30, Color(0.17, 0.23, 0.17, 1.0))
		_:
			_spawn_frontage_row(block, primary, 2, ["store", "apartment", "office", "building"], 15.0, 1.8, 6.5)

func _build_police_block(block: Dictionary) -> void:
	var direction: Vector3 = block.get("primary_frontage", Vector3(1, 0, 0)) as Vector3
	var center: Vector3 = block.get("center", Vector3.ZERO) as Vector3
	var envelope := Vector2(minf(_lateral_span(block, direction) * 0.62, 23.0), minf(_depth_span(block, direction) * 0.55, 19.0))
	var position_value := _frontage_center(block, direction, envelope.y, 2.4)
	_spawn_building("PoliceHeadquarters", position_value, direction, envelope, Vector3(envelope.x, 8.0, envelope.y), ["office", "building", "example", "prebuilt"], 100)
	var lateral := _lateral(direction)
	var forecourt: Vector3 = _frontage_point(block, direction) - direction * 3.2
	_add_surface_box("PoliceForecourt", forecourt + Vector3(0, 0.06, 0), _oriented_surface_size(direction, Vector2(7.0, 10.0), 0.035), Color(0.26, 0.265, 0.265, 1.0))
	var parking_center: Vector3 = center - direction * (_depth_span(block, direction) * 0.27) + lateral * minf(_lateral_span(block, direction) * 0.28, 10.0)
	_add_parking_surface("PoliceParking", parking_center, direction, Vector2(8.5, 11.0))

func _build_contraband_block(block: Dictionary) -> void:
	var primary: Vector3 = block.get("primary_frontage", Vector3(-1, 0, 0)) as Vector3
	var secondary: Vector3 = block.get("secondary_frontage", Vector3(0, 0, 1)) as Vector3
	_spawn_frontage_row(block, primary, 2, ["store", "apartment", "building", "example"], 14.5, 1.2, 6.3)
	_spawn_secondary_corner(block, secondary, primary, ["apartment", "store", "building"], 14.0, 5.8, 210)
	_add_courtyard(block, 0.24, Color(0.14, 0.16, 0.14, 1.0))

func _build_arms_block(block: Dictionary) -> void:
	var primary: Vector3 = block.get("primary_frontage", Vector3(-1, 0, 0)) as Vector3
	var secondary: Vector3 = block.get("secondary_frontage", Vector3(0, 0, -1)) as Vector3
	var main_envelope := Vector2(minf(_lateral_span(block, primary) * 0.55, 24.0), minf(_depth_span(block, primary) * 0.50, 19.0))
	var main_position := _frontage_center(block, primary, main_envelope.y, 2.5)
	_spawn_building("ArmsHeadquarters", main_position, primary, main_envelope, Vector3(main_envelope.x, 6.8, main_envelope.y), ["industrial", "warehouse", "building", "example"], 300)
	_spawn_secondary_corner(block, secondary, primary, ["industrial", "store", "building"], 13.0, 5.5, 301)
	_add_service_yard(block, -primary, 0.36)

func _build_commons(block: Dictionary) -> void:
	var center: Vector3 = block.get("center", Vector3.ZERO) as Vector3
	var width: float = float(block.get("width", 40.0))
	var depth: float = float(block.get("depth", 40.0))
	var sidewalk: float = float(_plan.get("sidewalk_width", 2.15))
	_add_surface_box("CentralCommons", center + Vector3(0, 0.065, 0), Vector3(maxf(width - sidewalk * 3.0, 10.0), 0.045, maxf(depth - sidewalk * 3.0, 10.0)), Color(0.285, 0.278, 0.26, 1.0))
	# Keep the center genuinely public/open. Two real storefront buildings frame
	# opposite sides rather than filling the plaza with procedural kiosks.
	var north := Vector3(0, 0, -1)
	var south := Vector3(0, 0, 1)
	var envelope := Vector2(minf(width * 0.28, 13.5), 10.5)
	var north_pos := _frontage_center(block, north, envelope.y, 1.2) + Vector3(width * 0.23, 0, 0)
	var south_pos := _frontage_center(block, south, envelope.y, 1.2) - Vector3(width * 0.23, 0, 0)
	_spawn_building("CommonsStoreNorth", north_pos, north, envelope, Vector3(envelope.x, 5.0, envelope.y), ["store", "shop", "building"], 400)
	_spawn_building("CommonsStoreSouth", south_pos, south, envelope, Vector3(envelope.x, 5.0, envelope.y), ["store", "shop", "building"], 401)

func _spawn_frontage_row(block: Dictionary, direction: Vector3, count: int, tokens: Array[String], max_depth: float, setback: float, fallback_height: float) -> void:
	var lateral_span: float = _lateral_span(block, direction)
	var sidewalk: float = float(_plan.get("sidewalk_width", 2.15))
	var usable: float = maxf(lateral_span - sidewalk * 2.0 - 2.0, 8.0)
	var slot: float = usable / float(maxi(count, 1))
	var lateral := _lateral(direction)
	var max_width: float = maxf(minf(slot - 1.2, 19.0), 7.0)
	var depth: float = minf(max_depth, maxf(_depth_span(block, direction) * 0.45, 9.0))
	var base_position := _frontage_center(block, direction, depth, setback)
	for index: int in range(count):
		var offset: float = -usable * 0.5 + slot * (float(index) + 0.5)
		var position_value: Vector3 = base_position + lateral * offset
		var envelope := Vector2(max_width, depth)
		_spawn_building("CityBuilding_%03d" % _building_serial, position_value, direction, envelope, Vector3(max_width, fallback_height + float(_building_serial % 3) * 0.5, depth), tokens, _building_serial)
		_building_serial += 1

func _spawn_secondary_corner(block: Dictionary, direction: Vector3, avoid_direction: Vector3, tokens: Array[String], max_depth: float, fallback_height: float, variant: int) -> void:
	var depth: float = minf(max_depth, _depth_span(block, direction) * 0.42)
	var width: float = minf(_lateral_span(block, direction) * 0.34, 15.0)
	var base := _frontage_center(block, direction, depth, 1.7)
	# Shift toward the corner opposite the primary frontage. Compare relative lot
	# offsets, never absolute world coordinates, so this behaves the same anywhere.
	var center: Vector3 = block.get("center", Vector3.ZERO) as Vector3
	var lateral := _lateral(direction)
	var test_a: Vector3 = base + lateral * (_lateral_span(block, direction) * 0.23)
	var test_b: Vector3 = base - lateral * (_lateral_span(block, direction) * 0.23)
	var a_bias: float = (test_a - center).dot(avoid_direction)
	var b_bias: float = (test_b - center).dot(avoid_direction)
	var position_value: Vector3 = test_a if a_bias < b_bias else test_b
	_spawn_building("CityBuilding_%03d" % _building_serial, position_value, direction, Vector2(width, depth), Vector3(width, fallback_height, depth), tokens, variant)
	_building_serial += 1

func _spawn_building(node_name: String, position_value: Vector3, direction: Vector3, footprint: Vector2, fallback_size: Vector3, tokens: Array[String], variant: int) -> void:
	var building := QuaterniusCityBuilding3D.new()
	building.name = node_name
	building.position = position_value
	building.rotation.y = atan2(direction.x, direction.z)
	building.max_footprint = footprint
	building.target_size = fallback_size
	building.fallback_color = _building_fallback_color(tokens)
	building.preferred_tokens = tokens
	building.variant_index = variant
	building.allow_upscale = false
	add_child(building)

func _building_fallback_color(tokens: Array[String]) -> Color:
	var text := ""
	for token: String in tokens:
		text += " " + token.to_lower()
	if "industrial" in text or "warehouse" in text:
		return Color(0.19, 0.17, 0.15, 1.0)
	if "office" in text:
		return Color(0.17, 0.19, 0.22, 1.0)
	if "store" in text or "shop" in text:
		return Color(0.20, 0.195, 0.18, 1.0)
	return Color(0.18, 0.19, 0.18, 1.0)

func _frontage_center(block: Dictionary, direction: Vector3, building_depth: float, setback: float) -> Vector3:
	var center: Vector3 = block.get("center", Vector3.ZERO) as Vector3
	var half_depth: float = _depth_span(block, direction) * 0.5
	return center + direction * maxf(half_depth - building_depth * 0.5 - setback, 0.0)

func _frontage_point(block: Dictionary, direction: Vector3, lateral_offset: float = 0.0) -> Vector3:
	var center: Vector3 = block.get("center", Vector3.ZERO) as Vector3
	var half_depth: float = _depth_span(block, direction) * 0.5
	var sidewalk: float = float(_plan.get("sidewalk_width", 2.15))
	return center + direction * maxf(half_depth - sidewalk * 0.52, 0.0) + _lateral(direction) * lateral_offset

func _lateral_span(block: Dictionary, direction: Vector3) -> float:
	return float(block.get("depth", 40.0)) if absf(direction.x) > 0.5 else float(block.get("width", 40.0))

func _depth_span(block: Dictionary, direction: Vector3) -> float:
	return float(block.get("width", 40.0)) if absf(direction.x) > 0.5 else float(block.get("depth", 40.0))

func _lateral(direction: Vector3) -> Vector3:
	return Vector3(-direction.z, 0.0, direction.x)

func _add_courtyard(block: Dictionary, scale_factor: float, color: Color) -> void:
	var center: Vector3 = block.get("center", Vector3.ZERO) as Vector3
	var width: float = float(block.get("width", 40.0))
	var depth: float = float(block.get("depth", 40.0))
	_add_surface_box("Courtyard_%03d" % _building_serial, center + Vector3(0, 0.055, 0), Vector3(maxf(width * scale_factor, 7.0), 0.03, maxf(depth * scale_factor, 7.0)), color)

func _add_service_yard(block: Dictionary, direction: Vector3, scale_factor: float) -> void:
	var center: Vector3 = block.get("center", Vector3.ZERO) as Vector3
	var span: float = _lateral_span(block, direction)
	var depth_span: float = _depth_span(block, direction)
	var yard_depth: float = minf(depth_span * 0.25, 10.0)
	var position_value: Vector3 = center + direction * depth_span * 0.28
	var size := Vector2(minf(span * scale_factor, 16.0), yard_depth)
	_add_surface_box("ServiceYard_%03d" % _building_serial, position_value + Vector3(0, 0.055, 0), _oriented_surface_size(direction, size, 0.03), Color(0.09, 0.092, 0.092, 1.0))

func _add_parking_surface(node_name: String, center: Vector3, direction: Vector3, size: Vector2) -> void:
	_add_surface_box(node_name, center + Vector3(0, 0.055, 0), _oriented_surface_size(direction, size, 0.03), Color(0.095, 0.097, 0.097, 1.0))

func _oriented_surface_size(direction: Vector3, size: Vector2, height: float) -> Vector3:
	return Vector3(size.y, height, size.x) if absf(direction.x) > 0.5 else Vector3(size.x, height, size.y)

func _place_gameplay_nodes() -> void:
	var police := _block("police")
	var contraband := _block("contraband")
	var arms := _block("arms")
	var drug := _block("neighborhood_nw")
	var gunrunner := _block("market_east")
	var interdict := _block("foundry_west")
	var commons_center: Vector3 = _commons_block.get("center", Vector3.ZERO) as Vector3

	_place_base_entrance("PrecinctEntrance", police)
	_place_base_entrance("SafehouseEntrance", contraband)
	_place_base_entrance("WorkshopEntrance", arms)

	var drug_dir: Vector3 = drug.get("primary_frontage", Vector3(1, 0, 0)) as Vector3
	var gun_dir: Vector3 = gunrunner.get("primary_frontage", Vector3(-1, 0, 0)) as Vector3
	var interdict_dir: Vector3 = interdict.get("primary_frontage", Vector3(0, 0, -1)) as Vector3
	_set_node_position("DrugBuyer", _frontage_point(drug, drug_dir, -5.5))
	_set_node_position("GunrunnerBuyer", _frontage_point(gunrunner, gun_dir, 5.0))
	_set_node_position("InterdictionCache", _frontage_point(interdict, interdict_dir, -5.0))

	_set_node_position("FFAEntrance", commons_center + Vector3(0.0, 0.0, -2.0))
	_set_node_position("KnifeVendor", commons_center + Vector3(-3.8, 0.0, 4.2))
	_set_node_position("BatVendor", commons_center + Vector3(0.0, 0.0, 4.2))
	_set_node_position("PistolVendor", commons_center + Vector3(3.8, 0.0, 4.2))

	_place_guard("BeatCopA", drug, drug_dir, -7.0)
	_place_guard("BeatCopB", police, police.get("primary_frontage", Vector3(1, 0, 0)) as Vector3, 7.0)
	_place_guard("ContrabandGuardA", gunrunner, gun_dir, -7.0)
	_place_guard("ContrabandGuardB", contraband, contraband.get("primary_frontage", Vector3(-1, 0, 0)) as Vector3, 7.0)
	_place_guard("ArmsGuardA", interdict, interdict_dir, -7.0)
	_place_guard("ArmsGuardB", arms, arms.get("primary_frontage", Vector3(-1, 0, 0)) as Vector3, 7.0)

	if _player != null:
		_player.global_position = commons_center + Vector3(0.0, 0.95, 0.0)

func _place_base_entrance(node_name: String, block: Dictionary) -> void:
	if block.is_empty():
		return
	var node: Node3D = get_node_or_null(NodePath(node_name)) as Node3D
	if node == null:
		return
	var direction: Vector3 = block.get("primary_frontage", Vector3(0, 0, -1)) as Vector3
	var front: Vector3 = _frontage_point(block, direction)
	node.global_position = front
	# Return just inside the sidewalk/forecourt, never into the traffic lane.
	node.set("city_return_position", front - direction * 1.35 + Vector3(0.0, 0.95, 0.0))

func _place_guard(node_name: String, block: Dictionary, direction: Vector3, lateral_offset: float) -> void:
	var position_value: Vector3 = _frontage_point(block, direction, lateral_offset) - direction * 0.5
	position_value.y = 0.95
	_set_node_position(node_name, position_value)

func _set_node_position(node_name: String, position_value: Vector3) -> void:
	var node: Node3D = get_node_or_null(NodePath(node_name)) as Node3D
	if node != null:
		node.global_position = position_value

func _add_surface_box(node_name: String, center: Vector3, size: Vector3, color: Color) -> void:
	var pad := MeshInstance3D.new()
	pad.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = size
	pad.mesh = mesh
	pad.position = center
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.98
	pad.material_override = material
	add_child(pad)

func _add_static_box(node_name: String, size: Vector3, position_value: Vector3, color: Color) -> void:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = position_value
	add_child(body)
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.98
	mesh_instance.material_override = material
	body.add_child(mesh_instance)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)

func _restore_city_spawn() -> void:
	if _player == null:
		return
	var spawn_data: Dictionary = GameSession.take_next_city_spawn()
	if spawn_data.is_empty():
		return
	var position_value: Variant = spawn_data.get("position", Vector3.ZERO)
	if position_value is Vector3:
		_player.global_position = position_value as Vector3

func _update_territory() -> void:
	if _player == null:
		return
	var position_value: Vector3 = _player.global_position
	if _point_in_block(position_value, _commons_block, 2.0):
		GameSession.set_territory(GameSession.Territory.NEUTRAL)
		return
	var police_center: Vector3 = _block("police").get("center", Vector3.ZERO) as Vector3
	var contra_center: Vector3 = _block("contraband").get("center", Vector3.ZERO) as Vector3
	var arms_center: Vector3 = _block("arms").get("center", Vector3.ZERO) as Vector3
	var p := Vector2(position_value.x, position_value.z)
	var police_distance: float = p.distance_squared_to(Vector2(police_center.x, police_center.z))
	var contra_distance: float = p.distance_squared_to(Vector2(contra_center.x, contra_center.z))
	var arms_distance: float = p.distance_squared_to(Vector2(arms_center.x, arms_center.z))
	if police_distance <= contra_distance and police_distance <= arms_distance:
		GameSession.set_territory(GameSession.Territory.POLICE)
	elif contra_distance <= arms_distance:
		GameSession.set_territory(GameSession.Territory.CONTRABAND)
	else:
		GameSession.set_territory(GameSession.Territory.ARMS)

func _point_in_block(position_value: Vector3, block: Dictionary, margin: float = 0.0) -> bool:
	if block.is_empty():
		return false
	var center: Vector3 = block.get("center", Vector3.ZERO) as Vector3
	var width: float = float(block.get("width", 0.0)) + margin * 2.0
	var depth: float = float(block.get("depth", 0.0)) + margin * 2.0
	return absf(position_value.x - center.x) <= width * 0.5 and absf(position_value.z - center.z) <= depth * 0.5
