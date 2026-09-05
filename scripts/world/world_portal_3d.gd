class_name WorldPortal3D
extends Node3D

@export_file("*.tscn") var target_scene: String
@export var title: String = "EXIT"
@export var subtitle: String = "F  ENTER"
@export var marker_color: Color = Color(0.18, 0.65, 1.0, 0.55)

var _label: Label3D = null

func _ready() -> void:
	add_to_group("world_interactable")
	_build_visuals()

func interact(actor: Node) -> void:
	if target_scene.is_empty():
		return
	if actor != null:
		GameSession.capture_player(actor)
	var resolved_target: String = target_scene
	if GameSession.ffa_active:
		GameSession.finish_ffa(false)
		resolved_target = "res://scenes/world/city_world.tscn"
	var error: Error = get_tree().change_scene_to_file(resolved_target)
	if error != OK:
		push_error("Failed to change scene to %s (error %d)" % [resolved_target, error])

func get_interaction_prompt(_actor: Node) -> String:
	if GameSession.ffa_active:
		return "LEAVE FFA\nF  FORFEIT ROUND"
	return "%s\n%s" % [title, subtitle]

func _build_visuals() -> void:
	var marker: MeshInstance3D = MeshInstance3D.new()
	marker.name = "PortalMarker"
	var box: BoxMesh = BoxMesh.new()
	box.size = Vector3(1.8, 0.08, 1.8)
	marker.mesh = box
	marker.position = Vector3(0.0, 0.05, 0.0)
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = marker_color
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	marker.material_override = material
	add_child(marker)

	_label = Label3D.new()
	_label.position = Vector3(0.0, 1.45, 0.0)
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.font_size = 42
	_label.outline_size = 12
	_label.pixel_size = 0.009
	_label.text = get_interaction_prompt(null)
	add_child(_label)
