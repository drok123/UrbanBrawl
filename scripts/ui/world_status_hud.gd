class_name WorldStatusHUD
extends Label

@export var player_path: NodePath
@export var location_name: String = "URBAN BRAWL"

func _process(_delta: float) -> void:
	var parts: Array[String] = []
	parts.append("$%d" % GameSession.cash)

	if GameSession.contraband_units > 0:
		parts.append("PRODUCT %d" % GameSession.contraband_units)

	if GameSession.heat > 0:
		parts.append("HEAT %d" % GameSession.heat)

	if GameSession.player_faction == GameSession.Faction.POLICE and GameSession.police_case_value > 0:
		parts.append("CASE %d" % GameSession.police_case_value)

	var flag_name: String = GameSession.get_flag_name()
	if flag_name != "NEUTRAL":
		parts.append(flag_name.replace(" FLAGGED", ""))

	text = "   |   ".join(parts)
