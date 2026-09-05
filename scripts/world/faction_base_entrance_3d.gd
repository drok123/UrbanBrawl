class_name FactionBaseEntrance3D
extends Node3D

@export var faction_id: int = 0
@export_file("*.tscn") var target_scene: String
@export var title: String = "FACTION BASE"
@export var marker_color: Color = Color(0.30, 0.40, 0.55, 0.62)
@export var city_return_position: Vector3 = Vector3.ZERO

var _label: Label3D = null

func _ready() -> void:
	if GameSession.player_faction != faction_id:
		visible = false
		return
	add_to_group("world_interactable")
	_build_visuals()

func interact(actor: Node) -> void:
	if GameSession.player_faction != faction_id or target_scene.is_empty():
		return
	if actor != null:
		GameSession.capture_player(actor)
	GameSession.set_next_city_spawn(city_return_position)
	get_tree().change_scene_to_file(target_scene)

func get_interaction_prompt(_actor: Node) -> String:
	if GameSession.player_faction != faction_id:
		return ""
	return "%s\nF  ENTER" % title

func _build_visuals() -> void:
	var marker: MeshInstance3D = MeshInstance3D.new()
	var mesh: CylinderMesh = CylinderMesh.new()
	mesh.top_radius = 1.1
	mesh.bottom_radius = 1.1
	mesh.height = 0.08
	mesh.radial_segments = 40
	marker.mesh = mesh
	marker.position = Vector3(0.0, 0.04, 0.0)
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = marker_color
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	marker.material_override = material
	add_child(marker)

	_label = Label3D.new()
	_label.position = Vector3(0.0, 1.4, 0.0)
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.font_size = 36
	_label.outline_size = 10
	_label.pixel_size = 0.008
	_label.text = get_interaction_prompt(null)
	add_child(_label)
