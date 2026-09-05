class_name PoliceWarrantDesk3D
extends Node3D

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
	if not GameSession.can_issue_warrant():
		_flash("NEED %d CASE + %d EVIDENCE PACKAGES" % [GameSession.WARRANT_CASE_COST, GameSession.WARRANT_MIN_PACKAGES])
		return
	if GameSession.issue_warrant():
		_flash("WARRANT ISSUED  |  TOTAL %d" % GameSession.warrants)

func get_interaction_prompt(_actor: Node) -> String:
	if GameSession.player_faction != GameSession.Faction.POLICE:
		return "WARRANT DESK\nPOLICE ONLY"
	if GameSession.can_issue_warrant():
		return "WARRANT READY\nF  ISSUE  |  COST %d CASE" % GameSession.WARRANT_CASE_COST
	return "WARRANT DESK\n%d / %d CASE   %d / %d PACKAGES" % [
		GameSession.police_case_value,
		GameSession.WARRANT_CASE_COST,
		GameSession.evidence_packages.size(),
		GameSession.WARRANT_MIN_PACKAGES,
	]

func _flash(value: String) -> void:
	_message = value
	_message_left = 1.7
	_refresh_label()

func _refresh_label() -> void:
	if _label == null:
		return
	_label.text = _message if not _message.is_empty() else get_interaction_prompt(null)

func _build_visuals() -> void:
	var desk: MeshInstance3D = MeshInstance3D.new()
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = Vector3(2.4, 0.8, 1.1)
	desk.mesh = mesh
	desk.position = Vector3(0.0, 0.4, 0.0)
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = Color(0.16, 0.18, 0.22, 1.0)
	material.roughness = 0.86
	desk.material_override = material
	add_child(desk)

	var folder: MeshInstance3D = MeshInstance3D.new()
	var folder_mesh: BoxMesh = BoxMesh.new()
	folder_mesh.size = Vector3(0.9, 0.05, 0.62)
	folder.mesh = folder_mesh
	folder.position = Vector3(0.0, 0.84, 0.0)
	var folder_material: StandardMaterial3D = StandardMaterial3D.new()
	folder_material.albedo_color = Color(0.72, 0.62, 0.30, 1.0)
	folder.material_override = folder_material
	add_child(folder)

	_label = Label3D.new()
	_label.position = Vector3(0.0, 1.5, 0.0)
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.font_size = 34
	_label.outline_size = 9
	_label.pixel_size = 0.0075
	add_child(_label)
