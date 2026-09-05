class_name FFAEntrance3D
extends Node3D

@export var target_scene: String = "res://scenes/arena/combat_lab.tscn"
@export var entry_fee: int = 100
@export var prize_cash: int = 350

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

func interact(actor: Node) -> void:
	if GameSession.cash < entry_fee:
		_flash("NEED $%d" % entry_fee)
		return
	if actor != null:
		GameSession.capture_player(actor)
	if not GameSession.begin_ffa(entry_fee):
		_flash("ACTIVITY UNAVAILABLE")
		return
	get_tree().change_scene_to_file(target_scene)

func get_interaction_prompt(_actor: Node) -> String:
	return "FFA SCRAMBLE  $%d ENTRY\nF  ENTER  |  WIN $%d + HELD WEAPON" % [entry_fee, prize_cash]

func _flash(value: String) -> void:
	_message = value
	_message_left = 1.4
	_refresh_label()

func _refresh_label() -> void:
	if _label == null:
		return
	_label.text = _message if not _message.is_empty() else get_interaction_prompt(null)

func _build_visuals() -> void:
	var ring: MeshInstance3D = MeshInstance3D.new()
	var mesh: CylinderMesh = CylinderMesh.new()
	mesh.top_radius = 1.15
	mesh.bottom_radius = 1.15
	mesh.height = 0.08
	mesh.radial_segments = 48
	ring.mesh = mesh
	ring.position = Vector3(0.0, 0.04, 0.0)
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = Color(0.72, 0.12, 0.10, 0.75)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ring.material_override = material
	add_child(ring)

	_label = Label3D.new()
	_label.position = Vector3(0.0, 1.6, 0.0)
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.font_size = 38
	_label.outline_size = 10
	_label.pixel_size = 0.008
	add_child(_label)
