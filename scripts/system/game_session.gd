extends Node

signal state_changed
signal crime_committed(event: Dictionary)
signal evidence_package_created(package: Dictionary)

enum Faction {
	NONE,
	ARMS,
	CONTRABAND,
	POLICE,
}

enum Territory {
	NEUTRAL,
	ARMS,
	CONTRABAND,
	POLICE,
}

enum FlagState {
	NEUTRAL,
	COMBAT,
	CRIMINAL,
	DUTY,
}

var cash: int = 900
var carried_item: Item = null
var carried_profile: WeaponCombatProfile = null
var stash: Array[Dictionary] = []

var player_faction: int = Faction.NONE
var current_territory: int = Territory.NEUTRAL
var heat: int = 0
var evidence: int = 0
var police_case_value: int = 0
var contraband_units: int = 0
var busts: int = 0

var evidence_packages: Array[Dictionary] = []
var last_crime_event: Dictionary = {}
var _crime_serial: int = 0
var _evidence_serial: int = 0

var _weapon_equipped: bool = false
var _combat_flag_left: float = 0.0
var _criminal_flag_left: float = 0.0
var _duty_flag_left: float = 0.0

var grow_cycle_left: float = 0.0
var grow_ready_units: int = 0

func _process(delta: float) -> void:
	_sync_weapon_flag_from_scene()
	var old_flag: int = get_flag_state()
	_combat_flag_left = maxf(_combat_flag_left - delta, 0.0)
	_criminal_flag_left = maxf(_criminal_flag_left - delta, 0.0)
	_duty_flag_left = maxf(_duty_flag_left - delta, 0.0)

	if grow_cycle_left > 0.0:
		grow_cycle_left = maxf(grow_cycle_left - delta, 0.0)
		if grow_cycle_left <= 0.0:
			grow_ready_units += 3
			state_changed.emit()

	if old_flag != get_flag_state():
		state_changed.emit()

func _sync_weapon_flag_from_scene() -> void:
	var scene: Node = get_tree().current_scene
	if scene == null:
		return
	var player: Node = scene.get_node_or_null("Player")
	if player == null or not player.has_method("get_equipped_item"):
		return
	var item_value: Variant = player.call("get_equipped_item")
	var is_equipped: bool = item_value != null
	if is_equipped != _weapon_equipped:
		set_weapon_equipped(is_equipped)

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

func set_player_faction(value: int) -> void:
	player_faction = clampi(value, Faction.NONE, Faction.POLICE)
	state_changed.emit()

func set_territory(value: int) -> void:
	current_territory = clampi(value, Territory.NEUTRAL, Territory.POLICE)
	state_changed.emit()

func set_weapon_equipped(is_equipped: bool) -> void:
	if _weapon_equipped == is_equipped:
		return
	_weapon_equipped = is_equipped
	if not is_equipped:
		_combat_flag_left = maxf(_combat_flag_left, 12.0)
	state_changed.emit()

func flag_combat(duration: float = 15.0) -> void:
	_combat_flag_left = maxf(_combat_flag_left, maxf(duration, 0.0))
	state_changed.emit()

func flag_crime(heat_delta: int = 5, evidence_delta: int = 3, duration: float = 30.0) -> void:
	_apply_crime_flag(heat_delta, evidence_delta, duration)
	state_changed.emit()

func commit_crime(kind: StringName, world_position: Vector3, heat_delta: int = 5, evidence_delta: int = 3, duration: float = 30.0, metadata: Dictionary = {}) -> Dictionary:
	_apply_crime_flag(heat_delta, evidence_delta, duration)
	_crime_serial += 1
	var event: Dictionary = {
		"id": _crime_serial,
		"kind": kind,
		"position": world_position,
		"territory": current_territory,
		"faction": player_faction,
		"heat": maxi(heat_delta, 0),
		"evidence": maxi(evidence_delta, 0),
		"metadata": metadata.duplicate(true),
		"timestamp_msec": Time.get_ticks_msec(),
	}
	last_crime_event = event.duplicate(true)
	crime_committed.emit(event.duplicate(true))
	state_changed.emit()
	return event

func _apply_crime_flag(heat_delta: int, evidence_delta: int, duration: float) -> void:
	_criminal_flag_left = maxf(_criminal_flag_left, maxf(duration, 0.0))
	_combat_flag_left = maxf(_combat_flag_left, maxf(duration, 0.0))
	heat += maxi(heat_delta, 0)
	evidence += maxi(evidence_delta, 0)

func flag_duty(duration: float = 30.0) -> void:
	_duty_flag_left = maxf(_duty_flag_left, maxf(duration, 0.0))
	_combat_flag_left = maxf(_combat_flag_left, maxf(duration, 0.0))
	state_changed.emit()

func get_flag_state() -> int:
	if _criminal_flag_left > 0.0:
		return FlagState.CRIMINAL
	if _duty_flag_left > 0.0:
		return FlagState.DUTY
	if _weapon_equipped or _combat_flag_left > 0.0:
		return FlagState.COMBAT
	return FlagState.NEUTRAL

func get_flag_name() -> String:
	match get_flag_state():
		FlagState.COMBAT:
			return "COMBAT FLAGGED"
		FlagState.CRIMINAL:
			return "CRIMINAL FLAGGED"
		FlagState.DUTY:
			return "DUTY FLAGGED"
	return "NEUTRAL"

func get_faction_name() -> String:
	match player_faction:
		Faction.ARMS:
			return "ARMS"
		Faction.CONTRABAND:
			return "CONTRABAND"
		Faction.POLICE:
			return "POLICE"
	return "UNAFFILIATED"

func get_territory_name() -> String:
	match current_territory:
		Territory.ARMS:
			return "ARMS TERRITORY"
		Territory.CONTRABAND:
			return "CONTRABAND TERRITORY"
		Territory.POLICE:
			return "POLICE TERRITORY"
	return "NEUTRAL TERRITORY"

func add_contraband(amount: int) -> void:
	contraband_units += maxi(amount, 0)
	state_changed.emit()

func spend_contraband(amount: int) -> bool:
	if amount <= 0:
		return true
	if contraband_units < amount:
		return false
	contraband_units -= amount
	state_changed.emit()
	return true

func seize_contraband(max_units: int = 999999) -> int:
	var seized: int = mini(contraband_units, maxi(max_units, 0))
	contraband_units -= seized
	state_changed.emit()
	return seized

func add_case_value(amount: int) -> void:
	police_case_value += maxi(amount, 0)
	state_changed.emit()

func create_evidence_package(crime_event: Dictionary, seized_units: int = 0, seized_weapon: String = "") -> Dictionary:
	if crime_event.is_empty():
		return {}
	_evidence_serial += 1
	var metadata_value: Variant = crime_event.get("metadata", {})
	var metadata: Dictionary = {}
	if metadata_value is Dictionary:
		metadata = metadata_value as Dictionary
	var event_evidence: int = int(crime_event.get("evidence", 0))
	var event_value: int = int(metadata.get("street_value", 0))
	var case_value: int = maxi(event_evidence * 2 + maxi(seized_units, 0) * 5 + int(round(float(event_value) / 80.0)), 1)
	var package: Dictionary = {
		"id": _evidence_serial,
		"crime_id": int(crime_event.get("id", 0)),
		"kind": crime_event.get("kind", &"unknown"),
		"territory": int(crime_event.get("territory", Territory.NEUTRAL)),
		"suspect_faction": int(crime_event.get("faction", Faction.NONE)),
		"seized_units": maxi(seized_units, 0),
		"seized_weapon": seized_weapon,
		"case_value": case_value,
		"confidence": 1.0,
		"timestamp_msec": Time.get_ticks_msec(),
		"metadata": metadata.duplicate(true),
	}
	evidence_packages.append(package)
	if evidence_packages.size() > 24:
		evidence_packages.pop_front()
	add_case_value(case_value)
	evidence_package_created.emit(package.duplicate(true))
	return package

func register_bust() -> void:
	busts += 1
	_criminal_flag_left = 0.0
	_combat_flag_left = maxf(_combat_flag_left, 4.0)
	heat = maxi(heat - 3, 0)
	state_changed.emit()

func start_grow_cycle(duration: float = 25.0) -> bool:
	if grow_cycle_left > 0.0 or grow_ready_units > 0:
		return false
	grow_cycle_left = maxf(duration, 1.0)
	state_changed.emit()
	return true

func harvest_grow() -> int:
	if grow_ready_units <= 0:
		return 0
	var harvested: int = grow_ready_units
	grow_ready_units = 0
	add_contraband(harvested)
	return harvested

func capture_player(player: Node) -> void:
	if player == null:
		return
	if not player.has_method("get_equipped_item") or not player.has_method("get_equipped_profile"):
		return
	var item_value: Variant = player.call("get_equipped_item")
	var profile_value: Variant = player.call("get_equipped_profile")
	carried_item = item_value as Item
	carried_profile = profile_value as WeaponCombatProfile
	set_weapon_equipped(carried_item != null and carried_profile != null)
	state_changed.emit()

func restore_player(player: Node) -> void:
	if player == null or carried_item == null or carried_profile == null:
		set_weapon_equipped(false)
		return
	if player.has_method("equip_weapon"):
		player.call("equip_weapon", carried_item, carried_profile)

func clear_carried() -> void:
	carried_item = null
	carried_profile = null
	set_weapon_equipped(false)
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
