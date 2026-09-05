class_name WeaponItemRules
extends RefCounted

const RARITY_NAMES: Array[String] = ["Common", "Uncommon", "Rare", "Epic", "Legendary"]
const RARITY_COLORS: Array[Color] = [
	Color(0.86, 0.88, 0.91, 1.0),
	Color(0.30, 0.95, 0.42, 1.0),
	Color(0.28, 0.56, 1.0, 1.0),
	Color(0.76, 0.34, 1.0, 1.0),
	Color(1.0, 0.55, 0.10, 1.0),
]

static func create_rolled_item(base: ItemBase) -> Item:
	if base == null:
		return null
	var item: Item = Item.new(base)
	var affix_count: int = _roll_affix_count()
	var candidates: Array[AffixDefinition] = AffixPool.get_affixes_for(item)
	for _index: int in range(affix_count):
		if candidates.is_empty():
			break
		var rolled: AffixInstance = AffixPool.roll_affix(candidates, item)
		if rolled == null:
			break
		item.add_affix(rolled)
	return item

static func rarity_index(item: Item) -> int:
	if item == null:
		return 0
	return clampi(item.affixes.size(), 0, RARITY_NAMES.size() - 1)

static func rarity_name(item: Item) -> String:
	return RARITY_NAMES[rarity_index(item)]

static func rarity_color(item: Item) -> Color:
	return RARITY_COLORS[rarity_index(item)]

static func stat_percent(item: Item, affix_id: String) -> float:
	if item == null or not item.has_affix(affix_id):
		return 0.0
	var affix: AffixInstance = item.get_affix(affix_id)
	if affix == null or affix.values.is_empty():
		return 0.0
	return float(affix.values[0])

static func damage_multiplier(item: Item, profile: WeaponCombatProfile) -> float:
	var multiplier: float = 1.0 + stat_percent(item, "brutal") / 100.0
	if item != null and item.base != null and profile != null and profile.reference_damage > 0.0:
		var average_damage: float = (float(item.base.min_damage) + float(item.base.max_damage)) * 0.5
		multiplier *= average_damage / profile.reference_damage
	return multiplier

static func speed_multiplier(item: Item, profile: WeaponCombatProfile) -> float:
	var multiplier: float = 1.0 + stat_percent(item, "quick") / 100.0
	if item != null and item.base != null and profile != null and profile.reference_attack_speed > 0.0:
		multiplier *= maxf(item.base.attack_speed, 0.05) / profile.reference_attack_speed
	return maxf(multiplier, 0.05)

static func impact_multiplier(item: Item) -> float:
	return 1.0 + stat_percent(item, "heavy") / 100.0

static func reach_multiplier(item: Item) -> float:
	return 1.0 + stat_percent(item, "long_reach") / 100.0

static func resolved_ability(base_ability: CombatAbility, item: Item, profile: WeaponCombatProfile) -> CombatAbility:
	if base_ability == null:
		return null
	var ability: CombatAbility = base_ability.duplicate(true) as CombatAbility
	if ability == null or item == null:
		return ability

	var damage_mult: float = damage_multiplier(item, profile)
	var speed_mult: float = speed_multiplier(item, profile)
	var impact_mult: float = impact_multiplier(item)
	var reach_mult: float = reach_multiplier(item)

	ability.damage *= damage_mult
	ability.knockback *= impact_mult
	ability.range_distance *= reach_mult
	ability.radius *= sqrt(reach_mult)
	ability.windup /= speed_mult
	ability.active_time /= speed_mult
	ability.recovery /= speed_mult
	ability.cooldown /= speed_mult
	return ability

static func _roll_affix_count() -> int:
	var roll: float = randf()
	if roll < 0.01:
		return 4
	if roll < 0.06:
		return 3
	if roll < 0.17:
		return 2
	if roll < 0.42:
		return 1
	return 0
