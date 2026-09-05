class_name CombatAbility
extends Resource

enum AbilityMode {
	MELEE,
	CHARGE,
}

enum TelegraphShape {
	DISC,
	BOX,
}

@export var ability_id: StringName = &"ability"
@export var display_name: String = "Ability"
@export var mode: AbilityMode = AbilityMode.MELEE

@export_group("Timing")
@export var cooldown: float = 1.0
@export var windup: float = 0.10
@export var active_time: float = 0.08
@export var recovery: float = 0.18

@export_group("Hit")
@export var damage: float = 50.0
@export var range_distance: float = 1.5
@export var radius: float = 0.9
@export var knockback: float = 4.0
@export var hitstop: float = 0.035
@export var wall_stun_window: float = 0.0

@export_group("Movement")
@export var movement_multiplier: float = 0.55
@export var self_impulse: float = 0.0
@export var charge_speed: float = 0.0

@export_group("Telegraph")
@export var telegraph_shape: TelegraphShape = TelegraphShape.DISC
@export var telegraph_length: float = 0.0
@export var telegraph_color: Color = Color(1.0, 0.55, 0.16, 0.24)
