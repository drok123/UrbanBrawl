class_name CityWorld3D
extends Node3D

@export var player_path: NodePath = NodePath("Player")

var _player: Node3D = null

func _ready() -> void:
	_player = get_node_or_null(player_path) as Node3D
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
	_add_static_box(self, "CityGround", Vector3(96.0, 0.2, 72.0), Vector3(0.0, -0.1, 0.0), Color(0.095, 0.10, 0.11, 1.0))
	_add_visual_box("PoliceDistrict", Vector3(-28.0, 0.02, 0.0), Vector3(38.0, 0.05, 66.0), Color(0.10, 0.15, 0.24, 1.0))
	_add_visual_box("ContrabandDistrict", Vector3(26.0, 0.02, -18.0), Vector3(34.0, 0.05, 30.0), Color(0.09, 0.20, 0.12, 1.0))
	_add_visual_box("ArmsDistrict", Vector3(26.0, 0.02, 18.0), Vector3(34.0, 0.05, 30.0), Color(0.24, 0.12, 0.07, 1.0))
	_add_visual_box("CentralCommons", Vector3(0.0, 0.025, 0.0), Vector3(15.0, 0.06, 66.0), Color(0.18, 0.18, 0.19, 1.0))

	_add_visual_box("WestRoad", Vector3(-7.0, 0.055, 0.0), Vector3(7.0, 0.03, 66.0), Color(0.055, 0.058, 0.062, 1.0))
	_add_visual_box("EastRoad", Vector3(7.0, 0.055, 0.0), Vector3(7.0, 0.03, 66.0), Color(0.055, 0.058, 0.062, 1.0))
	_add_visual_box("CrossRoad", Vector3(4.0, 0.06, 0.0), Vector3(84.0, 0.03, 7.0), Color(0.055, 0.058, 0.062, 1.0))

	_build_police_blocks()
	_build_contraband_blocks()
	_build_arms_blocks()
	_build_center_blocks()
	_add_label("POLICE DISTRICT", Vector3(-28.0, 3.0, -28.0), Color(0.40, 0.65, 1.0, 1.0))
	_add_label("CONTRABAND DISTRICT", Vector3(27.0, 3.0, -30.0), Color(0.40, 1.0, 0.52, 1.0))
	_add_label("ARMS DISTRICT", Vector3(27.0, 3.0, 30.0), Color(1.0, 0.50, 0.25, 1.0))
	_add_label("CENTRAL COMMONS", Vector3(0.0, 2.7, -24.0), Color(0.90, 0.90, 0.88, 1.0))

func _build_police_blocks() -> void:
	_add_static_box(self, "PrecinctExterior", Vector3(12.0, 6.0, 10.0), Vector3(-39.0, 3.0, -8.0), Color(0.12, 0.19, 0.34, 1.0))
	_add_static_box(self, "PoliceBlockA", Vector3(11.0, 5.0, 13.0), Vector3(-34.0, 2.5, -20.0), Color(0.18, 0.20, 0.24, 1.0))
	_add_static_box(self, "PoliceBlockB", Vector3(10.0, 6.5, 12.0), Vector3(-20.0, 3.25, -9.0), Color(0.16, 0.18, 0.22, 1.0))
	_add_static_box(self, "PoliceBlockC", Vector3(12.0, 4.5, 14.0), Vector3(-31.0, 2.25, 18.0), Color(0.20, 0.21, 0.23, 1.0))

func _build_contraband_blocks() -> void:
	_add_static_box(self, "SafehouseExterior", Vector3(9.0, 5.0, 7.0), Vector3(31.0, 2.5, -31.0), Color(0.10, 0.26, 0.13, 1.0))
	_add_static_box(self, "ContrabandBlockA", Vector3(10.0, 4.8, 10.0), Vector3(21.0, 2.4, -23.0), Color(0.14, 0.19, 0.15, 1.0))
	_add_static_box(self, "ContrabandBlockB", Vector3(9.0, 6.0, 9.0), Vector3(36.0, 3.0, -14.0), Color(0.12, 0.17, 0.14, 1.0))

func _build_arms_blocks() -> void:
	_add_static_box(self, "WorkshopExterior", Vector3(9.0, 5.0, 7.0), Vector3(31.0, 2.5, 31.0), Color(0.32, 0.14, 0.07, 1.0))
	_add_static_box(self, "ArmsBlockA", Vector3(11.0, 5.0, 10.0), Vector3(22.0, 2.5, 22.0), Color(0.22, 0.16, 0.12, 1.0))
	_add_static_box(self, "ArmsBlockB", Vector3(9.0, 6.5, 9.0), Vector3(36.0, 3.25, 13.0), Color(0.19, 0.13, 0.10, 1.0))

func _build_center_blocks() -> void:
	_add_static_box(self, "CommonsKioskA", Vector3(4.0, 2.4, 4.0), Vector3(-1.0, 1.2, -11.0), Color(0.25, 0.24, 0.23, 1.0))
	_add_static_box(self, "CommonsKioskB", Vector3(4.0, 2.4, 4.0), Vector3(1.0, 1.2, 11.0), Color(0.25, 0.24, 0.23, 1.0))

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
	label.font_size = 34
	label.outline_size = 10
	label.pixel_size = 0.009
	label.modulate = color
	add_child(label)
