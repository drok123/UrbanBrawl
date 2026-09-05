class_name PoliceRaidLaunch3D
extends Node3D

@export var target_scene: String = "res://scenes/activities/police_raid.tscn"

var _label: Label3D = null
var _message: String = ""
var _message_left: float = 0.0

func _ready() -> void:
	add_to_group("world_interactable")
	_build_visuals()
	_refresh_label()

func _process(delta: float) -> void:
	if _message_left > 0.0:
		_message_left = maxf(_message_left - delta, 0.0)
		if _message_left <= 0.0:
			_message = ""
	_refresh_label()

func interact(_actor: Node) -> void:
	if GameSession.player_faction != GameSession.Faction.POLICE:
		_flash("POLICE ONLY")
		return
	if GameSession.warrants <= 0:
		_flash("NO WARRANT")
		return
	GameSession.warrants -= 1
	GameSession.state_changed.emit()
	get_tree().change_scene_to_file(target_scene)

func get_interaction_prompt(_actor: Node) -> String:
	if GameSession.player_faction != GameSession.Faction.POLICE:
		return "RAID BOARD\nPOLICE ONLY"
	if GameSession.warrants <= 0:
		return "RAID BOARD\nISSUE A WARRANT FIRST"
	return "RAID BOARD  %d WARRANT\nF  LAUNCH ARMS RAID" % GameSession.warrants

func _flash(value: String) -> void:
	_message = value
	_message_left = 1.6
	_refresh_label()

func _refresh_label() -> void:
	if _label == null:
		return
	_label.text = _message if not _message.is_empty() else get_interaction_prompt(null)

func _build_visuals() -> void:
	var table: MeshInstance3D = MeshInstance3D.new()
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = Vector3(2.6, 0.72, 1.5)
	table.mesh = mesh
	table.position = Vector3(0.0, 0.36, 0.0)
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = Color(0.18, 0.14, 0.11, 1.0)
	material.roughness = 0.9
	table.material_override = material
	add_child(table)

	_label = Label3D.new()
	_label.position = Vector3(0.0, 1.45, 0.0)
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.font_size = 34
	_label.outline_size = 9
	_label.pixel_size = 0.0075
	add_child(_label)
