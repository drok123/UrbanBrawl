class_name WeaponStatAffix
extends AffixDefinition

enum Stat {
	DAMAGE_PERCENT,
	SPEED_PERCENT,
	IMPACT_PERCENT,
	REACH_PERCENT,
}

@export var stat: Stat = Stat.DAMAGE_PERCENT
@export var min_value: int = 4
@export var max_value: int = 10

func can_apply_to(item: Item) -> bool:
	return item != null and item.base != null and item.base.slot_type == ItemBase.SlotType.WEAPON

func roll(_item: Item) -> AffixInstance:
	return AffixInstance.new(id, [randi_range(min_value, max_value)])

func range(_index: int) -> String:
	return "%d-%d%%" % [min_value, max_value]
