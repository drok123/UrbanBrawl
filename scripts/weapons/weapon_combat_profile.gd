class_name WeaponCombatProfile
extends Resource

@export var item_id: StringName = &"weapon"
@export var display_name: String = "Weapon"
@export var basic_ability: CombatAbility
@export var secondary_ability: CombatAbility
@export var utility_ability: CombatAbility

@export_group("Held presentation")
@export var held_length: float = 1.65
@export var held_width: float = 0.12
@export var held_color: Color = Color(0.62, 0.42, 0.23, 1.0)
