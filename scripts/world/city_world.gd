class_name CityWorld3D
extends Node3D

@export var player_path: NodePath = NodePath("Player")

const SIDEWALK_DEPTH := 1.65
const CURB_WIDTH := 0.16
const SIDEWALK_HEIGHT := 0.12
const LOT_HEIGHT := 0.055

var _player: Node3D = null
var _layout: Dictionary = {}
var _anchors: Dictionary = {}
var _commons_rect: Dictionary = {}
var _building_serial: int = 0

func _ready() -> void:
	_player = get_node_or_null(player_path) as Node3D
	QuaterniusAssetLocator.print_install_summary()
	_layout = CityCrafterLayoutBridge.build_layout()
	_build_city()
	_restore_city_spawn()
	_update_territory()

func _process(_delta: float) -> void:
	_update_territory()

func _build_city() -> void:
	var bounds_size: Vector2 = _layout.get("bounds_size", Vector2(160.0, 160.0)) as Vector2
	_add_static_box(
		self,
		"CityFoundation",
		Vector3(bounds_size.x + 22.0, 0.30, bounds_size.y + 22.0),
		Vector3(0.0, -0.18, 0.0),
		Color(0.095, 0.098, 0.102, 1.0)
	)

	var road_network := CityRoadNetwork3D.new()
	road_network.name = "StreetNetwork"
	road_network.configure_from_layout(_layout)
	add_child(road_network)

	_select_anchor_blocks()
	_build_generated_blocks()
	_build_street_dressing()
	_place_gameplay_nodes()
	print("Urban Brawl: public city layout source = ", _layout.get("source", "fallback"), " | blocks = ", (_layout.get("active_blocks", []) as Array).size())

func _select_anchor_blocks() -> void:
	var bounds_min: Vector2 = _layout.get("bounds_min", Vector2(-75, -75)) as Vector2
	var bounds_max: Vector2 = _layout.get("bounds_max", Vector2(75, 75)) as Vector2
	var span := bounds_max - bounds_min
	var excluded: Dictionary = {}

	var commons := _choose_block(Vector2.ZERO, excluded, true)
	excluded[commons] = true
	var police := _choose_block(Vector2(bounds_min.x + span.x * 0.17, 0.0), excluded, true)
	excluded[police] = true
	var contraband := _choose_block(Vector2(bounds_min.x + span.x * 0.82, bounds_min.y + span.y * 0.22), excluded, true)
	excluded[contraband] = true
	var arms := _choose_block(Vector2(bounds_min.x + span.x * 0.82, bounds_min.y + span.y * 0.78), excluded, true)

	_anchors = {
		"commons": commons,
		"police": police,
		"contraband": contraband,
		"arms": arms,
	}
	_commons_rect = _block_rect(commons)

func _choose_block(target: Vector2, excluded: Dictionary, prefer_large: bool = false) -> Vector2i:
	var active_variant: Variant = _layout.get("active_blocks", [])
	var active: Array = active_variant as Array if active_variant is Array else []
	var best := Vector2i.ZERO
	var best_score: float = 1000000.0
	for value: Variant in active:
		if not value is Vector2i:
			continue
		var grid_pos := value as Vector2i
		if excluded.has(grid_pos):
			continue
		var rect: Dictionary = _block_rect(grid_pos)
		var center: Vector3 = rect.get("center", Vector3.ZERO) as Vector3
		var width: float = float(rect.get("width", 22.0))
		var depth: float = float(rect.get("depth", 22.0))
		var area_bonus: float = minf(width * depth / 240.0, 5.0) if prefer_large else 0.0
		var score: float = Vector2(center.x, center.z).distance_to(target) - area_bonus
		if score < best_score:
			best_score = score
			best = grid_pos
	return best

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

func _build_generated_blocks() -> void:
	var active_variant: Variant = _layout.get("active_blocks", [])
	var active: Array = active_variant as Array if active_variant is Array else []
	var districts_variant: Variant = _layout.get("districts", {})
	var districts: Dictionary = districts_variant as Dictionary if districts_variant is Dictionary else {}

	for value: Variant in active:
		if not value is Vector2i:
			continue
		var grid_pos := value as Vector2i
		var rect: Dictionary = _block_rect(grid_pos)
		var district: String = str(districts.get(grid_pos, "residential"))
		_add_block_surface(grid_pos, rect, district)

		if grid_pos == (_anchors.get("commons", Vector2i.ZERO) as Vector2i):
			_build_commons(rect)
		elif grid_pos == (_anchors.get("police", Vector2i.ZERO) as Vector2i):
			_build_faction_base(rect, "police")
		elif grid_pos == (_anchors.get("contraband", Vector2i.ZERO) as Vector2i):
			_build_faction_base(rect, "contraband")
		elif grid_pos == (_anchors.get("arms", Vector2i.ZERO) as Vector2i):
			_build_faction_base(rect, "arms")
		else:
			_build_generic_block(rect, district)

func _add_block_surface(grid_pos: Vector2i, rect: Dictionary, district: String) -> void:
	var center: Vector3 = rect.get("center", Vector3.ZERO) as Vector3
	var width: float = float(rect.get("width", 22.0))
	var depth: float = float(rect.get("depth", 22.0))
	var lot_width: float = maxf(width - SIDEWALK_DEPTH * 2.0, 2.0)
	var lot_depth: float = maxf(depth - SIDEWALK_DEPTH * 2.0, 2.0)

	_add_surface_box(
		"Lot_%d_%d" % [grid_pos.x, grid_pos.y],
		center + Vector3(0.0, LOT_HEIGHT * 0.5, 0.0),
		Vector3(lot_width, LOT_HEIGHT, lot_depth),
		_lot_color(district)
	)

	var sidewalk_color := _sidewalk_color(district)
	var north_z: float = center.z - depth * 0.5 + SIDEWALK_DEPTH * 0.5
	var south_z: float = center.z + depth * 0.5 - SIDEWALK_DEPTH * 0.5
	var west_x: float = center.x - width * 0.5 + SIDEWALK_DEPTH * 0.5
	var east_x: float = center.x + width * 0.5 - SIDEWALK_DEPTH * 0.5
	_add_surface_box("SidewalkN_%d_%d" % [grid_pos.x, grid_pos.y], Vector3(center.x, SIDEWALK_HEIGHT * 0.5, north_z), Vector3(width, SIDEWALK_HEIGHT, SIDEWALK_DEPTH), sidewalk_color)
	_add_surface_box("SidewalkS_%d_%d" % [grid_pos.x, grid_pos.y], Vector3(center.x, SIDEWALK_HEIGHT * 0.5, south_z), Vector3(width, SIDEWALK_HEIGHT, SIDEWALK_DEPTH), sidewalk_color)
	_add_surface_box("SidewalkW_%d_%d" % [grid_pos.x, grid_pos.y], Vector3(west_x, SIDEWALK_HEIGHT * 0.5, center.z), Vector3(SIDEWALK_DEPTH, SIDEWALK_HEIGHT, maxf(depth - SIDEWALK_DEPTH * 2.0, 1.0)), sidewalk_color)
	_add_surface_box("SidewalkE_%d_%d" % [grid_pos.x, grid_pos.y], Vector3(east_x, SIDEWALK_HEIGHT * 0.5, center.z), Vector3(SIDEWALK_DEPTH, SIDEWALK_HEIGHT, maxf(depth - SIDEWALK_DEPTH * 2.0, 1.0)), sidewalk_color)

	var curb_color := Color(0.36, 0.36, 0.345, 1.0)
	_add_surface_box("CurbN_%d_%d" % [grid_pos.x, grid_pos.y], Vector3(center.x, 0.075, center.z - depth * 0.5 + CURB_WIDTH * 0.5), Vector3(width, 0.15, CURB_WIDTH), curb_color)
	_add_surface_box("CurbS_%d_%d" % [grid_pos.x, grid_pos.y], Vector3(center.x, 0.075, center.z + depth * 0.5 - CURB_WIDTH * 0.5), Vector3(width, 0.15, CURB_WIDTH), curb_color)
	_add_surface_box("CurbW_%d_%d" % [grid_pos.x, grid_pos.y], Vector3(center.x - width * 0.5 + CURB_WIDTH * 0.5, 0.075, center.z), Vector3(CURB_WIDTH, 0.15, depth), curb_color)
	_add_surface_box("CurbE_%d_%d" % [grid_pos.x, grid_pos.y], Vector3(center.x + width * 0.5 - CURB_WIDTH * 0.5, 0.075, center.z), Vector3(CURB_WIDTH, 0.15, depth), curb_color)

func _lot_color(district: String) -> Color:
	match district:
		"commercial":
			return Color(0.185, 0.185, 0.178, 1.0)
		"industrial":
			return Color(0.125, 0.128, 0.127, 1.0)
		_:
			return Color(0.155, 0.162, 0.15, 1.0)

func _sidewalk_color(district: String) -> Color:
	match district:
		"commercial":
			return Color(0.31, 0.305, 0.292, 1.0)
		"industrial":
			return Color(0.245, 0.245, 0.235, 1.0)
		_:
			return Color(0.285, 0.285, 0.272, 1.0)

func _build_generic_block(rect: Dictionary, district: String) -> void:
	var center: Vector3 = rect.get("center", Vector3.ZERO) as Vector3
	var width: float = float(rect.get("width", 22.0))
	var depth: float = float(rect.get("depth", 22.0))
	var large_x: bool = width > 31.0
	var large_z: bool = depth > 31.0
	var tokens: Array[String] = _district_tokens(district)
	var fallback: Color = _district_fallback(district)
	var base_height: float = 5.0 if district == "industrial" else (7.0 if district == "commercial" else 5.6)

	if large_x and large_z:
		_build_superblock(center, width, depth, district, tokens, fallback, base_height)
		return

	if large_x:
		_build_long_x_block(center, width, depth, district, tokens, fallback, base_height)
		return

	if large_z:
		_build_long_z_block(center, width, depth, district, tokens, fallback, base_height)
		return

	var inset: float = 8.2 if district == "industrial" else (4.8 if district == "commercial" else 5.5)
	var target_width: float = maxf(minf(width - inset, 15.0), 8.0)
	var target_depth: float = maxf(minf(depth - inset, 13.5), 8.0)
	var height: float = base_height + float(_building_serial % 4) * 0.60
	var toward: Vector3 = _toward_city(center)
	var setback: float = 2.0 if district == "commercial" else (2.6 if district == "industrial" else 2.3)
	var building_center: Vector3 = _frontage_aligned_center(center, width, depth, target_width, target_depth, toward, setback)
	_add_external_building(
		"CityBuilding_%03d" % _building_serial,
		Vector3(target_width, height, target_depth),
		Vector3(building_center.x, height * 0.5, building_center.z),
		fallback,
		_building_serial,
		tokens,
		_yaw_for_direction(toward)
	)
	var detail_serial: int = _building_serial
	_building_serial += 1

	if district == "industrial":
		var lateral := _lateral(toward)
		var yard_center: Vector3 = center - toward * 4.2
		var yard_size := Vector2(5.8, 10.0) if absf(toward.x) > 0.5 else Vector2(10.0, 5.8)
		_add_parking_lot("IndustrialYard_%03d" % detail_serial, yard_center, yard_size, toward, detail_serial, 2)
		_add_prop("ServiceBin_%03d" % detail_serial, yard_center + lateral * 3.2, ["dumpster", "trash", "bin"], detail_serial, 1.25, 1.8)
	elif district == "commercial" and detail_serial % 3 == 0:
		var pocket_center: Vector3 = center - toward * 4.0
		var pocket_size := Vector2(4.8, 8.5) if absf(toward.x) > 0.5 else Vector2(8.5, 4.8)
		_add_parking_lot("ShopParking_%03d" % detail_serial, pocket_center, pocket_size, toward, detail_serial, 1)

func _build_superblock(center: Vector3, width: float, depth: float, district: String, tokens: Array[String], fallback: Color, base_height: float) -> void:
	var ns_width: float = minf(width * 0.48, 22.0)
	var ns_depth: float = minf(depth * 0.24, 12.5)
	var ew_width: float = minf(width * 0.24, 12.5)
	var ew_depth: float = minf(depth * 0.48, 22.0)
	var z_offset: float = depth * 0.5 - ns_depth * 0.5 - 2.4
	var x_offset: float = width * 0.5 - ew_width * 0.5 - 2.4

	var placements: Array[Dictionary] = [
		{"size": Vector3(ns_width, base_height + 1.2, ns_depth), "pos": center + Vector3(0, 0, -z_offset), "dir": Vector3(0, 0, -1)},
		{"size": Vector3(ns_width, base_height + 0.5, ns_depth), "pos": center + Vector3(0, 0, z_offset), "dir": Vector3(0, 0, 1)},
		{"size": Vector3(ew_width, base_height + 0.8, ew_depth), "pos": center + Vector3(-x_offset, 0, 0), "dir": Vector3(-1, 0, 0)},
		{"size": Vector3(ew_width, base_height + 1.6, ew_depth), "pos": center + Vector3(x_offset, 0, 0), "dir": Vector3(1, 0, 0)},
	]
	for placement: Dictionary in placements:
		var size: Vector3 = placement["size"] as Vector3
		var pos: Vector3 = placement["pos"] as Vector3
		var direction: Vector3 = placement["dir"] as Vector3
		_add_external_building(
			"CityBuilding_%03d" % _building_serial,
			size,
			Vector3(pos.x, size.y * 0.5, pos.z),
			fallback,
			_building_serial,
			tokens,
			_yaw_for_direction(direction)
		)
		_building_serial += 1
	_add_courtyard(center, Vector2(maxf(width * 0.30, 8.0), maxf(depth * 0.30, 8.0)), district)
	if district != "residential":
		_add_service_lane("SuperblockService_%03d" % _building_serial, center + Vector3(0.0, 0.0, depth * 0.18), Vector2(maxf(width * 0.28, 9.0), 3.2))

func _build_long_x_block(center: Vector3, width: float, depth: float, district: String, tokens: Array[String], fallback: Color, base_height: float) -> void:
	var direction := Vector3(0.0, 0.0, -1.0 if center.z >= 0.0 else 1.0)
	var count: int = 3 if width > 50.0 else 2
	var slot: float = (width - 6.0) / float(count)
	var building_depth: float = minf(depth - 7.0, 12.5)
	var row_z: float = center.z + direction.z * maxf(depth * 0.5 - building_depth * 0.5 - 2.2, 0.0)
	for index: int in range(count):
		var x: float = center.x - width * 0.5 + 3.0 + slot * (float(index) + 0.5)
		var h: float = base_height + float((_building_serial + index) % 3) * 0.75
		_add_external_building("CityBuilding_%03d" % _building_serial, Vector3(slot * 0.80, h, building_depth), Vector3(x, h * 0.5, row_z), fallback, _building_serial, tokens, _yaw_for_direction(direction))
		_building_serial += 1
	var service_z: float = center.z - direction.z * maxf(depth * 0.5 - 3.4, 0.0)
	_add_service_lane("RearLaneX_%03d" % _building_serial, Vector3(center.x, 0.0, service_z), Vector2(maxf(width - 5.0, 9.0), 3.1))
	if district == "industrial" or (_building_serial % 2 == 0 and district == "commercial"):
		_add_prop("RearDumpsterX_%03d" % _building_serial, Vector3(center.x + width * 0.28, 0.0, service_z), ["dumpster", "trash", "bin"], _building_serial, 1.25, 1.9)

func _build_long_z_block(center: Vector3, width: float, depth: float, district: String, tokens: Array[String], fallback: Color, base_height: float) -> void:
	var direction := Vector3(-1.0 if center.x >= 0.0 else 1.0, 0.0, 0.0)
	var count: int = 3 if depth > 50.0 else 2
	var slot: float = (depth - 6.0) / float(count)
	var building_width: float = minf(width - 7.0, 12.5)
	var row_x: float = center.x + direction.x * maxf(width * 0.5 - building_width * 0.5 - 2.2, 0.0)
	for index: int in range(count):
		var z: float = center.z - depth * 0.5 + 3.0 + slot * (float(index) + 0.5)
		var h: float = base_height + float((_building_serial + index) % 3) * 0.75
		_add_external_building("CityBuilding_%03d" % _building_serial, Vector3(building_width, h, slot * 0.80), Vector3(row_x, h * 0.5, z), fallback, _building_serial, tokens, _yaw_for_direction(direction))
		_building_serial += 1
	var service_x: float = center.x - direction.x * maxf(width * 0.5 - 3.4, 0.0)
	_add_service_lane("RearLaneZ_%03d" % _building_serial, Vector3(service_x, 0.0, center.z), Vector2(3.1, maxf(depth - 5.0, 9.0)))
	if district == "industrial" or (_building_serial % 2 == 0 and district == "commercial"):
		_add_prop("RearDumpsterZ_%03d" % _building_serial, Vector3(service_x, 0.0, center.z + depth * 0.28), ["dumpster", "trash", "bin"], _building_serial, 1.25, 1.9)

func _build_faction_base(rect: Dictionary, faction: String) -> void:
	var center: Vector3 = rect.get("center", Vector3.ZERO) as Vector3
	var width: float = float(rect.get("width", 22.0))
	var depth: float = float(rect.get("depth", 22.0))
	var toward: Vector3 = _toward_city(center)
	var height: float = 8.0 if faction == "police" else (6.2 if faction == "contraband" else 6.8)
	var tokens: Array[String]
	var fallback: Color
	match faction:
		"police":
			tokens = ["office", "civic", "building"]
			fallback = Color(0.16, 0.18, 0.22, 1.0)
		"contraband":
			tokens = ["apartment", "store", "shop", "building"]
			fallback = Color(0.16, 0.18, 0.16, 1.0)
		_:
			tokens = ["industrial", "warehouse", "store", "building"]
			fallback = Color(0.20, 0.17, 0.15, 1.0)

	var building_width: float = maxf(minf(width * 0.62, 20.0), 11.0)
	var building_depth: float = maxf(minf(depth * 0.56, 17.0), 10.0)
	var building_center: Vector3 = _frontage_aligned_center(center, width, depth, building_width, building_depth, toward, 2.7)
	_add_external_building(
		"%sHeadquarters" % faction.capitalize(),
		Vector3(building_width, height, building_depth),
		Vector3(building_center.x, height * 0.5, building_center.z),
		fallback,
		30 + _building_serial,
		tokens,
		_yaw_for_direction(toward)
	)
	var base_serial: int = _building_serial
	_building_serial += 1

	var front: Vector3 = _frontage_point(rect)
	var plaza_center: Vector3 = (front + building_center) * 0.5
	_add_plaza("%sForecourt" % faction.capitalize(), plaza_center, Vector2(5.5, 5.5), Color(0.29, 0.29, 0.285, 1.0))

	var rear_center: Vector3 = center - toward * 4.5
	var parking_size := Vector2(5.6, 10.0) if absf(toward.x) > 0.5 else Vector2(10.0, 5.6)
	_add_parking_lot("%sParking" % faction.capitalize(), rear_center, parking_size, toward, 90 + base_serial, 2 if faction == "police" else 1)
	if faction == "arms":
		_add_prop("ArmsLoadingPallet", rear_center + _lateral(toward) * 3.0, ["pallet", "crate", "box"], base_serial, 1.0, 1.6)

func _build_commons(rect: Dictionary) -> void:
	var center: Vector3 = rect.get("center", Vector3.ZERO) as Vector3
	var width: float = float(rect.get("width", 22.0))
	var depth: float = float(rect.get("depth", 22.0))
	_add_plaza("CentralCommons", center, Vector2(maxf(width - 3.0, 9.0), maxf(depth - 3.0, 9.0)), Color(0.315, 0.305, 0.29, 1.0))

	var kiosk_height: float = 3.6
	var kiosk_width: float = minf(maxf(width * 0.18, 4.5), 7.0)
	var kiosk_depth: float = minf(maxf(depth * 0.20, 4.5), 7.0)
	_add_external_building("CommonsKioskA", Vector3(kiosk_width, kiosk_height, kiosk_depth), center + Vector3(-width * 0.31, kiosk_height * 0.5, depth * 0.27), Color(0.23, 0.23, 0.22, 1.0), 70, ["store", "shop", "building"], 90.0)
	_add_external_building("CommonsKioskB", Vector3(kiosk_width, kiosk_height, kiosk_depth), center + Vector3(width * 0.31, kiosk_height * 0.5, -depth * 0.27), Color(0.23, 0.23, 0.22, 1.0), 71, ["store", "shop", "building"], -90.0)
	for index: int in range(4):
		var angle: float = float(index) * TAU / 4.0 + PI * 0.25
		var offset := Vector3(cos(angle), 0.0, sin(angle)) * minf(width, depth) * 0.28
		_add_prop("CommonsTree_%02d" % index, center + offset, ["tree", "planter", "plant"], 200 + index, 3.2, 2.4)
	for x: float in [-5.2, 5.2]:
		_add_prop("CommonsBollard_%s" % str(x), center + Vector3(x, 0.0, -depth * 0.38), ["bollard", "post", "barrier"], int(absf(x) * 10.0), 0.85, 0.65)

func _build_street_dressing() -> void:
	var active_variant: Variant = _layout.get("active_blocks", [])
	var active: Array = active_variant as Array if active_variant is Array else []
	var districts_variant: Variant = _layout.get("districts", {})
	var districts: Dictionary = districts_variant as Dictionary if districts_variant is Dictionary else {}
	var index: int = 0
	for value: Variant in active:
		if not value is Vector2i:
			continue
		var grid_pos := value as Vector2i
		var rect: Dictionary = _block_rect(grid_pos)
		var center: Vector3 = rect.get("center", Vector3.ZERO) as Vector3
		var direction := _toward_city(center)
		var lateral := _lateral(direction)
		var frontage := _frontage_point(rect)
		var width: float = float(rect.get("width", 22.0))
		var depth: float = float(rect.get("depth", 22.0))
		var district: String = str(districts.get(grid_pos, "residential"))
		var lateral_span: float = (depth if absf(direction.x) > 0.5 else width) * 0.30

		if index % 2 == 0:
			_add_prop("StreetLamp_%03d" % index, frontage + lateral * lateral_span - direction * 0.35, ["streetlight", "street_light", "lamp"], index, 3.4, 1.0)
		if index % 3 == 0:
			_add_prop("Hydrant_%03d" % index, frontage - lateral * lateral_span * 0.72 - direction * 0.30, ["hydrant", "fire_hydrant"], index, 0.82, 0.65)
		if district == "commercial" and index % 3 == 1:
			_add_prop("StreetBench_%03d" % index, frontage + lateral * lateral_span * 0.45 - direction * 0.45, ["bench", "seat"], index, 0.95, 2.0, _yaw_for_direction(lateral))
		if district != "industrial" and index % 4 == 1:
			_add_prop("StreetTree_%03d" % index, frontage - lateral * lateral_span * 0.50 - direction * 0.55, ["tree", "planter", "plant"], index, 3.0, 2.2)
		if index % 5 == 2:
			var parked_pos: Vector3 = frontage + direction * 2.15 + lateral * lateral_span * 0.25
			_add_prop("ParkedVehicle_%03d" % index, parked_pos, ["car", "vehicle", "sedan", "van"], index, 1.45, 4.4, _yaw_for_direction(lateral))
		if district == "commercial" and index % 4 == 2:
			_add_prop("StreetTrash_%03d" % index, frontage - lateral * lateral_span - direction * 0.45, ["trash", "garbage", "bin"], index, 1.0, 1.3)
		index += 1

	if not _commons_rect.is_empty():
		var commons_center: Vector3 = _commons_rect.get("center", Vector3.ZERO) as Vector3
		for offset: Vector3 in [Vector3(-4.2, 0, -2.8), Vector3(4.2, 0, 2.8)]:
			_add_prop("CommonsBench_%s" % str(offset), commons_center + offset, ["bench", "seat"], int(absf(offset.x) * 10.0), 0.95, 2.1, 90.0)

func _place_gameplay_nodes() -> void:
	var police_rect: Dictionary = _block_rect(_anchors.get("police", Vector2i.ZERO) as Vector2i)
	var contra_rect: Dictionary = _block_rect(_anchors.get("contraband", Vector2i.ZERO) as Vector2i)
	var arms_rect: Dictionary = _block_rect(_anchors.get("arms", Vector2i.ZERO) as Vector2i)
	var commons_center: Vector3 = _commons_rect.get("center", Vector3.ZERO) as Vector3

	_place_base_entrance("PrecinctEntrance", police_rect)
	_place_base_entrance("SafehouseEntrance", contra_rect)
	_place_base_entrance("WorkshopEntrance", arms_rect)

	var excluded: Dictionary = {
		_anchors.get("commons", Vector2i.ZERO): true,
		_anchors.get("police", Vector2i.ZERO): true,
		_anchors.get("contraband", Vector2i.ZERO): true,
		_anchors.get("arms", Vector2i.ZERO): true,
	}
	var bounds_min: Vector2 = _layout.get("bounds_min", Vector2(-75, -75)) as Vector2
	var bounds_max: Vector2 = _layout.get("bounds_max", Vector2(75, 75)) as Vector2
	var span := bounds_max - bounds_min
	var drug_block := _choose_block(Vector2(bounds_min.x + span.x * 0.28, bounds_min.y + span.y * 0.36), excluded)
	excluded[drug_block] = true
	var gun_block := _choose_block(Vector2(bounds_min.x + span.x * 0.70, bounds_min.y + span.y * 0.31), excluded)
	excluded[gun_block] = true
	var interdict_block := _choose_block(Vector2(bounds_min.x + span.x * 0.70, bounds_min.y + span.y * 0.69), excluded)

	var drug_rect := _block_rect(drug_block)
	var gun_rect := _block_rect(gun_block)
	var interdict_rect := _block_rect(interdict_block)
	var drug_pos: Vector3 = _frontage_point(drug_rect)
	var gun_pos: Vector3 = _frontage_point(gun_rect)
	var interdict_pos: Vector3 = _frontage_point(interdict_rect)
	_set_node_position("DrugBuyer", drug_pos)
	_set_node_position("GunrunnerBuyer", gun_pos)
	_set_node_position("InterdictionCache", interdict_pos)

	_set_node_position("FFAEntrance", commons_center + Vector3(0.0, 0.0, -3.2))
	_set_node_position("KnifeVendor", commons_center + Vector3(-3.0, 0.0, 3.4))
	_set_node_position("BatVendor", commons_center + Vector3(0.0, 0.0, 3.4))
	_set_node_position("PistolVendor", commons_center + Vector3(3.0, 0.0, 3.4))

	_place_guard_near_frontage("BeatCopA", drug_rect, -3.0)
	_place_guard_near_frontage("BeatCopB", police_rect, 3.0)
	_place_guard_near_frontage("ContrabandGuardA", gun_rect, -3.0)
	_place_guard_near_frontage("ContrabandGuardB", contra_rect, 3.0)
	_place_guard_near_frontage("ArmsGuardA", interdict_rect, -3.0)
	_place_guard_near_frontage("ArmsGuardB", arms_rect, 3.0)

	if _player != null:
		_player.global_position = commons_center + Vector3(0.0, 0.95, 0.0)

func _place_guard_near_frontage(node_name: String, rect: Dictionary, lateral_amount: float) -> void:
	var center: Vector3 = rect.get("center", Vector3.ZERO) as Vector3
	var direction := _toward_city(center)
	var position_value := _frontage_point(rect) + _lateral(direction) * lateral_amount - direction * 1.2
	position_value.y = 0.95
	_set_node_position(node_name, position_value)

func _place_base_entrance(node_name: String, rect: Dictionary) -> void:
	var node: Node3D = get_node_or_null(node_name) as Node3D
	if node == null:
		return
	var front: Vector3 = _frontage_point(rect)
	var toward: Vector3 = _toward_city(rect.get("center", Vector3.ZERO) as Vector3)
	node.global_position = front
	node.set("city_return_position", front + toward * 2.3 + Vector3(0.0, 0.95, 0.0))

func _set_node_position(node_name: String, position_value: Vector3) -> void:
	var node: Node3D = get_node_or_null(node_name) as Node3D
	if node != null:
		node.global_position = position_value

func _frontage_point(rect: Dictionary) -> Vector3:
	var center: Vector3 = rect.get("center", Vector3.ZERO) as Vector3
	var width: float = float(rect.get("width", 22.0))
	var depth: float = float(rect.get("depth", 22.0))
	var toward: Vector3 = _toward_city(center)
	if absf(toward.x) > 0.5:
		return Vector3(center.x + toward.x * (width * 0.5 - 1.2), 0.0, center.z)
	return Vector3(center.x, 0.0, center.z + toward.z * (depth * 0.5 - 1.2))

func _toward_city(center: Vector3) -> Vector3:
	var dx: float = -center.x
	var dz: float = -center.z
	if absf(dx) >= absf(dz) and absf(dx) > 0.001:
		return Vector3(1.0 if dx > 0.0 else -1.0, 0.0, 0.0)
	if absf(dz) > 0.001:
		return Vector3(0.0, 0.0, 1.0 if dz > 0.0 else -1.0)
	return Vector3(0.0, 0.0, -1.0)

func _frontage_aligned_center(center: Vector3, block_width: float, block_depth: float, building_width: float, building_depth: float, direction: Vector3, setback: float) -> Vector3:
	if absf(direction.x) > 0.5:
		var offset_x: float = maxf(block_width * 0.5 - building_width * 0.5 - setback, 0.0)
		return center + direction * offset_x
	var offset_z: float = maxf(block_depth * 0.5 - building_depth * 0.5 - setback, 0.0)
	return center + direction * offset_z

func _lateral(direction: Vector3) -> Vector3:
	return Vector3(-direction.z, 0.0, direction.x)

func _yaw_for_direction(direction: Vector3) -> float:
	return rad_to_deg(atan2(direction.x, direction.z))

func _district_tokens(district: String) -> Array[String]:
	match district:
		"commercial":
			return ["store", "shop", "office", "building"]
		"industrial":
			return ["industrial", "warehouse", "factory", "building"]
		_:
			return ["apartment", "residential", "house", "building"]

func _district_fallback(district: String) -> Color:
	match district:
		"commercial":
			return Color(0.19, 0.20, 0.21, 1.0)
		"industrial":
			return Color(0.19, 0.17, 0.15, 1.0)
		_:
			return Color(0.18, 0.19, 0.18, 1.0)

func _add_courtyard(center: Vector3, size: Vector2, district: String) -> void:
	var color := Color(0.22, 0.30, 0.21, 1.0) if district == "residential" else (Color(0.23, 0.23, 0.22, 1.0) if district == "commercial" else Color(0.15, 0.15, 0.15, 1.0))
	_add_plaza("Courtyard_%03d" % _building_serial, center, size, color)

func _add_parking_lot(node_name: String, center: Vector3, size: Vector2, frontage_direction: Vector3, serial: int, parked_vehicle_count: int = 0) -> void:
	_add_surface_box(node_name, center + Vector3(0.0, 0.085, 0.0), Vector3(size.x, 0.055, size.y), Color(0.09, 0.092, 0.092, 1.0))
	var lateral := _lateral(frontage_direction)
	var bay_count: int = maxi(int(floor((size.y if absf(frontage_direction.x) > 0.5 else size.x) / 2.4)), 2)
	var span: float = size.y if absf(frontage_direction.x) > 0.5 else size.x
	for index: int in range(1, bay_count):
		var offset: float = -span * 0.5 + span * float(index) / float(bay_count)
		var line_center: Vector3 = center + lateral * offset
		var line_size := Vector3(size.x * 0.72, 0.012, 0.08) if absf(frontage_direction.x) > 0.5 else Vector3(0.08, 0.012, size.y * 0.72)
		_add_surface_box("%s_Line_%02d" % [node_name, index], line_center + Vector3(0.0, 0.116, 0.0), line_size, Color(0.67, 0.66, 0.59, 1.0))
	for vehicle_index: int in range(parked_vehicle_count):
		var offset_factor: float = (float(vehicle_index) - float(parked_vehicle_count - 1) * 0.5) * 2.7
		var car_pos: Vector3 = center + lateral * offset_factor
		_add_prop("%s_Car_%02d" % [node_name, vehicle_index], car_pos, ["car", "vehicle", "sedan", "van"], serial + vehicle_index, 1.45, 4.3, _yaw_for_direction(lateral))

func _add_service_lane(node_name: String, center: Vector3, size: Vector2) -> void:
	_add_surface_box(node_name, center + Vector3(0.0, 0.075, 0.0), Vector3(size.x, 0.045, size.y), Color(0.078, 0.079, 0.08, 1.0))

func _add_plaza(node_name: String, center: Vector3, size: Vector2, color: Color) -> void:
	_add_surface_box(node_name, center + Vector3(0.0, 0.12, 0.0), Vector3(size.x, 0.08, size.y), color)

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

func _add_external_building(node_name: String, size: Vector3, position_value: Vector3, color: Color, variant: int, preferred: Array[String], yaw_degrees: float) -> void:
	var building := QuaterniusCityBuilding3D.new()
	building.name = node_name
	building.target_size = size
	building.fallback_color = color
	building.variant_index = variant
	building.preferred_tokens = preferred
	building.position = position_value
	building.rotation_degrees = Vector3(0.0, yaw_degrees, 0.0)
	add_child(building)

func _add_prop(node_name: String, position_value: Vector3, tokens: Array[String], variant: int, height: float, width: float = 0.0, yaw: float = 0.0) -> void:
	var prop := QuaterniusCityProp3D.new()
	prop.name = node_name
	prop.position = position_value
	prop.search_tokens = tokens
	prop.variant_index = variant
	prop.target_height = height
	prop.target_width = width
	prop.yaw_degrees = yaw
	add_child(prop)

func _add_static_box(parent: Node3D, node_name: String, size: Vector3, position_value: Vector3, color: Color) -> void:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = position_value
	parent.add_child(body)
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
	if _point_in_rect(position_value, _commons_rect, 2.5):
		GameSession.set_territory(GameSession.Territory.NEUTRAL)
		return

	var police_center: Vector3 = (_block_rect(_anchors.get("police", Vector2i.ZERO) as Vector2i)).get("center", Vector3.ZERO) as Vector3
	var contra_center: Vector3 = (_block_rect(_anchors.get("contraband", Vector2i.ZERO) as Vector2i)).get("center", Vector3.ZERO) as Vector3
	var arms_center: Vector3 = (_block_rect(_anchors.get("arms", Vector2i.ZERO) as Vector2i)).get("center", Vector3.ZERO) as Vector3
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

func _point_in_rect(position_value: Vector3, rect: Dictionary, margin: float = 0.0) -> bool:
	if rect.is_empty():
		return false
	var center: Vector3 = rect.get("center", Vector3.ZERO) as Vector3
	var width: float = float(rect.get("width", 0.0)) + margin * 2.0
	var depth: float = float(rect.get("depth", 0.0)) + margin * 2.0
	return absf(position_value.x - center.x) <= width * 0.5 and absf(position_value.z - center.z) <= depth * 0.5
