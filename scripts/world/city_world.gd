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
	if position_value.x < -8.0:
		territory = GameSession.Territory.POLICE
	elif position_value.x > 8.0 and position_value.z < 0.0:
		territory = GameSession.Territory.CONTRABAND
	elif position_value.x > 8.0 and position_value.z >= 0.0:
		territory = GameSession.Territory.ARMS
	GameSession.set_territory(territory)

func _build_city() -> void:
	# Gameplay collision/territory remains simple. Presentation now comes from the
	# installed Downtown City MegaKit instead of faction-colored block slabs.
	_add_static_box(self, "CityGround", Vector3(96.0, 0.2, 72.0), Vector3(0.0, -0.1, 0.0), Color(0.12, 0.12, 0.125, 1.0))
	_add_visual_box("WestRoad", Vector3(-7.0, 0.015, 0.0), Vector3(7.0, 0.03, 66.0), Color(0.045, 0.047, 0.05, 1.0))
	_add_visual_box("EastRoad", Vector3(7.0, 0.015, 0.0), Vector3(7.0, 0.03, 66.0), Color(0.045, 0.047, 0.05, 1.0))
	_add_visual_box("CrossRoad", Vector3(4.0, 0.02, 0.0), Vector3(84.0, 0.03, 7.0), Color(0.045, 0.047, 0.05, 1.0))
	_add_visual_box("WestSidewalk", Vector3(-13.5, 0.03, 0.0), Vector3(6.0, 0.08, 66.0), Color(0.27, 0.27, 0.275, 1.0))
	_add_visual_box("EastSidewalk", Vector3(13.5, 0.03, 0.0), Vector3(6.0, 0.08, 66.0), Color(0.27, 0.27, 0.275, 1.0))

	_build_police_blocks()
	_build_contraband_blocks()
	_build_arms_blocks()
	_build_center_blocks()
	_build_street_dressing()

	_add_label("POLICE DISTRICT", Vector3(-28.0, 3.0, -28.0), Color(0.40, 0.65, 1.0, 1.0))
	_add_label("CONTRABAND DISTRICT", Vector3(27.0, 3.0, -30.0), Color(0.40, 1.0, 0.52, 1.0))
	_add_label("ARMS DISTRICT", Vector3(27.0, 3.0, 30.0), Color(1.0, 0.50, 0.25, 1.0))
	_add_label("CENTRAL COMMONS", Vector3(0.0, 2.7, -24.0), Color(0.90, 0.90, 0.88, 1.0))

func _build_police_blocks() -> void:
	_add_external_building("PrecinctExterior", Vector3(12.0, 6.0, 10.0), Vector3(-39.0, 3.0, -8.0), Color(0.15, 0.18, 0.22, 1.0), 0, ["office", "building"])
	_add_external_building("PoliceBlockA", Vector3(11.0, 5.0, 13.0), Vector3(-34.0, 2.5, -20.0), Color(0.18, 0.20, 0.24, 1.0), 1)
	_add_external_building("PoliceBlockB", Vector3(10.0, 6.5, 12.0), Vector3(-20.0, 3.25, -9.0), Color(0.16, 0.18, 0.22, 1.0), 2)
	_add_external_building("PoliceBlockC", Vector3(12.0, 4.5, 14.0), Vector3(-31.0, 2.25, 18.0), Color(0.20, 0.21, 0.23, 1.0), 3)
	_add_external_building("PoliceBlockD", Vector3(10.0, 5.5, 10.0), Vector3(-19.0, 2.75, 21.0), Color(0.18, 0.19, 0.21, 1.0), 4)

func _build_contraband_blocks() -> void:
	_add_external_building("SafehouseExterior", Vector3(9.0, 5.0, 7.0), Vector3(31.0, 2.5, -31.0), Color(0.16, 0.18, 0.16, 1.0), 5, ["store", "shop", "building"])
	_add_external_building("ContrabandBlockA", Vector3(10.0, 4.8, 10.0), Vector3(21.0, 2.4, -23.0), Color(0.17, 0.18, 0.17, 1.0), 6)
	_add_external_building("ContrabandBlockB", Vector3(9.0, 6.0, 9.0), Vector3(36.0, 3.0, -14.0), Color(0.15, 0.16, 0.15, 1.0), 1)
	_add_external_building("ContrabandBlockC", Vector3(11.0, 5.2, 9.0), Vector3(20.5, 2.6, -9.0), Color(0.16, 0.17, 0.16, 1.0), 4)

func _build_arms_blocks() -> void:
	_add_external_building("WorkshopExterior", Vector3(9.0, 5.0, 7.0), Vector3(31.0, 2.5, 31.0), Color(0.20, 0.17, 0.15, 1.0), 2, ["store", "shop", "building"])
	_add_external_building("ArmsBlockA", Vector3(11.0, 5.0, 10.0), Vector3(22.0, 2.5, 22.0), Color(0.20, 0.18, 0.17, 1.0), 3)
	_add_external_building("ArmsBlockB", Vector3(9.0, 6.5, 9.0), Vector3(36.0, 3.25, 13.0), Color(0.18, 0.16, 0.15, 1.0), 5)
	_add_external_building("ArmsBlockC", Vector3(10.0, 5.0, 11.0), Vector3(20.0, 2.5, 9.5), Color(0.19, 0.17, 0.15, 1.0), 0)

func _build_center_blocks() -> void:
	_add_external_building("CommonsKioskA", Vector3(5.0, 3.4, 5.0), Vector3(-1.0, 1.7, -11.0), Color(0.24, 0.24, 0.23, 1.0), 2, ["store", "shop", "building"])
	_add_external_building("CommonsKioskB", Vector3(5.0, 3.4, 5.0), Vector3(1.0, 1.7, 11.0), Color(0.24, 0.24, 0.23, 1.0), 4, ["store", "shop", "building"])

func _build_street_dressing() -> void:
	# Missing categories simply self-delete, so this works across Standard pack revisions.
	var lamp_positions: Array[Vector3] = [
		Vector3(-11.0, 0.0, -26.0), Vector3(-11.0, 0.0, -13.0), Vector3(-11.0, 0.0, 9.0), Vector3(-11.0, 0.0, 25.0),
		Vector3(11.0, 0.0, -27.0), Vector3(11.0, 0.0, -13.0), Vector3(11.0, 0.0, 10.0), Vector3(11.0, 0.0, 26.0),
	]
	for index: int in range(lamp_positions.size()):
		_add_prop("StreetLamp%d" % index, lamp_positions[index], ["streetlight", "street_light", "lamp", "light"], index, 3.2, 1.0)

	var bench_positions: Array[Vector3] = [Vector3(-3.3, 0, -20), Vector3(3.3, 0, -18), Vector3(-3.2, 0, 18), Vector3(3.2, 0, 21)]
	for index: int in range(bench_positions.size()):
		_add_prop("Bench%d" % index, bench_positions[index], ["bench", "seat"], index, 0.95, 2.1, 90.0 if index % 2 == 0 else -90.0)

	var trash_positions: Array[Vector3] = [Vector3(-15.0, 0, -4.5), Vector3(-14.0, 0, 14.5), Vector3(16.0, 0, -20.0), Vector3(16.0, 0, 18.0)]
	for index: int in range(trash_positions.size()):
		_add_prop("Trash%d" % index, trash_positions[index], ["trash", "garbage", "dumpster", "bin"], index, 1.15, 1.8)

	var sign_positions: Array[Vector3] = [Vector3(-9.5, 0, -2.5), Vector3(9.5, 0, -2.5), Vector3(-9.5, 0, 3.5), Vector3(9.5, 0, 3.5)]
	for index: int in range(sign_positions.size()):
		_add_prop("StreetSign%d" % index, sign_positions[index], ["sign", "traffic"], index, 2.4, 1.0)

	_add_prop("HydrantPolice", Vector3(-14.0, 0, -15.0), ["hydrant"], 0, 0.8, 0.7)
	_add_prop("HydrantEast", Vector3(14.5, 0, 7.0), ["hydrant"], 1, 0.8, 0.7)
	_add_prop("BarrierA", Vector3(-3.6, 0, 3.2), ["barrier", "bollard"], 0, 1.0, 2.4, 90.0)
	_add_prop("BarrierB", Vector3(3.6, 0, -3.2), ["barrier", "bollard"], 1, 1.0, 2.4, -90.0)

func _add_external_building(node_name: String, size: Vector3, position_value: Vector3, color: Color, variant: int, preferred: Array[String] = []) -> void:
	var building: QuaterniusCityBuilding3D = QuaterniusCityBuilding3D.new()
	building.name = node_name
	building.target_size = size
	building.fallback_color = color
	building.variant_index = variant
	building.preferred_tokens = preferred
	building.position = position_value
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

func _add_visual_box(node_name: String, position_value: Vector3, size: Vector3, color: Color) -> void:
	var mesh_instance: MeshInstance3D = MeshInstance3D.new()
	mesh_instance.name = node_name
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	mesh_instance.position = position_value
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.95
	mesh_instance.material_override = material
	add_child(mesh_instance)

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
	material.roughness = 0.90
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
	label.font_size = 30
	label.outline_size = 9
	label.pixel_size = 0.008
	label.modulate = color
	add_child(label)
