class_name CombatHit
extends RefCounted

var source: Node3D = null
var ability_id: StringName = &""
var weapon_id: StringName = &"unarmed"
var damage_type: StringName = &"blunt"
var hit_location: StringName = &"body"

var damage: float = 0.0
var impulse: Vector3 = Vector3.ZERO
var wall_stun_window: float = 0.0
var hitstop: float = 0.0
