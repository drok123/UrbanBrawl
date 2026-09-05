class_name WorldStatusHUD
extends Label

@export var player_path: NodePath
@export var location_name: String = "URBAN BRAWL"

@onready var _player: Node = get_node_or_null(player_path)

func _process(_delta: float) -> void:
	var weapon_name: String = "UNARMED"
	if _player != null and _player.has_method("get_equipped_weapon_name"):
		weapon_name = str(_player.call("get_equipped_weapon_name"))

	text = "%s\n%s  |  %s  |  %s\nCASH $%d   PRODUCT %d   HEAT %d   EVIDENCE %d   STASH %d   CARRY %s" % [
		location_name,
		GameSession.get_faction_name(),
		GameSession.get_territory_name(),
		GameSession.get_flag_name(),
		GameSession.cash,
		GameSession.contraband_units,
		GameSession.heat,
		GameSession.evidence,
		GameSession.stash_count(),
		weapon_name,
	]
