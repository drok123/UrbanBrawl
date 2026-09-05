class_name PlayerNameplate3D
extends Label3D

func _ready() -> void:
	position = Vector3(0.0, 2.45, 0.0)
	billboard = BaseMaterial3D.BILLBOARD_ENABLED
	font_size = 28
	outline_size = 8
	pixel_size = 0.0065
	text = GameSession.character_name
	match GameSession.player_faction:
		GameSession.Faction.POLICE:
			modulate = Color(0.55, 0.72, 1.0, 1.0)
		GameSession.Faction.CONTRABAND:
			modulate = Color(0.55, 1.0, 0.62, 1.0)
		GameSession.Faction.ARMS:
			modulate = Color(1.0, 0.62, 0.34, 1.0)
		_:
			modulate = Color.WHITE
