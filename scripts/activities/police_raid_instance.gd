class_name PoliceRaidInstance
extends Node3D

@export var player_path: NodePath = NodePath("Player")
@export var failure_return_delay: float = 0.8

var _player: Node = null
var _failed: bool = false
var _return_left: float = -1.0

func _ready() -> void:
	GameSession.set_territory(GameSession.Territory.ARMS)
	GameSession.flag_duty(60.0)
	_player = get_node_or_null(player_path)

func _process(delta: float) -> void:
	if _failed:
		_return_left = maxf(_return_left - delta, 0.0)
		if _return_left <= 0.0:
			get_tree().change_scene_to_file("res://scenes/world/hideout.tscn")
		return
	if _player == null or not _player.has_method("get_combat_phase_name"):
		return
	if str(_player.call("get_combat_phase_name")) == "DOWN":
		_failed = true
		_return_left = maxf(failure_return_delay, 0.15)
		GameSession.clear_carried()
