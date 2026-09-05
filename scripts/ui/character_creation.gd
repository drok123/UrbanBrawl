extends Control

const BODY_COLORS: Array[Color] = [
	Color(0.72, 0.76, 0.82, 1.0),
	Color(0.36, 0.48, 0.62, 1.0),
	Color(0.58, 0.34, 0.22, 1.0),
	Color(0.30, 0.58, 0.42, 1.0),
]
const ACCENT_COLORS: Array[Color] = [
	Color(0.16, 0.17, 0.20, 1.0),
	Color(0.62, 0.18, 0.15, 1.0),
	Color(0.15, 0.35, 0.68, 1.0),
	Color(0.76, 0.60, 0.18, 1.0),
]

@onready var _name_edit: LineEdit = $Panel/VBox/NameEdit
@onready var _faction_label: Label = $Panel/VBox/FactionLabel
@onready var _body_swatch: ColorRect = $Panel/VBox/Colors/BodySwatch
@onready var _accent_swatch: ColorRect = $Panel/VBox/Colors/AccentSwatch
@onready var _status: Label = $Panel/VBox/Status

var _faction: int = GameSession.Faction.CONTRABAND
var _body_index: int = 0
var _accent_index: int = 0

func _ready() -> void:
	$Panel/VBox/Factions/Arms.pressed.connect(func() -> void: _select_faction(GameSession.Faction.ARMS))
	$Panel/VBox/Factions/Contraband.pressed.connect(func() -> void: _select_faction(GameSession.Faction.CONTRABAND))
	$Panel/VBox/Factions/Police.pressed.connect(func() -> void: _select_faction(GameSession.Faction.POLICE))
	$Panel/VBox/Colors/BodyButton.pressed.connect(_cycle_body)
	$Panel/VBox/Colors/AccentButton.pressed.connect(_cycle_accent)
	$Panel/VBox/EnterCity.pressed.connect(_enter_city)
	_refresh()

func _select_faction(value: int) -> void:
	_faction = value
	match _faction:
		GameSession.Faction.POLICE:
			_accent_index = 2
		GameSession.Faction.ARMS:
			_accent_index = 1
		_:
			_accent_index = 0
	_refresh()

func _cycle_body() -> void:
	_body_index = (_body_index + 1) % BODY_COLORS.size()
	_refresh()

func _cycle_accent() -> void:
	_accent_index = (_accent_index + 1) % ACCENT_COLORS.size()
	_refresh()

func _enter_city() -> void:
	GameSession.create_character(_name_edit.text, _faction, BODY_COLORS[_body_index], ACCENT_COLORS[_accent_index])
	get_tree().change_scene_to_file("res://scenes/world/city_world.tscn")

func _refresh() -> void:
	var faction_name: String = "CONTRABAND"
	match _faction:
		GameSession.Faction.ARMS:
			faction_name = "ARMS"
		GameSession.Faction.POLICE:
			faction_name = "POLICE"
	_faction_label.text = "FACTION: %s" % faction_name
	_body_swatch.color = BODY_COLORS[_body_index]
	_accent_swatch.color = ACCENT_COLORS[_accent_index]
	_status.text = "Your faction decides your home base, foreign-profit loop and who controls your turf."
