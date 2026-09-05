class_name ArmsGunrunnerBuyer3D
extends Node3D

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

func interact(actor: Node) -> void:
	if GameSession.player_faction != GameSession.Faction.ARMS:
		_flash_message("ARMS FACTION ONLY")
		return
	if GameSession.current_territory != GameSession.Territory.CONTRABAND:
		_flash_message("BUYERS ONLY IN CONTRABAND TURF")
		return
	if actor == null or not actor.has_method("get_equipped_item") or not actor.has_method("take_equipped_weapon_for_storage"):
		_flash_message("NO WEAPON TO MOVE")
		return

	var item_value: Variant = actor.call("get_equipped_item")
	var item: Item = item_value as Item
	if item == null or item.base == null:
		_flash_message("EQUIP A WEAPON FIRST")
		return

	var rarity_index: int = WeaponItemRules.rarity_index(item)
	var rarity_name: String = WeaponItemRules.rarity_name(item)
	var weapon_name: String = item.base.name
	var base_value: int = int(item.base.base_value)
	var payout_multiplier: float = 2.0 + float(rarity_index) * 0.45
	var payout: int = maxi(int(round(float(base_value) * payout_multiplier)), 120)
	var heat_gain: int = 6 + rarity_index * 3
	var evidence_gain: int = 4 + rarity_index * 2
	var event_position: Vector3 = global_position
	var actor_3d: Node3D = actor as Node3D
	if actor_3d != null:
		event_position = actor_3d.global_position

	var removed_value: Variant = actor.call("take_equipped_weapon_for_storage")
	if not removed_value is Dictionary:
		_flash_message("TRANSFER FAILED")
		return
	var removed: Dictionary = removed_value as Dictionary
	var removed_item: Item = removed.get("item", null) as Item
	if removed_item == null:
		_flash_message("TRANSFER FAILED")
		return

	GameSession.clear_carried()
	GameSession.add_cash(payout)
	GameSession.commit_crime(
		&"illegal_weapon_sale",
		event_position,
		heat_gain,
		evidence_gain,
		criminal_flag_seconds,
		{
			"weapon_name": weapon_name,
			"rarity": rarity_name,
			"rarity_index": rarity_index,
			"street_value": payout,
		}
	)
	_flash_message("GUNRUN COMPLETE +$%d — CRIMINAL FLAGGED" % payout)

func get_interaction_prompt(actor: Node) -> String:
	if GameSession.player_faction != GameSession.Faction.ARMS:
		return "ILLEGAL ARMS BUYER\nARMS FACTION REQUIRED"
	if GameSession.current_territory != GameSession.Territory.CONTRABAND:
		return "ILLEGAL ARMS BUYER\nONLY PAYS IN CONTRABAND TURF"
	if actor != null and actor.has_method("get_equipped_item"):
		var item_value: Variant = actor.call("get_equipped_item")
		var item: Item = item_value as Item
		if item != null and item.base != null:
			return "ILLEGAL ARMS BUYER\nF  SELL %s — CRIME FLAG" % item.base.name.to_upper()
	return "ILLEGAL ARMS BUYER\nEQUIP A WEAPON TO SELL"

func _flash_message(value: String) -> void:
	_message = value
	_message_left = 1.5
	_refresh_label()

func _refresh_label() -> void:
	if _label == null:
		return
	_label.text = _message if not _message.is_empty() else get_interaction_prompt(null)

func _build_visuals() -> void:
	var crate: MeshInstance3D = MeshInstance3D.new()
	var crate_mesh: BoxMesh = BoxMesh.new()
	crate_mesh.size = Vector3(1.8, 0.8, 1.1)
	crate.mesh = crate_mesh
	crate.position = Vector3(0.0, 0.4, 0.0)
	var crate_material: StandardMaterial3D = StandardMaterial3D.new()
	crate_material.albedo_color = Color(0.32, 0.20, 0.12, 1.0)
	crate_material.roughness = 0.9
	crate.material_override = crate_material
	add_child(crate)

	_label = Label3D.new()
	_label.position = Vector3(0.0, 1.65, 0.0)
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.font_size = 38
	_label.outline_size = 10
	_label.pixel_size = 0.008
	add_child(_label)
