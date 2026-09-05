extends Control

@export var player_path: NodePath

@onready var _player: Node = get_node(player_path)
@onready var _basic_label: Label = $AbilityBar/Basic
@onready var _cleave_label: Label = $AbilityBar/Cleave
@onready var _charge_label: Label = $AbilityBar/Charge
@onready var _dash_label: Label = $AbilityBar/Dash
@onready var _phase_label: Label = $Phase
@onready var _health_label: Label = $Health

func _process(_delta: float) -> void:
	if _player == null:
		return

	_update_ability_label(_basic_label, "LMB", &"basic")
	_update_ability_label(_cleave_label, "Q", &"cleave")
	_update_ability_label(_charge_label, "E", &"charge")

	var dash_remaining: float = float(_player.call("get_dash_cooldown_remaining"))
	_dash_label.text = _slot_text("SPACE", "DASH", dash_remaining)

	var phase_name: String = str(_player.call("get_combat_phase_name"))
	_phase_label.text = "COMBAT STATE: %s" % phase_name

	var health: float = float(_player.call("get_health"))
	var max_health: float = float(_player.call("get_max_health"))
	var weapon_name: String = str(_player.call("get_equipped_weapon_name"))
	_health_label.text = "YOU   %d / %d HP    |    %s" % [int(health), int(max_health), weapon_name]

func _update_ability_label(label: Label, key_name: String, ability_id: StringName) -> void:
	var remaining: float = float(_player.call("get_cooldown_remaining", ability_id))
	var ability_name: String = str(_player.call("get_ability_display_name", ability_id))
	label.text = _slot_text(key_name, ability_name, remaining)

func _slot_text(key_name: String, ability_name: String, remaining: float) -> String:
	var status: String = "READY"
	if remaining > 0.0:
		status = "%.1fs" % remaining
	return "%s   %s\n%s" % [key_name, ability_name, status]
