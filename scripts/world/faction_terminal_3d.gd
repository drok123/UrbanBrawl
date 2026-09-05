class_name FactionTerminal3D
extends Node3D

@export var faction_id: int = 0
@export var terminal_title: String = "FACTION"
@export var terminal_color: Color = Color(0.35, 0.35, 0.38, 1.0)

var _label: Label3D = null
var _message_left: float = 0.0
var _message: String = ""

func _ready() -> void:
	add_to_group("world_interactable")
	_build_visuals()
	_refresh_label()

func _process(delta: float) -> void:
	if _message_left <= 0.0:
		return
	_message_left = maxf(_message_left - delta, 0.0)
	if _message_left <= 0.0:
		_message = ""
		_refresh_label()

func interact(_actor: Node) -> void:
	GameSession.set_player_faction(faction_id)
	_message = "FACTION SET — %s" % GameSession.get_faction_name()
	_message_left = 1.4
	_refresh_label()

func get_interaction_prompt(_actor: Node) -> String:
	return "%s\nF  TEST THIS FACTION" % terminal_title

func _refresh_label() -> void:
	if _label == null:
		return
	_label.text = _message if not _message.is_empty() else get_interaction_prompt(null)

func _build_visuals() -> void:
	var pedestal: MeshInstance3D = MeshInstance3D.new()
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = Vector3(1.8, 0.85, 1.0)
	pedestal.mesh = mesh
	pedestal.position = Vector3(0.0, 0.43, 0.0)
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = terminal_color
	material.roughness = 0.82
	pedestal.material_override = material
	add_child(pedestal)

	_label = Label3D.new()
	_label.position = Vector3(0.0, 1.55, 0.0)
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.font_size = 38
	_label.outline_size = 10
	_label.pixel_size = 0.008
	_label.text = get_interaction_prompt(null)
	add_child(_label)
