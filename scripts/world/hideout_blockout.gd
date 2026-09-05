extends Node3D

func _ready() -> void:
	GameSession.set_territory(GameSession.Territory.NEUTRAL)
	_build_shell()
	_build_hideout_props()

func _build_shell() -> void:
	_add_static_box("Floor", Vector3(18.0, 0.2, 14.0), Vector3(0.0, -0.1, 0.0), Color(0.12, 0.13, 0.14, 1.0))
	_add_static_box("NorthWall", Vector3(18.0, 2.6, 0.35), Vector3(0.0, 1.3, -7.0), Color(0.22, 0.23, 0.24, 1.0))
	_add_static_box("SouthWall", Vector3(18.0, 2.6, 0.35), Vector3(0.0, 1.3, 7.0), Color(0.22, 0.23, 0.24, 1.0))
	_add_static_box("WestWall", Vector3(0.35, 2.6, 14.0), Vector3(-9.0, 1.3, 0.0), Color(0.22, 0.23, 0.24, 1.0))
	_add_static_box("EastWall", Vector3(0.35, 2.6, 14.0), Vector3(9.0, 1.3, 0.0), Color(0.22, 0.23, 0.24, 1.0))

func _build_hideout_props() -> void:
	_add_static_box("PlanningTable", Vector3(3.4, 0.75, 1.8), Vector3(0.0, 0.38, 0.5), Color(0.24, 0.19, 0.14, 1.0))
	_add_label("PLANNING TABLE\nHEISTS / RAIDS WILL LAUNCH HERE", Vector3(0.0, 1.75, 0.5), Color(0.92, 0.82, 0.58, 1.0))

	_add_static_box("GrowBenchA", Vector3(3.0, 0.65, 1.0), Vector3(5.0, 0.33, -2.1), Color(0.13, 0.24, 0.14, 1.0))
	_add_static_box("GrowBenchB", Vector3(3.0, 0.65, 1.0), Vector3(5.0, 0.33, -0.6), Color(0.13, 0.24, 0.14, 1.0))
	_add_label("GROW ROOM\nCONTRABAND PRODUCTION", Vector3(5.0, 1.55, -1.35), Color(0.48, 1.0, 0.55, 1.0))

	_add_static_box("CashCrate", Vector3(1.4, 0.9, 1.2), Vector3(-5.5, 0.45, -3.6), Color(0.18, 0.22, 0.17, 1.0))
	_add_label("CASH / CONTRABAND STORAGE", Vector3(-5.5, 1.55, -3.6), Color(0.63, 0.88, 0.60, 1.0))

	_add_static_box("GangCouch", Vector3(3.6, 0.8, 1.1), Vector3(4.6, 0.4, 4.7), Color(0.24, 0.13, 0.15, 1.0))
	_add_label("FACTION TEST AREA", Vector3(4.6, 1.55, 4.7), Color(0.95, 0.52, 0.58, 1.0))

func _add_static_box(node_name: String, size: Vector3, position_value: Vector3, color: Color) -> void:
	var body: StaticBody3D = StaticBody3D.new()
	body.name = node_name
	body.position = position_value
	add_child(body)

	var mesh_instance: MeshInstance3D = MeshInstance3D.new()
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.9
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
	label.font_size = 32
	label.outline_size = 9
	label.pixel_size = 0.008
	label.modulate = color
	add_child(label)
