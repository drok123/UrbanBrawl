class_name PoliceCaseBoard3D
extends Node3D

var _label: Label3D = null
var _detail_left: float = 0.0

func _ready() -> void:
	add_to_group("world_interactable")
	_build_visuals()
	_refresh_label()

func _process(delta: float) -> void:
	if _detail_left <= 0.0:
		return
	_detail_left = maxf(_detail_left - delta, 0.0)
	if _detail_left <= 0.0:
		_refresh_label()

func interact(_actor: Node) -> void:
	if GameSession.player_faction != GameSession.Faction.POLICE:
		_detail_left = 2.0
		_label.text = "POLICE CASE BOARD\nACCESS DENIED"
		return
	_detail_left = 5.0
	_label.text = _build_case_summary()

func get_interaction_prompt(_actor: Node) -> String:
	if GameSession.player_faction != GameSession.Faction.POLICE:
		return "CASE BOARD\nPOLICE ONLY"
	return "CASE BOARD  %d CASE\nF  REVIEW" % GameSession.police_case_value

func _build_case_summary() -> String:
	var lines: Array[String] = []
	lines.append("CASE BOARD  %d" % GameSession.police_case_value)
	if GameSession.evidence_packages.is_empty():
		lines.append("NO EVIDENCE PACKAGES")
		return "\n".join(lines)

	var start_index: int = maxi(GameSession.evidence_packages.size() - 3, 0)
	for index: int in range(GameSession.evidence_packages.size() - 1, start_index - 1, -1):
		var package: Dictionary = GameSession.evidence_packages[index]
		var kind: String = str(package.get("kind", &"unknown")).replace("_", " ").to_upper()
		var case_value: int = int(package.get("case_value", 0))
		var seized_units: int = int(package.get("seized_units", 0))
		var seized_weapon: String = str(package.get("seized_weapon", ""))
		var detail: String = "#%d %s  +%d" % [int(package.get("id", 0)), kind, case_value]
		if seized_units > 0:
			detail += "  %d PRODUCT" % seized_units
		if not seized_weapon.is_empty():
			detail += "  %s" % seized_weapon
		lines.append(detail)
	return "\n".join(lines)

func _refresh_label() -> void:
	if _label == null:
		return
	_label.text = get_interaction_prompt(null)

func _build_visuals() -> void:
	var board: MeshInstance3D = MeshInstance3D.new()
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = Vector3(3.7, 2.2, 0.18)
	board.mesh = mesh
	board.position = Vector3(0.0, 1.25, 0.0)
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = Color(0.10, 0.16, 0.24, 1.0)
	material.roughness = 0.82
	board.material_override = material
	add_child(board)

	_label = Label3D.new()
	_label.position = Vector3(0.0, 1.3, -0.12)
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.font_size = 34
	_label.outline_size = 9
	_label.pixel_size = 0.0075
	add_child(_label)
