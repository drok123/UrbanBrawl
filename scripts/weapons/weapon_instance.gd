class_name WeaponInstance
extends RefCounted

enum Rarity {
	COMMON,
	UNCOMMON,
	RARE,
	EPIC,
}

var data: WeaponData
var rarity: Rarity = Rarity.COMMON

func _init(weapon_data: WeaponData = null, rolled_rarity: Rarity = Rarity.COMMON) -> void:
	data = weapon_data
	rarity = rolled_rarity

func rarity_name() -> String:
	return Rarity.keys()[rarity].capitalize()

func rarity_id() -> StringName:
	return StringName(Rarity.keys()[rarity].to_lower())

func rarity_color() -> Color:
	match rarity:
		Rarity.UNCOMMON:
			return Color(0.30, 0.95, 0.42, 1.0)
		Rarity.RARE:
			return Color(0.28, 0.56, 1.0, 1.0)
		Rarity.EPIC:
			return Color(0.76, 0.34, 1.0, 1.0)
		_:
			return Color(0.86, 0.88, 0.91, 1.0)

func damage_multiplier() -> float:
	if data == null:
		return 1.0
	match rarity:
		Rarity.UNCOMMON:
			return data.uncommon_damage
		Rarity.RARE:
			return data.rare_damage
		Rarity.EPIC:
			return data.epic_damage
		_:
			return 1.0

func speed_multiplier() -> float:
	if data == null:
		return 1.0
	match rarity:
		Rarity.UNCOMMON:
			return data.uncommon_speed
		Rarity.RARE:
			return data.rare_speed
		Rarity.EPIC:
			return data.epic_speed
		_:
			return 1.0

func knockback_multiplier() -> float:
	if data == null:
		return 1.0
	match rarity:
		Rarity.UNCOMMON:
			return data.uncommon_knockback
		Rarity.RARE:
			return data.rare_knockback
		Rarity.EPIC:
			return data.epic_knockback
		_:
			return 1.0

static func roll_rarity() -> Rarity:
	var roll: float = randf()
	if roll < 0.04:
		return Rarity.EPIC
	if roll < 0.15:
		return Rarity.RARE
	if roll < 0.40:
		return Rarity.UNCOMMON
	return Rarity.COMMON
