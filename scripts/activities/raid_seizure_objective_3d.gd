class_name RaidSeizureObjective3D
extends Node3D

@export var cash_reward: int = 500
@export var case_reward: int = 10

var _label: Label3D = null
var _message: String = ""
var _message_left: float = 0.0
var _complete: bool = false

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

func interact(actor: Node) -> void:
	if _complete:
		return
	if GameSession.player_faction != GameSession.Faction.POLICE:
		_flash("POLICE OBJECTIVE")
		return
	if _living_defenders() > 0:
		_flash("SECURE THE ROOM FIRST")
		return

	_complete = true
	GameSession.add_cash(cash_reward)
	GameSession.add_case_value(case_reward)
	if actor != null:
		GameSession.capture_player(actor)
	_flash("STASH SEIZED  +$%d  +%d CASE" % [cash_reward, case_reward])
	await get_tree().create_timer(0.8).timeout
	get_tree().change_scene_to_file(GameSession.get_home_scene())

func get_interaction_prompt(_actor: Node) -> String:
	var living: int = _living_defenders()
	if living > 0:
		return "CRIMINAL STASH\n%d DEFENDERS REMAIN" % living
	return "CRIMINAL STASH SECURED\nF  SEIZE +$%d" % cash_reward

func _living_defenders() -> int:
	var count: int = 0
	for node: Node in get_tree().get_nodes_in_group("raid_defender"):
		if node == null or not node.has_method("get_combat_phase_name"):
			continue
		if str(node.call("get_combat_phase_name")) != "DOWN":
			count += 1
	return count

func _flash(value: String) -> void:
	_message = value
	_message_left = 1.6
	_refresh_label()

func _refresh_label() -> void:
	if _label == null:
		return
	_label.text = _message if not _message.is_empty() else get_interaction_prompt(null)

func _build_visuals() -> void:
	for x_offset: float in [-0.75, 0.0, 0.75]:
		var crate: MeshInstance3D = MeshInstance3D.new()
		var mesh: BoxMesh = BoxMesh.new()
		mesh.size = Vector3(0.62, 0.55, 0.8)
		crate.mesh = mesh
		crate.position = Vector3(x_offset, 0.28, 0.0)
		var material: StandardMaterial3D = StandardMaterial3D.new()
		material.albedo_color = Color(0.27, 0.17, 0.09, 1.0)
		material.roughness = 0.9
		crate.material_override = material
		add_child(crate)

	_label = Label3D.new()
	_label.position = Vector3(0.0, 1.45, 0.0)
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.font_size = 36
	_label.outline_size = 10
	_label.pixel_size = 0.008
	add_child(_label)
