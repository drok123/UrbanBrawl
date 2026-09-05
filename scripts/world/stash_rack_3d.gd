class_name StashRack3D
extends Node3D

@export var rack_color: Color = Color(0.16, 0.18, 0.20, 1.0)

var _label: Label3D = null
var _message: String = ""
var _message_left: float = 0.0

func _ready() -> void:
	add_to_group("world_interactable")
	_build_visuals()
	_refresh_label(null)

func _process(delta: float) -> void:
	if _message_left > 0.0:
		_message_left = maxf(_message_left - delta, 0.0)
		if _message_left <= 0.0:
			_message = ""

func interact(actor: Node) -> void:
	if actor == null:
		return

	if actor.has_method("get_equipped_item") and actor.has_method("get_equipped_profile"):
		var item_value: Variant = actor.call("get_equipped_item")
		var profile_value: Variant = actor.call("get_equipped_profile")
		var item: Item = item_value as Item
		var profile: WeaponCombatProfile = profile_value as WeaponCombatProfile
		if item != null and profile != null:
			if actor.has_method("take_equipped_weapon_for_storage"):
				var stored_value: Variant = actor.call("take_equipped_weapon_for_storage")
				if stored_value is Dictionary:
					var stored: Dictionary = stored_value as Dictionary
					var stored_item: Item = stored.get("item", null) as Item
					var stored_profile: WeaponCombatProfile = stored.get("profile", null) as WeaponCombatProfile
					if GameSession.store_weapon(stored_item, stored_profile):
						_flash_message("STASHED %s" % item.base.name.to_upper())
						_refresh_label(actor)
						return

	if GameSession.stash_count() <= 0:
		_flash_message("STASH EMPTY")
		_refresh_label(actor)
		return

	var entry: Dictionary = GameSession.take_last_stashed_weapon()
	var stashed_item: Item = entry.get("item", null) as Item
	var stashed_profile: WeaponCombatProfile = entry.get("profile", null) as WeaponCombatProfile
	if stashed_item == null or stashed_profile == null or not actor.has_method("equip_weapon"):
		_flash_message("STASH ERROR")
		_refresh_label(actor)
		return

	actor.call("equip_weapon", stashed_item, stashed_profile)
	GameSession.capture_player(actor)
	_flash_message("TOOK %s" % stashed_item.base.name.to_upper())
	_refresh_label(actor)

func get_interaction_prompt(actor: Node) -> String:
	if actor != null and actor.has_method("get_equipped_item"):
		var item_value: Variant = actor.call("get_equipped_item")
		var item: Item = item_value as Item
		if item != null and item.base != null:
			return "STASH RACK  %d ITEMS\nF  STORE %s" % [GameSession.stash_count(), item.base.name.to_upper()]
	if GameSession.stash_count() > 0:
		return "STASH RACK  %d ITEMS\nF  TAKE LAST WEAPON" % GameSession.stash_count()
	return "STASH RACK\nEMPTY"

func _flash_message(value: String) -> void:
	_message = value
	_message_left = 1.2

func _refresh_label(actor: Node) -> void:
	if _label == null:
		return
	_label.text = _message if not _message.is_empty() else get_interaction_prompt(actor)

func _build_visuals() -> void:
	for index: int in range(3):
		var shelf: MeshInstance3D = MeshInstance3D.new()
		var box: BoxMesh = BoxMesh.new()
		box.size = Vector3(2.5, 0.12, 0.75)
		shelf.mesh = box
		shelf.position = Vector3(0.0, 0.35 + float(index) * 0.58, 0.0)
		var material: StandardMaterial3D = StandardMaterial3D.new()
		material.albedo_color = rack_color
		material.roughness = 0.88
		shelf.material_override = material
		add_child(shelf)

	_label = Label3D.new()
	_label.position = Vector3(0.0, 2.55, 0.0)
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.font_size = 38
	_label.outline_size = 11
	_label.pixel_size = 0.009
	add_child(_label)
