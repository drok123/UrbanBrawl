class_name ContrabandBuyer3D
extends Node3D

@export var units_per_sale: int = 1
@export var cash_per_unit: int = 180
@export var heat_per_sale: int = 8
@export var evidence_per_sale: int = 5
@export var criminal_flag_seconds: float = 30.0

var _label: Label3D = null
var _message_left: float = 0.0
var _message: String = ""

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
	if GameSession.player_faction != GameSession.Faction.CONTRABAND:
		_flash_message("CONTRABAND FACTION ONLY")
		return
	if GameSession.current_territory != GameSession.Territory.POLICE:
		_flash_message("NO BUYERS OUTSIDE POLICE TURF")
		return
	if GameSession.contraband_units < units_per_sale:
		_flash_message("NO PRODUCT")
		return
	if not GameSession.spend_contraband(units_per_sale):
		return

	var payout: int = cash_per_unit * units_per_sale
	GameSession.add_cash(payout)
	GameSession.flag_crime(heat_per_sale, evidence_per_sale, criminal_flag_seconds)
	_flash_message("SOLD +$%d — CRIMINAL FLAGGED" % payout)

func get_interaction_prompt(_actor: Node) -> String:
	if GameSession.player_faction != GameSession.Faction.CONTRABAND:
		return "STREET BUYER\nCONTRABAND FACTION REQUIRED"
	if GameSession.current_territory != GameSession.Territory.POLICE:
		return "STREET BUYER\nONLY PAYS IN POLICE TERRITORY"
	if GameSession.contraband_units < units_per_sale:
		return "STREET BUYER\nNO PRODUCT — GROW SOME FIRST"
	return "STREET BUYER  $%d / UNIT\nF  SELL %d — CRIME FLAG" % [cash_per_unit, units_per_sale]

func _flash_message(value: String) -> void:
	_message = value
	_message_left = 1.5
	_refresh_label()

func _refresh_label() -> void:
	if _label == null:
		return
	_label.text = _message if not _message.is_empty() else get_interaction_prompt(null)

func _build_visuals() -> void:
	var body: MeshInstance3D = MeshInstance3D.new()
	var body_mesh: BoxMesh = BoxMesh.new()
	body_mesh.size = Vector3(0.72, 1.15, 0.46)
	body.mesh = body_mesh
	body.position = Vector3(0.0, 0.92, 0.0)
	var body_material: StandardMaterial3D = StandardMaterial3D.new()
	body_material.albedo_color = Color(0.18, 0.17, 0.22, 1.0)
	body_material.roughness = 0.88
	body.material_override = body_material
	add_child(body)

	var head: MeshInstance3D = MeshInstance3D.new()
	var head_mesh: SphereMesh = SphereMesh.new()
	head_mesh.radius = 0.27
	head_mesh.height = 0.54
	head.mesh = head_mesh
	head.position = Vector3(0.0, 1.72, 0.0)
	var head_material: StandardMaterial3D = StandardMaterial3D.new()
	head_material.albedo_color = Color(0.42, 0.30, 0.24, 1.0)
	head.material_override = head_material
	add_child(head)

	_label = Label3D.new()
	_label.position = Vector3(0.0, 2.45, 0.0)
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.font_size = 38
	_label.outline_size = 10
	_label.pixel_size = 0.008
	add_child(_label)
