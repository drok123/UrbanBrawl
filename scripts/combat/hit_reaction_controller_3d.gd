class_name HitReactionController3D
extends Node

const META_PHASE: StringName = &"hit_reaction_phase"
const META_VARIANT: StringName = &"hit_reaction_variant"

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

var _root_pivot: Node3D = null
var _torso_pivot: Node3D = null
var _head_pivot: Node3D = null
var _left_arm_pivot: Node3D = null
var _right_arm_pivot: Node3D = null
var _left_leg_pivot: Node3D = null
var _right_leg_pivot: Node3D = null

static func apply_to_body(body: Node3D, hit: CombatHit) -> void:
	var actor: CharacterBody3D = body as CharacterBody3D
	if actor == null or hit == null:
		return

	var controller: HitReactionController3D = actor.get_node_or_null("HitReactionController") as HitReactionController3D
	if controller == null:
		controller = HitReactionController3D.new()
		controller.name = "HitReactionController"
		actor.add_child(controller)
		controller.bind_actor(actor)

	var base_stun: float = 0.12
	if _has_property(actor, &"hitstun_duration"):
		base_stun = float(actor.get("hitstun_duration"))
	var reaction_stun: float = controller.apply_hit(hit, base_stun)
	if _has_property(actor, &"_stun_left"):
		var current_stun: float = float(actor.get("_stun_left"))
		actor.set("_stun_left", maxf(current_stun, reaction_stun))

static func _has_property(object: Object, property_name: StringName) -> bool:
	for property: Dictionary in object.get_property_list():
		if StringName(str(property.get("name", ""))) == property_name:
			return true
	return false

func bind_actor(actor: CharacterBody3D) -> void:
	_actor = actor
	_actor.set_meta(META_PHASE, &"")
	_actor.set_meta(META_VARIANT, 0)
	call_deferred("_ensure_visual_layers")

func _physics_process(delta: float) -> void:
	if _actor == null:
		return
	_ensure_visual_layers()
	_balance = maxf(_balance - delta * 0.34, 0.0)

	if _reaction != Reaction.NONE:
		_reaction_left = maxf(_reaction_left - delta, 0.0)
		var progress: float = 1.0
		if _reaction_total > 0.0:
			progress = clampf(1.0 - (_reaction_left / _reaction_total), 0.0, 1.0)
		_apply_visual_reaction(progress)
		if _reaction_left <= 0.0:
			_reaction = Reaction.NONE
			_reaction_total = 0.0
			_actor.set_meta(META_PHASE, &"")
	else:
		_relax_visuals(delta)

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
	if _actor != null:
		_actor.set_meta(META_PHASE, &"")
		_actor.set_meta(META_VARIANT, 0)
	_reset_visuals()

func _start_reaction(reaction: Reaction, duration: float) -> void:
	_reaction = reaction
	_reaction_total = maxf(duration, 0.05)
	_reaction_left = _reaction_total
	if _actor != null:
		_actor.set_meta(META_PHASE, _reaction_name())
		_actor.set_meta(META_VARIANT, _variant)

func _apply_stumble_motion(force: float) -> void:
	if _actor == null:
		return
	var lateral: Vector3 = Vector3(-_last_impact_direction.z, 0.0, _last_impact_direction.x) * _step_sign
	_actor.velocity += _last_impact_direction * clampf(force * 0.28, 0.45, 2.2)
	_actor.velocity += lateral * randf_range(0.35, 1.15)

func _apply_fallback_motion(force: float) -> void:
	if _actor == null:
		return
	var lateral: Vector3 = Vector3(-_last_impact_direction.z, 0.0, _last_impact_direction.x) * _step_sign
	_actor.velocity += _last_impact_direction * clampf(force * 0.52, 1.3, 4.8)
	_actor.velocity += lateral * randf_range(0.18, 0.70)

func _fallback_direction(hit: CombatHit) -> Vector3:
	if _actor == null:
		return Vector3.BACK
	if hit.source != null:
		var away: Vector3 = _actor.global_position - hit.source.global_position
		away.y = 0.0
		if away.length_squared() > 0.001:
			return away.normalized()
	return -_actor.global_transform.basis.z.normalized()

func _reaction_name() -> StringName:
	match _reaction:
		Reaction.RECOIL:
			return &"RECOIL"
		Reaction.STUMBLE:
			return &"STUMBLE"
		Reaction.FALLBACK:
			return &"FALLBACK"
	return &""

func _ensure_visual_layers() -> void:
	if _actor == null or _root_pivot != null:
		return
	var visual: Node3D = _actor.get_node_or_null("CharacterVisual") as Node3D
	if visual == null:
		return
	var model_root: Node3D = visual.get_node_or_null("ProceduralHumanoid") as Node3D
	if model_root == null:
		return

	_root_pivot = Node3D.new()
	_root_pivot.name = "HitReactionRootPivot"
	visual.add_child(_root_pivot)
	model_root.reparent(_root_pivot, false)

	_torso_pivot = _wrap_child(model_root, "Torso", "HitTorsoPivot")
	_head_pivot = _wrap_child(model_root, "Head", "HitHeadPivot")
	_left_arm_pivot = _wrap_child(model_root, "LeftArm", "HitLeftArmPivot")
	_right_arm_pivot = _wrap_child(model_root, "RightArm", "HitRightArmPivot")
	_left_leg_pivot = _wrap_child(model_root, "LeftLeg", "HitLeftLegPivot")
	_right_leg_pivot = _wrap_child(model_root, "RightLeg", "HitRightLegPivot")

func _wrap_child(parent: Node3D, child_name: String, pivot_name: String) -> Node3D:
	var child: Node3D = parent.get_node_or_null(child_name) as Node3D
	if child == null:
		return null
	var original_position: Vector3 = child.position
	var pivot: Node3D = Node3D.new()
	pivot.name = pivot_name
	pivot.position = original_position
	parent.add_child(pivot)
	child.reparent(pivot, false)
	child.position = Vector3.ZERO
	return pivot

func _apply_visual_reaction(progress: float) -> void:
	if _root_pivot == null:
		return
	var envelope: float = sin(clampf(progress, 0.0, 1.0) * PI)
	var variant_scale: float = 0.86 + float(_variant % 3) * 0.11
	var root_rotation: Vector3 = Vector3.ZERO
	var root_position: Vector3 = Vector3.ZERO
	var torso_rotation: Vector3 = Vector3.ZERO
	var head_rotation: Vector3 = Vector3.ZERO
	var left_arm_rotation: Vector3 = Vector3.ZERO
	var right_arm_rotation: Vector3 = Vector3.ZERO
	var left_leg_rotation: Vector3 = Vector3.ZERO
	var right_leg_rotation: Vector3 = Vector3.ZERO

	match _reaction:
		Reaction.RECOIL:
			root_rotation.x = -0.13 * envelope * _lean
			torso_rotation.y = 0.18 * envelope * _twist
			head_rotation.x = 0.12 * envelope
			if _variant % 2 == 0:
				right_arm_rotation.x = -0.38 * envelope
			else:
				left_arm_rotation.x = -0.38 * envelope

		Reaction.STUMBLE:
			var step_wave: float = sin(progress * PI * (2.0 + float(_variant % 2)))
			root_rotation.x = -0.30 * envelope * _lean
			root_rotation.z = 0.10 * envelope * _step_sign * variant_scale
			root_position.z = 0.10 * envelope
			torso_rotation.y = 0.34 * envelope * _twist
			head_rotation.z = -0.08 * envelope * _step_sign
			left_arm_rotation.x = (-0.42 + 0.16 * step_wave) * envelope
			right_arm_rotation.x = (-0.62 - 0.14 * step_wave) * envelope
			left_leg_rotation.x = step_wave * 0.42 * _step_sign
			right_leg_rotation.x = -step_wave * 0.42 * _step_sign

		Reaction.FALLBACK:
			var fall_amount: float = 0.0
			if progress < 0.42:
				fall_amount = smoothstep(0.0, 0.42, progress)
			elif progress < 0.68:
				fall_amount = 1.0
			else:
				fall_amount = 1.0 - smoothstep(0.68, 1.0, progress)
			root_rotation.x = -1.18 * fall_amount * _lean
			root_rotation.z = 0.12 * fall_amount * _step_sign * variant_scale
			root_position.y = -0.40 * fall_amount
			root_position.z = 0.18 * fall_amount
			torso_rotation.y = 0.28 * fall_amount * _twist
			head_rotation.x = 0.20 * fall_amount
			left_arm_rotation.x = -0.74 * fall_amount
			right_arm_rotation.x = -0.44 * fall_amount
			left_leg_rotation.x = (0.30 + 0.12 * float(_variant % 2)) * fall_amount
			right_leg_rotation.x = (-0.22 - 0.10 * float((_variant + 1) % 2)) * fall_amount

	_root_pivot.rotation = root_rotation
	_root_pivot.position = root_position
	_set_pivot_rotation(_torso_pivot, torso_rotation)
	_set_pivot_rotation(_head_pivot, head_rotation)
	_set_pivot_rotation(_left_arm_pivot, left_arm_rotation)
	_set_pivot_rotation(_right_arm_pivot, right_arm_rotation)
	_set_pivot_rotation(_left_leg_pivot, left_leg_rotation)
	_set_pivot_rotation(_right_leg_pivot, right_leg_rotation)

func _set_pivot_rotation(pivot: Node3D, value: Vector3) -> void:
	if pivot != null:
		pivot.rotation = value

func _relax_visuals(delta: float) -> void:
	var blend: float = clampf(delta * 12.0, 0.0, 1.0)
	if _root_pivot != null:
		_root_pivot.rotation = _root_pivot.rotation.lerp(Vector3.ZERO, blend)
		_root_pivot.position = _root_pivot.position.lerp(Vector3.ZERO, blend)
	for pivot: Node3D in [_torso_pivot, _head_pivot, _left_arm_pivot, _right_arm_pivot, _left_leg_pivot, _right_leg_pivot]:
		if pivot != null:
			pivot.rotation = pivot.rotation.lerp(Vector3.ZERO, blend)

func _reset_visuals() -> void:
	if _root_pivot != null:
		_root_pivot.rotation = Vector3.ZERO
		_root_pivot.position = Vector3.ZERO
	for pivot: Node3D in [_torso_pivot, _head_pivot, _left_arm_pivot, _right_arm_pivot, _left_leg_pivot, _right_leg_pivot]:
		if pivot != null:
			pivot.rotation = Vector3.ZERO
