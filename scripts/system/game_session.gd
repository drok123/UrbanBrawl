extends Node

signal state_changed

var cash: int = 900
var carried_item: Item = null
var carried_profile: WeaponCombatProfile = null
var stash: Array[Dictionary] = []

func spend_cash(amount: int) -> bool:
	if amount <= 0:
		return true
	if cash < amount:
		return false
	cash -= amount
	state_changed.emit()
	return true

func add_cash(amount: int) -> void:
	cash += maxi(amount, 0)
	state_changed.emit()

func capture_player(player: Node) -> void:
	if player == null:
		return
	if not player.has_method("get_equipped_item") or not player.has_method("get_equipped_profile"):
		return
	var item_value: Variant = player.call("get_equipped_item")
	var profile_value: Variant = player.call("get_equipped_profile")
	carried_item = item_value as Item
	carried_profile = profile_value as WeaponCombatProfile
	state_changed.emit()

func restore_player(player: Node) -> void:
	if player == null or carried_item == null or carried_profile == null:
		return
	if player.has_method("equip_weapon"):
		player.call("equip_weapon", carried_item, carried_profile)

func clear_carried() -> void:
	carried_item = null
	carried_profile = null
	state_changed.emit()

func store_weapon(item: Item, profile: WeaponCombatProfile) -> bool:
	if item == null or profile == null:
		return false
	stash.append({"item": item, "profile": profile})
	clear_carried()
	state_changed.emit()
	return true

func take_last_stashed_weapon() -> Dictionary:
	if stash.is_empty():
		return {}
	var value: Variant = stash.pop_back()
	state_changed.emit()
	if value is Dictionary:
		return value as Dictionary
	return {}

func stash_count() -> int:
	return stash.size()
