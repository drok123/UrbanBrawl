class_name HitReactionController3D
extends Node

const META_PHASE: StringName = &"hit_reaction_phase"
const META_VARIANT: StringName = &"hit_reaction_variant"
const META_PROGRESS: StringName = &"hit_reaction_progress"
const META_LEAN: StringName = &"hit_reaction_lean"
const META_TWIST: StringName = &"hit_reaction_twist"
const META_STEP: StringName = &"hit_reaction_step"

enum Reaction {
	NONE,
	RECOIL,
	STUMBLE,
	FALLBACK,
}

var _actor: CharacterBody3D = null
var _reaction: Reaction = Reaction.NONE
var _reaction_total: float = 0.0
var _reaction_left: float = 0.0
var _variant: int = 0
var _lean: float = 0.0
var _twist: float = 0.0
var _step_sign: float = 0.0
var _balance: float = 0.0
var _last_impact_direction: Vector3 = Vector3.ZERO

func bind_actor(actor: CharacterBody3D) -> void:
	_actor = actor
	_clear_meta()

func tick(delta: float) -> void:
	_balance = maxf(_balance - delta * 0.34, 0.0)
	if _reaction == Reaction.NONE:
		return

	_reaction_left = maxf(_reaction_left - delta, 0.0)
	var progress: float = 1.0
	if _reaction_total > 0.0:
		progress = clampf(1.0 - (_reaction_left / _reaction_total), 0.0, 1.0)
	_write_meta(progress)

	if _reaction_left <= 0.0:
		_reaction = Reaction.NONE
		_reaction_total = 0.0
		_clear_meta()

func apply_hit(hit: CombatHit, base_stun: float) -> float:
	if _actor == null or hit == null:
		return base_stun

	var horizontal_impulse: Vector3 = Vector3(hit.impulse.x, 0.0, hit.impulse.z)
	var force: float = horizontal_impulse.length()
	var damage: float = maxf(hit.damage, 0.0)
	var previous_balance: float = _balance
	_balance = clampf(_balance + damage / 170.0 + force / 11.0, 0.0, 2.6)

	_last_impact_direction = horizontal_impulse.normalized() if force > 0.001 else _fallback_direction(hit)
	_variant = randi_range(0, 5)
	_step_sign = -1.0 if randf() < 0.5 else 1.0
	_lean = randf_range(0.72, 1.18)
	_twist = randf_range(0.70, 1.30) * _step_sign

	var fall_chance: float = clampf(
		(force - 5.2) * 0.055 + (damage - 82.0) * 0.0034 + previous_balance * 0.16,
		0.0,
		0.72
	)
	var stumble_chance: float = clampf(
		0.10 + force * 0.045 + damage * 0.0014 + previous_balance * 0.13,
		0.08,
		0.76
	)

	# Piercing/slashing hits should read more like a recoil unless the raw force is large.
	if hit.damage_type == &"pierce" or hit.damage_type == &"slash":
		fall_chance *= 0.72
		stumble_chance *= 0.88

	var roll: float = randf()
	if roll < fall_chance:
		_start_reaction(Reaction.FALLBACK, randf_range(0.82, 1.18))
		_apply_fallback_motion(force)
		return maxf(base_stun, _reaction_total)

	if roll < fall_chance + stumble_chance * (1.0 - fall_chance):
		_start_reaction(Reaction.STUMBLE, randf_range(0.30, 0.52))
		_apply_stumble_motion(force)
		return maxf(base_stun, _reaction_total)

	_start_reaction(Reaction.RECOIL, randf_range(0.10, 0.19))
	return maxf(base_stun, _reaction_total)

func clear() -> void:
	_reaction = Reaction.NONE
	_reaction_total = 0.0
	_reaction_left = 0.0
	_balance = 0.0
	_clear_meta()

func _start_reaction(reaction: Reaction, duration: float) -> void:
	_reaction = reaction
	_reaction_total = maxf(duration, 0.05)
	_reaction_left = _reaction_total
	_write_meta(0.0)

func _apply_stumble_motion(force: float) -> void:
	if _actor == null:
		return
	var lateral: Vector3 = Vector3(-_last_impact_direction.z, 0.0, _last_impact_direction.x) * _step_sign
	var backward_push: float = clampf(force * 0.28, 0.45, 2.2)
	var side_push: float = randf_range(0.35, 1.15)
	_actor.velocity += _last_impact_direction * backward_push + lateral * side_push

func _apply_fallback_motion(force: float) -> void:
	if _actor == null:
		return
	var lateral: Vector3 = Vector3(-_last_impact_direction.z, 0.0, _last_impact_direction.x) * _step_sign
	var backward_push: float = clampf(force * 0.52, 1.3, 4.8)
	_actor.velocity += _last_impact_direction * backward_push + lateral * randf_range(0.18, 0.70)

func _fallback_direction(hit: CombatHit) -> Vector3:
	if _actor == null:
		return Vector3.BACK
	if hit.source != null:
		var away: Vector3 = _actor.global_position - hit.source.global_position
		away.y = 0.0
		if away.length_squared() > 0.001:
			return away.normalized()
	return -_actor.global_transform.basis.z.normalized()

func _write_meta(progress: float) -> void:
	if _actor == null:
		return
	_actor.set_meta(META_PHASE, _reaction_name())
	_actor.set_meta(META_VARIANT, _variant)
	_actor.set_meta(META_PROGRESS, progress)
	_actor.set_meta(META_LEAN, _lean)
	_actor.set_meta(META_TWIST, _twist)
	_actor.set_meta(META_STEP, _step_sign)

func _reaction_name() -> StringName:
	match _reaction:
		Reaction.RECOIL:
			return &"RECOIL"
		Reaction.STUMBLE:
			return &"STUMBLE"
		Reaction.FALLBACK:
			return &"FALLBACK"
	return &""

func _clear_meta() -> void:
	if _actor == null:
		return
	_actor.set_meta(META_PHASE, &"")
	_actor.set_meta(META_VARIANT, 0)
	_actor.set_meta(META_PROGRESS, 0.0)
	_actor.set_meta(META_LEAN, 0.0)
	_actor.set_meta(META_TWIST, 0.0)
	_actor.set_meta(META_STEP, 0.0)
