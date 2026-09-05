extends Node3D

func _ready() -> void:
	GameSession.set_territory(GameSession.Territory.POLICE)
	_build_ground()
	_build_blocks()
	_build_dealer_corner()

func _build_ground() -> void:
	_add_static_box("StreetFloor", Vector3(34.0, 0.2, 22.0), Vector3(0.0, -0.1, 0.0), Color(0.10, 0.105, 0.11, 1.0))
	_add_static_box("WestSidewalk", Vector3(7.0, 0.28, 22.0), Vector3(-13.5, 0.04, 0.0), Color(0.25, 0.255, 0.26, 1.0))
	_add_static_box("EastSidewalk", Vector3(7.0, 0.28, 22.0), Vector3(13.5, 0.04, 0.0), Color(0.25, 0.255, 0.26, 1.0))

	for z_value: float in [-8.0, -3.0, 2.0, 7.0]:
		var stripe: MeshInstance3D = MeshInstance3D.new()
		var mesh: BoxMesh = BoxMesh.new()
		mesh.size = Vector3(0.22, 0.025, 2.3)
		stripe.mesh = mesh
		stripe.position = Vector3(0.0, 0.03, z_value)
		var material: StandardMaterial3D = StandardMaterial3D.new()
		material.albedo_color = Color(0.78, 0.70, 0.35, 1.0)
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		stripe.material_override = material
		add_child(stripe)

func _build_blocks() -> void:
	_add_static_box("WestBuildingA", Vector3(5.8, 4.5, 8.0), Vector3(-14.2, 2.25, -6.2), Color(0.20, 0.17, 0.16, 1.0))
	_add_static_box("WestBuildingB", Vector3(5.8, 5.8, 8.0), Vector3(-14.2, 2.9, 5.7), Color(0.16, 0.18, 0.20, 1.0))
	_add_static_box("EastBuildingA", Vector3(5.8, 5.0, 8.5), Vector3(14.2, 2.5, -5.8), Color(0.18, 0.19, 0.16, 1.0))
	_add_static_box("EastBuildingB", Vector3(5.8, 4.3, 8.0), Vector3(14.2, 2.15, 6.0), Color(0.19, 0.15, 0.18, 1.0))

	_add_static_box("Dumpster", Vector3(2.0, 1.1, 1.2), Vector3(-10.3, 0.55, 4.2), Color(0.12, 0.24, 0.20, 1.0))
	_add_static_box("ConcreteBarrier", Vector3(2.6, 0.7, 0.55), Vector3(5.2, 0.35, -2.0), Color(0.45, 0.45, 0.43, 1.0))

func _build_dealer_corner() -> void:
	var dealer_root: Node3D = Node3D.new()
	dealer_root.name = "DealerSilhouette"
	dealer_root.position = Vector3(10.6, 0.0, 2.2)
	add_child(dealer_root)

	_add_visual_box(dealer_root, Vector3(0.75, 1.15, 0.45), Vector3(0.0, 1.15, 0.0), Color(0.12, 0.12, 0.14, 1.0))
	_add_visual_sphere(dealer_root, 0.28, Vector3(0.0, 1.95, 0.0), Color(0.20, 0.15, 0.12, 1.0))
	_add_label("STREET ARMS DEALER\nPOLICE TERRITORY", Vector3(10.6, 2.75, 2.2), Color(1.0, 0.70, 0.30, 1.0))
	_add_label("FFA ENTRANCE\nWEST SIDE", Vector3(-10.5, 2.1, -5.0), Color(0.56, 0.78, 1.0, 1.0))

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

func _add_visual_box(parent: Node3D, size: Vector3, position_value: Vector3, color: Color) -> void:
	var mesh_instance: MeshInstance3D = MeshInstance3D.new()
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	mesh_instance.position = position_value
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.88
	mesh_instance.material_override = material
	parent.add_child(mesh_instance)

func _add_visual_sphere(parent: Node3D, radius: float, position_value: Vector3, color: Color) -> void:
	var mesh_instance: MeshInstance3D = MeshInstance3D.new()
	var mesh: SphereMesh = SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh_instance.mesh = mesh
	mesh_instance.position = position_value
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color
	mesh_instance.material_override = material
	parent.add_child(mesh_instance)

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
