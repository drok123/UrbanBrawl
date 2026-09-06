class_name CityWorld3D
extends Node3D

@export var player_path: NodePath = NodePath("Player")

var _player: Node3D = null

func _ready() -> void:
	_player = get_node_or_null(player_path) as Node3D
	QuaterniusAssetLocator.print_install_summary()
	_build_city()
	_restore_city_spawn()
	_update_territory()

func _process(_delta: float) -> void:
	_update_territory()

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
	var territory: int = GameSession.Territory.NEUTRAL
	# Central Avenue + its pedestrian frontage form neutral commons. Faction
	# territory begins beyond the first row of lots rather than at the curb.
	if position_value.x < -12.0:
		territory = GameSession.Territory.POLICE
	elif position_value.x > 12.0 and position_value.z < 0.0:
		territory = GameSession.Territory.CONTRABAND
	elif position_value.x > 12.0 and position_value.z >= 0.0:
		territory = GameSession.Territory.ARMS
	GameSession.set_territory(territory)

func _build_city() -> void:
	# Flat foundation remains intentionally boring. Road Generator, authored lots
	# and the Downtown MegaKit now provide the visible city structure.
	_add_static_box(self, "CityGround", Vector3(112.0, 0.2, 84.0), Vector3(0.0, -0.14, 0.0), Color(0.105, 0.108, 0.11, 1.0))

	var road_network: CityRoadNetwork3D = CityRoadNetwork3D.new()
	road_network.name = "StreetNetwork"
	add_child(road_network)

	_build_police_blocks()
	_build_contraband_blocks()
	_build_arms_blocks()
	_build_center_blocks()
	_build_street_dressing()

	# District identity is environmental first; labels are small wayfinding aids,
	# not giant floating prototype signage.
	_add_label("PRECINCT DISTRICT", Vector3(-42.0, 2.5, -34.0), Color(0.56, 0.72, 1.0, 0.92))
	_add_label("NORTHSIDE", Vector3(42.0, 2.5, -34.0), Color(0.62, 0.92, 0.68, 0.92))
	_add_label("FOUNDRY", Vector3(42.0, 2.5, 34.0), Color(1.0, 0.66, 0.42, 0.92))

func _build_police_blocks() -> void:
	# West side: larger civic/commercial footprints around the precinct, then
	# smaller mixed blocks toward Central Avenue.
	_add_lot_pad("PrecinctLot", Vector3(-41.0, 0.0, -9.5), Vector2(16.5, 16.0))
	_add_external_building("PrecinctExterior", Vector3(13.0, 7.0, 11.0), Vector3(-41.0, 3.5, -9.5), Color(0.15, 0.18, 0.22, 1.0), 0, ["office", "building"], 90.0)

	_add_external_building("PoliceNW", Vector3(13.0, 6.4, 12.0), Vector3(-41.0, 3.2, -29.5), Color(0.18, 0.20, 0.24, 1.0), 1, [], 0.0)
	_add_external_building("PoliceNorthInner", Vector3(12.0, 5.6, 12.0), Vector3(-17.5, 2.8, -29.0), Color(0.17, 0.19, 0.22, 1.0), 2, [], 180.0)
	_add_external_building("PoliceMidInner", Vector3(11.0, 5.2, 10.0), Vector3(-17.0, 2.6, -10.5), Color(0.18, 0.19, 0.21, 1.0), 3, ["store", "shop", "building"], 90.0)
	_add_external_building("PoliceSW", Vector3(13.0, 5.5, 11.0), Vector3(-41.0, 2.75, 10.0), Color(0.19, 0.20, 0.22, 1.0), 4, [], 90.0)
	_add_external_building("PoliceSouthInner", Vector3(11.0, 5.8, 11.0), Vector3(-17.0, 2.9, 10.5), Color(0.18, 0.19, 0.21, 1.0), 5, [], -90.0)
	_add_external_building("PoliceFarSouth", Vector3(13.0, 6.2, 12.0), Vector3(-40.0, 3.1, 30.0), Color(0.17, 0.18, 0.20, 1.0), 6, [], 180.0)
	_add_external_building("PoliceSouthMarket", Vector3(11.0, 4.8, 11.0), Vector3(-16.5, 2.4, 30.0), Color(0.20, 0.20, 0.20, 1.0), 7, ["store", "shop", "building"], 0.0)

func _build_contraband_blocks() -> void:
	# North-east is denser and more mixed-use. The safehouse is embedded behind
	# storefront massing rather than standing alone as a faction-colored box.
	_add_external_building("ContraNorthInner", Vector3(11.5, 5.0, 11.0), Vector3(17.5, 2.5, -30.0), Color(0.17, 0.18, 0.17, 1.0), 8, [], 180.0)
	_add_external_building("ContraNorthOuter", Vector3(14.0, 6.0, 12.0), Vector3(40.0, 3.0, -30.0), Color(0.15, 0.17, 0.16, 1.0), 9, [], 0.0)
	_add_external_building("ContraMarket", Vector3(11.0, 4.6, 10.0), Vector3(17.0, 2.3, -10.5), Color(0.17, 0.18, 0.17, 1.0), 10, ["store", "shop", "building"], -90.0)
	_add_lot_pad("SafehouseLot", Vector3(40.0, 0.0, -10.0), Vector2(16.0, 15.0))
	_add_external_building("SafehouseExterior", Vector3(10.0, 5.2, 9.0), Vector3(40.0, 2.6, -10.0), Color(0.16, 0.18, 0.16, 1.0), 11, ["store", "shop", "building"], -90.0)

func _build_arms_blocks() -> void:
	# South-east mirrors the street density without mirroring the exact building
	# arrangement. Taller/industrial-ish footprints sit toward the outer edge.
	_add_external_building("ArmsMidInner", Vector3(11.0, 4.8, 10.0), Vector3(17.0, 2.4, 10.5), Color(0.20, 0.18, 0.17, 1.0), 12, ["store", "shop", "building"], 90.0)
	_add_external_building("ArmsMidOuter", Vector3(14.0, 6.4, 12.0), Vector3(40.0, 3.2, 10.0), Color(0.18, 0.16, 0.15, 1.0), 13, [], 180.0)
	_add_external_building("ArmsSouthInner", Vector3(11.5, 5.5, 11.0), Vector3(17.5, 2.75, 30.0), Color(0.19, 0.17, 0.15, 1.0), 14, [], 0.0)
	_add_lot_pad("WorkshopLot", Vector3(40.0, 0.0, 30.0), Vector2(16.0, 15.0))
	_add_external_building("WorkshopExterior", Vector3(11.0, 5.5, 10.0), Vector3(40.0, 2.75, 30.0), Color(0.20, 0.17, 0.15, 1.0), 15, ["store", "shop", "building"], -90.0)

func _build_center_blocks() -> void:
	# Central Commons is deliberately low and open so the player can read the
	# public market and FFA entrance from the main avenue.
	_add_external_building("CommonsNorthShop", Vector3(5.0, 3.2, 5.0), Vector3(9.0, 1.6, -11.5), Color(0.24, 0.24, 0.23, 1.0), 16, ["store", "shop", "building"], -90.0)
	_add_external_building("CommonsSouthShop", Vector3(5.0, 3.2, 5.0), Vector3(9.0, 1.6, 12.5), Color(0.24, 0.24, 0.23, 1.0), 17, ["store", "shop", "building"], -90.0)

func _build_street_dressing() -> void:
	# Props hug actual road frontages now. Missing categories self-delete.
	var lamp_positions: Array[Vector3] = [
		Vector3(-8.0, 0.0, -31.0), Vector3(-8.0, 0.0, -13.0), Vector3(-8.0, 0.0, 11.0), Vector3(-8.0, 0.0, 30.0),
		Vector3(8.0, 0.0, -31.0), Vector3(8.0, 0.0, -13.0), Vector3(8.0, 0.0, 11.0), Vector3(8.0, 0.0, 30.0),
		Vector3(-31.0, 0.0, -17.0), Vector3(-31.0, 0.0, 16.5), Vector3(31.0, 0.0, -16.5), Vector3(31.0, 0.0, 16.5),
	]
	for index: int in range(lamp_positions.size()):
		_add_prop("StreetLamp%d" % index, lamp_positions[index], ["streetlight", "street_light", "lamp", "light"], index, 3.2, 1.0)

	var bench_positions: Array[Vector3] = [Vector3(-10.0, 0, -13.5), Vector3(-10.0, 0, 10.0), Vector3(10.0, 0, -13.5), Vector3(10.0, 0, 10.0)]
	for index: int in range(bench_positions.size()):
		_add_prop("Bench%d" % index, bench_positions[index], ["bench", "seat"], index, 0.95, 2.1, 90.0 if index % 2 == 0 else -90.0)

	var trash_positions: Array[Vector3] = [Vector3(-32.0, 0, -4.8), Vector3(-32.0, 0, 14.5), Vector3(32.0, 0, -15.0), Vector3(32.0, 0, 14.0)]
	for index: int in range(trash_positions.size()):
		_add_prop("Trash%d" % index, trash_positions[index], ["trash", "garbage", "dumpster", "bin"], index, 1.15, 1.8)

	var sign_positions: Array[Vector3] = [Vector3(-8.0, 0, -4.8), Vector3(8.0, 0, -4.8), Vector3(-8.0, 0, 5.0), Vector3(8.0, 0, 5.0)]
	for index: int in range(sign_positions.size()):
		_add_prop("StreetSign%d" % index, sign_positions[index], ["sign", "traffic"], index, 2.4, 1.0)

	_add_prop("HydrantPolice", Vector3(-31.0, 0, -14.0), ["hydrant"], 0, 0.8, 0.7)
	_add_prop("HydrantEast", Vector3(31.0, 0, 7.0), ["hydrant"], 1, 0.8, 0.7)
	_add_prop("BarrierA", Vector3(-9.0, 0, 3.8), ["barrier", "bollard"], 0, 1.0, 2.4, 90.0)
	_add_prop("BarrierB", Vector3(9.0, 0, -3.8), ["barrier", "bollard"], 1, 1.0, 2.4, -90.0)

func _add_lot_pad(node_name: String, position_value: Vector3, size: Vector2) -> void:
	var pad: MeshInstance3D = MeshInstance3D.new()
	pad.name = node_name
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = Vector3(size.x, 0.10, size.y)
	pad.mesh = mesh
	pad.position = position_value + Vector3(0.0, 0.015, 0.0)
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = Color(0.235, 0.235, 0.225, 1.0)
	material.roughness = 0.98
	pad.material_override = material
	add_child(pad)

func _add_external_building(node_name: String, size: Vector3, position_value: Vector3, color: Color, variant: int, preferred: Array[String] = [], yaw_degrees: float = 0.0) -> void:
	var building: QuaterniusCityBuilding3D = QuaterniusCityBuilding3D.new()
	building.name = node_name
	building.target_size = size
	building.fallback_color = color
	building.variant_index = variant
	building.preferred_tokens = preferred
	building.position = position_value
	building.rotation_degrees.y = yaw_degrees
	add_child(building)

func _add_prop(node_name: String, position_value: Vector3, tokens: Array[String], variant: int, height: float, width: float = 0.0, yaw: float = 0.0) -> void:
	var prop: QuaterniusCityProp3D = QuaterniusCityProp3D.new()
	prop.name = node_name
	prop.position = position_value
	prop.search_tokens = tokens
	prop.variant_index = variant
	prop.target_height = height
	prop.target_width = width
	prop.yaw_degrees = yaw
	add_child(prop)

func _add_static_box(parent: Node3D, node_name: String, size: Vector3, position_value: Vector3, color: Color) -> void:
	var body: StaticBody3D = StaticBody3D.new()
	body.name = node_name
	body.position = position_value
	parent.add_child(body)
	var mesh_instance: MeshInstance3D = MeshInstance3D.new()
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.96
	mesh_instance.material_override = material
	body.add_child(mesh_instance)
	var collision: CollisionShape3D = CollisionShape3D.new()
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)

func _add_label(value: String, position_value: Vector3, color: Color) -> void:
	var label: Label3D = Label3D.new()
	label.text = value
	label.position = position_value
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 24
	label.outline_size = 7
	label.pixel_size = 0.007
	label.modulate = color
	add_child(label)
