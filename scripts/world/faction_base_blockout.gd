class_name FactionBaseBlockout3D
extends Node3D

@export var base_title: String = "FACTION BASE"
@export var base_color: Color = Color(0.20, 0.22, 0.25, 1.0)
@export var territory_id: int = 0

func _ready() -> void:
	GameSession.set_territory(territory_id)
	_add_static_box("Floor", Vector3(18.0, 0.2, 14.0), Vector3(0.0, -0.1, 0.0), Color(0.10, 0.105, 0.11, 1.0))
	_add_static_box("NorthWall", Vector3(18.0, 2.8, 0.35), Vector3(0.0, 1.4, -7.0), base_color)
	_add_static_box("SouthWall", Vector3(18.0, 2.8, 0.35), Vector3(0.0, 1.4, 7.0), base_color)
	_add_static_box("WestWall", Vector3(0.35, 2.8, 14.0), Vector3(-9.0, 1.4, 0.0), base_color)
	_add_static_box("EastWall", Vector3(0.35, 2.8, 14.0), Vector3(9.0, 1.4, 0.0), base_color)
	_add_label(base_title, Vector3(0.0, 2.4, -5.8), Color(0.94, 0.94, 0.92, 1.0))

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
	label.font_size = 36
	label.outline_size = 10
	label.pixel_size = 0.008
	label.modulate = color
	add_child(label)
