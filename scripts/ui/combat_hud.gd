extends Control

@export var player_path: NodePath
@export var opponent_path: NodePath = NodePath("../../SparringBot")
@export var ffa_reward_cash: int = 350
@export var ffa_return_delay: float = 0.9

@onready var _player: Node = get_node(player_path)
@onready var _opponent: Node = get_node_or_null(opponent_path)
@onready var _basic_label: Label = $AbilityBar/Basic
@onready var _cleave_label: Label = $AbilityBar/Cleave
@onready var _charge_label: Label = $AbilityBar/Charge
@onready var _dash_label: Label = $AbilityBar/Dash
@onready var _phase_label: Label = $Phase
@onready var _health_label: Label = $Health

var _ffa_finished: bool = false
var _ffa_return_left: float = -1.0

func _ready() -> void:
	if not GameSession.ffa_active:
		GameSession.begin_ffa(0)

func _process(delta: float) -> void:
	if _ffa_finished:
		_ffa_return_left = maxf(_ffa_return_left - delta, 0.0)
		if _ffa_return_left <= 0.0:
			get_tree().change_scene_to_file("res://scenes/world/city_world.tscn")
		return

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

	_resolve_ffa_if_needed()

func _resolve_ffa_if_needed() -> void:
	if not GameSession.ffa_active or _opponent == null:
		return
	if _is_down(_player):
		_finish_ffa(false)
		return
	if _is_down(_opponent):
		_finish_ffa(true)

func _finish_ffa(win: bool) -> void:
	if _ffa_finished:
		return
	_ffa_finished = true
	_ffa_return_left = maxf(ffa_return_delay, 0.15)

	var extracted_item: Item = null
	var extracted_profile: WeaponCombatProfile = null
	if win:
		if _player.has_method("get_equipped_item"):
			var item_value: Variant = _player.call("get_equipped_item")
			extracted_item = item_value as Item
		if _player.has_method("get_equipped_profile"):
			var profile_value: Variant = _player.call("get_equipped_profile")
			extracted_profile = profile_value as WeaponCombatProfile

	var result: Dictionary = GameSession.finish_ffa(win, extracted_item, extracted_profile, ffa_reward_cash if win else 0)
	if win:
		var reward: int = int(result.get("reward_cash", 0))
		var extracted_name: String = str(result.get("extracted_weapon", ""))
		_phase_label.text = "WIN  +$%d" % reward
		if not extracted_name.is_empty():
			_phase_label.text += "  |  EXTRACTED %s" % extracted_name
	else:
		_phase_label.text = "ELIMINATED  |  ARENA GEAR LOST"

func _is_down(actor: Node) -> bool:
	if actor == null or not actor.has_method("get_combat_phase_name"):
		return false
	return str(actor.call("get_combat_phase_name")) == "DOWN"

func _update_ability_label(label: Label, key_name: String, ability_id: StringName) -> void:
	var remaining: float = float(_player.call("get_cooldown_remaining", ability_id))
	var ability_name: String = str(_player.call("get_ability_display_name", ability_id))
	label.text = _slot_text(key_name, ability_name, remaining)

func _slot_text(key_name: String, ability_name: String, remaining: float) -> String:
	var status: String = "READY"
	if remaining > 0.0:
		status = "%.1fs" % remaining
	return "%s   %s\n%s" % [key_name, ability_name, status]
