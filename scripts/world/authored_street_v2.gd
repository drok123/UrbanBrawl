class_name AuthoredStreetV2
extends Node3D

@export var player_path: NodePath = NodePath("Player")

const GROUND_Y := -0.12
const ROAD_Y := 0.012
const WALK_Y := 0.055
const LOT_Y := 0.025
const MAIN_ROAD_WIDTH := 8.0
const SIDE_ROAD_WIDTH := 7.0
const SIDEWALK_WIDTH := 2.4
const CROSS_X := 14.0

var _player: Node3D = null
var _materials: Dictionary = {}

func _ready() -> void:
	_player = get_node_or_null(player_path) as Node3D
	QuaterniusAssetLocator.print_install_summary()
	_build_materials()
	_build_ground_and_streets()
	_build_architecture()
	_build_alley_courtyard()
	_build_minimal_dressing()
	_place_gameplay()
	_restore_city_spawn()
	_update_territory()
	print("Urban Brawl: AUTHORED STREET V2 loaded — handcrafted layout / no city generator / no Road Generator")

func _process(_delta: float) -> void:
	_update_territory()

func _build_materials() -> void:
	_materials["ground"] = _material(Color(0.095, 0.092, 0.087, 1.0), 0.98)
	_materials["asphalt"] = _material(Color(0.055, 0.058, 0.060, 1.0), 0.92)
	_materials["alley"] = _material(Color(0.070, 0.069, 0.066, 1.0), 0.98)
	_materials["walk"] = _material(Color(0.31, 0.305, 0.285, 1.0), 0.96)
	_materials["curb"] = _material(Color(0.39, 0.38, 0.35, 1.0), 0.94)
	_materials["lot"] = _material(Color(0.145, 0.14, 0.132, 1.0), 0.98)
	_materials["civic"] = _material(Color(0.20, 0.205, 0.205, 1.0), 0.95)
	_materials["yard"] = _material(Color(0.095, 0.097, 0.095, 1.0), 0.99)
	_materials["line"] = _material(Color(0.72, 0.67, 0.40, 1.0), 0.82)
	_materials["wall"] = _material(Color(0.24, 0.235, 0.22, 1.0), 0.96)

func _build_ground_and_streets() -> void:
	_add_static_box("StreetSliceFoundation", Vector3(128.0, 0.24, 86.0), Vector3(0.0, GROUND_Y, 0.0), _materials["ground"])

	# Main street is deliberately compressed for the top-down camera. The cross
	# street is offset rather than centered so the composition does not read like
	# a generated grid.
	_add_surface("MainRoadWest", Vector3(-25.25, ROAD_Y, 0.0), Vector3(70.5, 0.025, MAIN_ROAD_WIDTH), _materials["asphalt"])
	_add_surface("MainRoadEast", Vector3(38.75, ROAD_Y, 0.0), Vector3(42.5, 0.025, MAIN_ROAD_WIDTH), _materials["asphalt"])
	_add_surface("CrossRoadNorth", Vector3(CROSS_X, ROAD_Y, -20.0), Vector3(SIDE_ROAD_WIDTH, 0.025, 32.0), _materials["asphalt"])
	_add_surface("CrossRoadSouth", Vector3(CROSS_X, ROAD_Y, 20.0), Vector3(SIDE_ROAD_WIDTH, 0.025, 32.0), _materials["asphalt"])
	_add_surface("MainIntersection", Vector3(CROSS_X, ROAD_Y + 0.001, 0.0), Vector3(SIDE_ROAD_WIDTH, 0.027, MAIN_ROAD_WIDTH), _materials["asphalt"])

	# Sidewalks are authored as street frontage, not generated from road edges.
	_add_walk_segment("WalkNorthWest", Vector3(-25.25, WALK_Y, -5.2), Vector3(70.5, 0.09, SIDEWALK_WIDTH))
	_add_walk_segment("WalkNorthEast", Vector3(38.75, WALK_Y, -5.2), Vector3(42.5, 0.09, SIDEWALK_WIDTH))
	_add_walk_segment("WalkSouthWest", Vector3(-25.25, WALK_Y, 5.2), Vector3(70.5, 0.09, SIDEWALK_WIDTH))
	_add_walk_segment("WalkSouthEast", Vector3(38.75, WALK_Y, 5.2), Vector3(42.5, 0.09, SIDEWALK_WIDTH))
	_add_walk_segment("WalkCrossWestNorth", Vector3(9.3, WALK_Y, -20.0), Vector3(SIDEWALK_WIDTH, 0.09, 32.0))
	_add_walk_segment("WalkCrossWestSouth", Vector3(9.3, WALK_Y, 20.0), Vector3(SIDEWALK_WIDTH, 0.09, 32.0))
	_add_walk_segment("WalkCrossEastNorth", Vector3(18.7, WALK_Y, -20.0), Vector3(SIDEWALK_WIDTH, 0.09, 32.0))
	_add_walk_segment("WalkCrossEastSouth", Vector3(18.7, WALK_Y, 20.0), Vector3(SIDEWALK_WIDTH, 0.09, 32.0))

	# Compact curb lips make the roadway legible without introducing another road
	# system. Corner pieces are intentionally omitted around the intersection.
	_add_curb("CurbNW", Vector3(-25.25, 0.105, -4.06), Vector3(70.5, 0.12, 0.16))
	_add_curb("CurbNE", Vector3(38.75, 0.105, -4.06), Vector3(42.5, 0.12, 0.16))
	_add_curb("CurbSW", Vector3(-25.25, 0.105, 4.06), Vector3(70.5, 0.12, 0.16))
	_add_curb("CurbSE", Vector3(38.75, 0.105, 4.06), Vector3(42.5, 0.12, 0.16))

	# Sparse center dashes establish direction without painting the whole scene.
	for x_value: float in [-52.0, -40.0, -28.0, -16.0, -4.0, 26.0, 38.0, 50.0]:
		_add_surface("MainDash_%d" % int(x_value + 60.0), Vector3(x_value, 0.032, 0.0), Vector3(4.5, 0.012, 0.12), _materials["line"])
	for z_value: float in [-30.0, -18.0, 18.0, 30.0]:
		_add_surface("CrossDash_%d" % int(z_value + 40.0), Vector3(CROSS_X, 0.032, z_value), Vector3(0.12, 0.012, 4.2), _materials["line"])

	# Lot surfaces are explicit composition zones, not procedural city blocks.
	_add_surface("PoliceLot", Vector3(-45.0, LOT_Y, -15.5), Vector3(26.0, 0.035, 17.0), _materials["civic"])
	_add_surface("NorthMarketLot", Vector3(-19.0, LOT_Y, -14.5), Vector3(24.0, 0.035, 15.0), _materials["lot"])
	_add_surface("ContrabandLot", Vector3(38.0, LOT_Y, -15.5), Vector3(39.0, 0.035, 17.0), _materials["lot"])
	_add_surface("SouthMarketLot", Vector3(-42.0, LOT_Y, 15.5), Vector3(22.0, 0.035, 17.0), _materials["lot"])
	_add_surface("ApartmentLot", Vector3(-25.0, LOT_Y, 16.5), Vector3(17.0, 0.035, 19.0), _materials["lot"])
	_add_surface("ArmsLot", Vector3(39.0, LOT_Y, 17.0), Vector3(39.0, 0.035, 20.0), _materials["yard"])

func _build_architecture() -> void:
	# Each building is intentionally assigned a role and frontage. Quaternius is
	# presentation here; it does not decide where anything belongs.
	_spawn_building("PrecinctExterior", Vector3(-47.0, 0.08, -15.0), Vector3(0, 0, 1), Vector2(20.0, 15.0), Vector3(20.0, 8.0, 15.0), ["office", "building", "example", "prebuilt"], 101)
	_spawn_building("Bodega", Vector3(-27.5, 0.08, -12.0), Vector3(0, 0, 1), Vector2(13.0, 10.5), Vector3(13.0, 5.0, 10.5), ["store", "shop", "building"], 11)
	_spawn_building("PawnShop", Vector3(-13.0, 0.08, -12.0), Vector3(0, 0, 1), Vector2(12.5, 10.5), Vector3(12.5, 5.0, 10.5), ["shop", "store", "building"], 23)
	_spawn_building("SafehouseMixedUse", Vector3(30.0, 0.08, -13.5), Vector3(0, 0, 1), Vector2(18.0, 13.0), Vector3(18.0, 7.0, 13.0), ["apartment", "store", "building", "example"], 211)
	_spawn_building("NorthApartments", Vector3(50.0, 0.08, -14.0), Vector3(0, 0, 1), Vector2(17.0, 14.0), Vector3(17.0, 8.0, 14.0), ["apartment", "residential", "building"], 47)

	_spawn_building("CornerDiner", Vector3(-46.5, 0.08, 12.5), Vector3(0, 0, -1), Vector2(15.0, 11.0), Vector3(15.0, 5.0, 11.0), ["store", "shop", "building"], 62)
	_spawn_building("SouthApartments", Vector3(-29.0, 0.08, 14.0), Vector3(0, 0, -1), Vector2(15.0, 14.0), Vector3(15.0, 7.5, 14.0), ["apartment", "residential", "building"], 73)
	_spawn_building("WorkshopExterior", Vector3(31.0, 0.08, 14.5), Vector3(0, 0, -1), Vector2(21.0, 15.0), Vector3(21.0, 6.5, 15.0), ["industrial", "warehouse", "building", "example"], 301)
	_spawn_building("EastWarehouse", Vector3(52.0, 0.08, 16.0), Vector3(0, 0, -1), Vector2(17.0, 17.0), Vector3(17.0, 6.0, 17.0), ["warehouse", "industrial", "building"], 88)

	# Two side-street facades prevent the scene from reading as one horizontal row.
	_spawn_building("SideStreetShop", Vector3(23.5, 0.08, -27.0), Vector3(-1, 0, 0), Vector2(13.0, 11.0), Vector3(13.0, 5.0, 11.0), ["store", "shop", "building"], 36)
	_spawn_building("SideStreetGarage", Vector3(2.5, 0.08, 26.0), Vector3(1, 0, 0), Vector2(15.0, 13.0), Vector3(15.0, 5.5, 13.0), ["garage", "industrial", "building"], 94)

func _build_alley_courtyard() -> void:
	# A five-meter alley deliberately punches through the south frontage and opens
	# into a fightable rear court. This is gameplay space first, realism second.
	_add_surface("FightAlley", Vector3(-14.0, 0.038, 18.5), Vector3(5.2, 0.03, 25.0), _materials["alley"])
	_add_surface("RearFightCourt", Vector3(-16.5, 0.039, 31.0), Vector3(20.0, 0.032, 14.0), _materials["alley"])

	_add_static_box("CourtWallWest", Vector3(0.28, 3.0, 14.0), Vector3(-26.4, 1.5, 31.0), _materials["wall"])
	_add_static_box("CourtWallSouth", Vector3(20.0, 3.0, 0.28), Vector3(-16.5, 1.5, 38.0), _materials["wall"])
	_add_static_box("CourtWallEastRear", Vector3(0.28, 3.0, 8.0), Vector3(-6.6, 1.5, 34.0), _materials["wall"])

	# Industrial service pocket creates a second kind of combat space on the east.
	_add_surface("WorkshopServiceYard", Vector3(39.0, 0.04, 29.0), Vector3(27.0, 0.035, 11.0), _materials["alley"])
	_add_static_box("YardRearWall", Vector3(27.0, 2.5, 0.25), Vector3(39.0, 1.25, 34.5), _materials["wall"])

func _build_minimal_dressing() -> void:
	# Only anchor props that explain a space. No scatter pass.
	_spawn_prop("AlleyDumpsterA", Vector3(-23.5, 0.08, 30.0), ["dumpster", "trash", "bin"], 2, 1.4, 1.8, 90.0)
	_spawn_prop("AlleyDumpsterB", Vector3(-8.2, 0.08, 35.0), ["dumpster", "trash", "bin"], 5, 1.4, 1.8, 0.0)
	_spawn_prop("MarketBench", Vector3(-4.0, 0.08, -5.5), ["bench"], 1, 1.0, 2.2, 0.0)
	_spawn_prop("CornerHydrant", Vector3(7.8, 0.08, 5.6), ["hydrant"], 0, 0.9, 1.0, 0.0)
	_spawn_prop("YardPallet", Vector3(48.0, 0.08, 29.5), ["pallet", "crate"], 3, 1.0, 1.8, 0.0)
	_spawn_prop("YardBarrier", Vector3(29.0, 0.08, 28.5), ["barrier", "bollard"], 1, 1.0, 2.0, 90.0)

func _place_gameplay() -> void:
	_set_node_position("PrecinctEntrance", Vector3(-39.0, 0.08, -5.2))
	_set_return_position("PrecinctEntrance", Vector3(-39.0, 0.95, -6.6))
	_set_node_position("SafehouseEntrance", Vector3(27.0, 0.08, -5.2))
	_set_return_position("SafehouseEntrance", Vector3(27.0, 0.95, -6.6))
	_set_node_position("WorkshopEntrance", Vector3(31.0, 0.08, 5.2))
	_set_return_position("WorkshopEntrance", Vector3(31.0, 0.95, 6.6))

	_set_node_position("DrugBuyer", Vector3(-18.5, 0.08, 31.0))
	_set_node_position("GunrunnerBuyer", Vector3(47.0, 0.08, -5.2))
	_set_node_position("InterdictionCache", Vector3(46.0, 0.08, 29.0))
	_set_node_position("FFAEntrance", Vector3(-16.5, 0.08, 34.0))

	_set_node_position("KnifeVendor", Vector3(-7.0, 0.08, -5.4))
	_set_node_position("BatVendor", Vector3(-2.8, 0.08, -5.4))
	_set_node_position("PistolVendor", Vector3(1.4, 0.08, -5.4))

	_set_node_position("BeatCopA", Vector3(-33.0, 0.95, -3.1))
	_set_node_position("BeatCopB", Vector3(-48.0, 0.95, 3.1))
	_set_node_position("ContrabandGuardA", Vector3(25.0, 0.95, -3.0))
	_set_node_position("ContrabandGuardB", Vector3(43.0, 0.95, -3.0))
	_set_node_position("ArmsGuardA", Vector3(30.0, 0.95, 8.5))
	_set_node_position("ArmsGuardB", Vector3(46.0, 0.95, 27.0))

	if _player != null:
		_player.global_position = Vector3(-20.0, 0.95, 2.2)

func _spawn_building(node_name: String, position_value: Vector3, frontage: Vector3, footprint: Vector2, fallback_size: Vector3, tokens: Array[String], variant: int) -> void:
	var building := QuaterniusCityBuilding3D.new()
	building.name = node_name
	building.position = position_value
	building.rotation.y = atan2(frontage.x, frontage.z)
	building.max_footprint = footprint
	building.target_size = fallback_size
	building.preferred_tokens = tokens
	building.variant_index = variant
	building.allow_upscale = false
	add_child(building)

func _spawn_prop(node_name: String, position_value: Vector3, tokens: Array[String], variant: int, target_height: float, target_width: float, yaw: float) -> void:
	var prop := QuaterniusCityProp3D.new()
	prop.name = node_name
	prop.position = position_value
	prop.search_tokens = tokens
	prop.variant_index = variant
	prop.target_height = target_height
	prop.target_width = target_width
	prop.yaw_degrees = yaw
	add_child(prop)

func _add_walk_segment(node_name: String, center: Vector3, size: Vector3) -> void:
	_add_surface(node_name, center, size, _materials["walk"])

func _add_curb(node_name: String, center: Vector3, size: Vector3) -> void:
	_add_static_box(node_name, size, center, _materials["curb"])

func _add_surface(node_name: String, center: Vector3, size: Vector3, material: Material) -> void:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	mesh_instance.position = center
	mesh_instance.material_override = material
	add_child(mesh_instance)

func _add_static_box(node_name: String, size: Vector3, center: Vector3, material: Material) -> void:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = center
	add_child(body)
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	mesh_instance.material_override = material
	body.add_child(mesh_instance)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)

func _material(color: Color, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	return material

func _set_node_position(node_name: String, position_value: Vector3) -> void:
	var node := get_node_or_null(NodePath(node_name)) as Node3D
	if node != null:
		node.global_position = position_value

func _set_return_position(node_name: String, position_value: Vector3) -> void:
	var node := get_node_or_null(NodePath(node_name))
	if node != null:
		node.set("city_return_position", position_value)

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
	var p: Vector3 = _player.global_position
	# Neutral around the central crossing and market. West reads Police; northeast
	# reads Contraband; southeast/service yard reads Arms.
	if absf(p.x - CROSS_X) < 11.0 and absf(p.z) < 10.0:
		GameSession.set_territory(GameSession.Territory.NEUTRAL)
	elif p.x < -8.0:
		GameSession.set_territory(GameSession.Territory.POLICE)
	elif p.z < 7.0:
		GameSession.set_territory(GameSession.Territory.CONTRABAND)
	else:
		GameSession.set_territory(GameSession.Territory.ARMS)
