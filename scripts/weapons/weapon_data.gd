class_name WeaponData
extends Resource

@export var weapon_id: StringName = &"weapon"
@export var display_name: String = "Weapon"
@export var damage_type: StringName = &"blunt"
@export var basic_ability: CombatAbility
@export var secondary_ability: CombatAbility
@export var utility_ability: CombatAbility

@export_group("World")
@export var pickup_height: float = 0.18
@export var held_scale: Vector3 = Vector3.ONE

@export_group("Rarity Scaling")
@export var uncommon_damage: float = 1.08
@export var rare_damage: float = 1.16
@export var epic_damage: float = 1.26
@export var uncommon_speed: float = 1.03
@export var rare_speed: float = 1.06
@export var epic_speed: float = 1.10
@export var uncommon_knockback: float = 1.04
@export var rare_knockback: float = 1.08
@export var epic_knockback: float = 1.14
