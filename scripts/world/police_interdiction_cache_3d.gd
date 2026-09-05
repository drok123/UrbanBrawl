class_name PoliceInterdictionCache3D
extends Node3D

@export var cash_reward: int = 160
@export var case_value_reward: int = 12
@export var duty_flag_seconds: float = 30.0
@export var reset_seconds: float = 20.0

var _available: bool = true
var _reset_left: float = 0.0
var _label: Label3D = null
var _message_left: float = 0.0
var _message: String = ""

func _ready() -> void:
	add_to_group("world_interactable")
	_build_visuals()
	_refresh_label()

func _process(delta: float) -> void:
	if not _available:
		_reset_left = maxf(_reset_left - delta, 0.0)
		if _reset_left <= 0.0:
			_available = true
	if _message_left > 0.0:
		_message_left = maxf(_message_left - delta, 0.0)
		if _message_left <= 0.0:
			_message = ""
	_refresh_label()

func interact(_actor: Node) -> void:
	if GameSession.player_faction != GameSession.Faction.POLICE:
		_flash_message("POLICE FACTION ONLY")
		return
	if GameSession.current_territory != GameSession.Territory.ARMS:
		_flash_message("NO WARRANT ACTION HERE")
		return
	if not _available:
		_flash_message("CACHE ALREADY CLEARED")
		return

	_available = false
	_reset_left = reset_seconds
	GameSession.flag_duty(duty_flag_seconds)
	GameSession.add_cash(cash_reward)
	GameSession.add_case_value(case_value_reward)
	_flash_message("INTERDICTION +$%d  +%d CASE — DUTY FLAGGED" % [cash_reward, case_value_reward])

func get_interaction_prompt(_actor: Node) -> String:
	if GameSession.player_faction != GameSession.Faction.POLICE:
		return "ILLEGAL WEAPON CACHE\nPOLICE INTERDICTION ONLY"
	if GameSession.current_territory != GameSession.Territory.ARMS:
		return "ILLEGAL WEAPON CACHE\nARMS TERRITORY REQUIRED"
	if not _available:
		return "ILLEGAL WEAPON CACHE\nCLEARED — %.0fs" % ceilf(_reset_left)
	return "ILLEGAL WEAPON CACHE\nF  INTERDICT — DUTY FLAG"

func _flash_message(value: String) -> void:
	_message = value
	_message_left = 1.5
	_refresh_label()

func _refresh_label() -> void:
	if _label == null:
		return
	_label.text = _message if not _message.is_empty() else get_interaction_prompt(null)

func _build_visuals() -> void:
	for x_offset: float in [-0.65, 0.65]:
		var crate: MeshInstance3D = MeshInstance3D.new()
		var mesh: BoxMesh = BoxMesh.new()
		mesh.size = Vector3(1.0, 0.75, 1.0)
		crate.mesh = mesh
		crate.position = Vector3(x_offset, 0.38, 0.0)
		var material: StandardMaterial3D = StandardMaterial3D.new()
		material.albedo_color = Color(0.23, 0.16, 0.11, 1.0)
		material.roughness = 0.92
		crate.material_override = material
		add_child(crate)

	_label = Label3D.new()
	_label.position = Vector3(0.0, 1.7, 0.0)
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.font_size = 38
	_label.outline_size = 10
	_label.pixel_size = 0.008
	add_child(_label)
