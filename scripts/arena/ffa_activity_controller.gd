class_name FFAActivityController
extends Node

@export var player_path: NodePath = NodePath("../Player")
@export var opponent_path: NodePath = NodePath("../SparringBot")
@export var result_label_path: NodePath = NodePath("../HUD/Result")
@export var reward_cash: int = 350
@export var return_delay: float = 0.9
@export var return_scene: String = "res://scenes/world/street_block.tscn"

var _player: Node = null
var _opponent: Node = null
var _result_label: Label = null
var _finished: bool = false
var _return_left: float = -1.0

func _ready() -> void:
	_player = get_node_or_null(player_path)
	_opponent = get_node_or_null(opponent_path)
	_result_label = get_node_or_null(result_label_path) as Label
	if not GameSession.ffa_active:
		GameSession.begin_ffa(0)
	if _result_label != null:
		_result_label.visible = false

func _process(delta: float) -> void:
	if _finished:
		_return_left = maxf(_return_left - delta, 0.0)
		if _return_left <= 0.0:
			get_tree().change_scene_to_file(return_scene)
		return

	if _player == null or _opponent == null:
		return

	if _is_down(_player):
		_finish(false)
		return
	if _is_down(_opponent):
		_finish(true)

func _finish(win: bool) -> void:
	if _finished:
		return
	_finished = true
	_return_left = maxf(return_delay, 0.15)

	var extracted_item: Item = null
	var extracted_profile: WeaponCombatProfile = null
	if win and _player != null:
		if _player.has_method("get_equipped_item"):
			var item_value: Variant = _player.call("get_equipped_item")
			extracted_item = item_value as Item
		if _player.has_method("get_equipped_profile"):
			var profile_value: Variant = _player.call("get_equipped_profile")
			extracted_profile = profile_value as WeaponCombatProfile

	var result: Dictionary = GameSession.finish_ffa(win, extracted_item, extracted_profile, reward_cash if win else 0)
	_show_result(result)

func _is_down(actor: Node) -> bool:
	if actor == null or not actor.has_method("get_combat_phase_name"):
		return false
	return str(actor.call("get_combat_phase_name")) == "DOWN"

func _show_result(result: Dictionary) -> void:
	if _result_label == null:
		return
	_result_label.visible = true
	if bool(result.get("win", false)):
		var reward: int = int(result.get("reward_cash", 0))
		var weapon: String = str(result.get("extracted_weapon", ""))
		_result_label.text = "WIN  +$%d" % reward
		if not weapon.is_empty():
			_result_label.text += "\nEXTRACTED  %s" % weapon
	else:
		_result_label.text = "ELIMINATED\nARENA GEAR LOST"
