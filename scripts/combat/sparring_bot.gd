extends CharacterBody3D

@export var target_path: NodePath
@export var max_health: float = 500.0
@export var move_speed: float = 5.3
@export var acceleration: float = 22.0
@export var rotation_speed: float = 11.0
@export var preferred_distance: float = 2.0
@export var decision_interval: float = 0.22
@export var hitstun_duration: float = 0.14
@export var wall_stun_duration: float = 0.72
@export var knockback_drag: float = 16.0
@export var respawn_delay: float = 1.4
@export var weapon_seek_radius: float = 14.0
@export var weapon_pickup_distance: float = 1.45

enum CombatPhase {
	READY,
	WINDUP,
	ACTIVE,
	RECOVERY,
}

var _unarmed_jab: CombatAbility = preload("res://resources/abilities/sparring_jab.tres") as CombatAbility
var _unarmed_heavy: CombatAbility = preload("res://resources/abilities/sparring_heavy.tres") as CombatAbility

var jab_ability: CombatAbility = preload("res://resources/abilities/sparring_jab.tres") as CombatAbility
var heavy_ability: CombatAbility = preload("res://resources/abilities/sparring_heavy.tres") as CombatAbility
var utility_ability: CombatAbility = null

var health: float = 0.0
var _spawn_position: Vector3 = Vector3.ZERO
var _dead: bool = false
var _respawn_left: float = 0.0
var _stun_left: float = 0.0
var _hitstop_left: float = 0.0
var _wall_stun_window_left: float = 0.0
var _decision_left: float = 0.0
var _strafe_sign: float = 1.0

var _current_ability: CombatAbility = null
var _combat_phase: CombatPhase = CombatPhase.READY
var _phase_time_left: float = 0.0
var _ability_forward: Vector3 = Vector3.FORWARD
var _cooldowns: Dictionary = {}

var _hitbox: MeleeHitbox3D = null
var _telegraph: MeshInstance3D = null
var _behavior_tree: BeehaveTree = null
var _weapon_target: WorldWeaponPickup3D = null
var _ai_mode: StringName = &"fight"

var _equipped_item: Item = null
var _equipped_profile: WeaponCombatProfile = null
var _held_weapon_visual: Node3D = null

@onready var _target: Node3D = get_node_or_null(target_path) as Node3D
@onready var _mesh: MeshInstance3D = $Mesh
@onready var _health_label: Label3D = $HealthLabel

func _ready() -> void:
	add_to_group("damageable")
	_spawn_position = global_position
	health = max_health
	_set_unarmed_loadout()
	_setup_hitbox()
	_setup_behavior_tree()
	_update_health_label()

func _physics_process(delta: float) -> void:
	if _dead:
		_respawn_left = maxf(_respawn_left - delta, 0.0)
		velocity = Vector3.ZERO
		if _respawn_left <= 0.0:
			_reset_after_death()
		return

	if _hitstop_left > 0.0:
		_hitstop_left = maxf(_hitstop_left - delta, 0.0)
		return

	_tick_cooldowns(delta)
	_stun_left = maxf(_stun_left - delta, 0.0)
	_wall_stun_window_left = maxf(_wall_stun_window_left - delta, 0.0)
	_decision_left = maxf(_decision_left - delta, 0.0)

	if _target == null or not is_instance_valid(_target):
		velocity = Vector3.ZERO
		return

	if _stun_left <= 0.0:
		_advance_combat_state(delta)
		if _current_ability == null and _behavior_tree != null:
			_behavior_tree.tick()

	_update_facing(delta)

	if _stun_left > 0.0:
		velocity.x = move_toward(velocity.x, 0.0, knockback_drag * delta)
		velocity.z = move_toward(velocity.z, 0.0, knockback_drag * delta)
		velocity.y = 0.0
	elif _current_ability != null:
		_update_combat_movement(delta, _current_ability.movement_multiplier)
	else:
		_update_combat_movement(delta, 1.0)

	move_and_slide()
	_check_for_wall_stun()
	_update_health_label()

func receive_hit(hit: CombatHit) -> void:
	if hit == null or _dead:
		return

	health = maxf(health - hit.damage, 0.0)
	velocity += Vector3(hit.impulse.x, 0.0, hit.impulse.z)
	_hitstop_left = maxf(_hitstop_left, hit.hitstop)
	_wall_stun_window_left = maxf(_wall_stun_window_left, hit.wall_stun_window)
	_stun_left = maxf(_stun_left, hitstun_duration)
	_cancel_current_ability()
	_hit_feedback()

	if health <= 0.0:
		_die()

func _setup_behavior_tree() -> void:
	var tree: BeehaveTree = BeehaveTree.new()
	tree.name = "CombatBehaviorTree"
	tree.process_thread = BeehaveTree.ProcessThread.MANUAL
	add_child(tree)

	var selector: SelectorComposite = SelectorComposite.new()
	selector.name = "WeaponOrFight"
	tree.add_child(selector)

	var seek_action: SeekGroundWeaponAction = SeekGroundWeaponAction.new()
	seek_action.name = "SeekGroundWeapon"
	selector.add_child(seek_action)

	var fight_action: FightTargetAction = FightTargetAction.new()
	fight_action.name = "FightTarget"
	selector.add_child(fight_action)

	_behavior_tree = tree

func ai_seek_ground_weapon() -> bool:
	if _dead or _stun_left > 0.0 or _current_ability != null:
		return false
	if _equipped_item != null:
		return false

	var pickup: WorldWeaponPickup3D = _nearest_weapon_pickup()
	if pickup == null:
		_weapon_target = null
		return false

	_ai_mode = &"seek_weapon"
	_weapon_target = pickup
	var distance: float = global_position.distance_to(pickup.global_position)
	if distance > weapon_pickup_distance:
		return true

	var profile: WeaponCombatProfile = pickup.get_profile()
	if profile == null:
		return false
	var item: Item = pickup.take_item()
	if item == null:
		return false

	equip_weapon(item, profile)
	_weapon_target = null
	_ai_mode = &"fight"
	return true

func ai_fight_target() -> bool:
	if _target == null or not is_instance_valid(_target):
		return false
	_ai_mode = &"fight"
	_weapon_target = null
	_update_decision()
	return true

func _nearest_weapon_pickup() -> WorldWeaponPickup3D:
	var nearest: WorldWeaponPickup3D = null
	var best_distance_sq: float = weapon_seek_radius * weapon_seek_radius
	for node: Node in get_tree().get_nodes_in_group("weapon_pickup"):
		var pickup: WorldWeaponPickup3D = node as WorldWeaponPickup3D
		if pickup == null or not pickup.is_available():
			continue
		var distance_sq: float = global_position.distance_squared_to(pickup.global_position)
		if distance_sq <= best_distance_sq:
			best_distance_sq = distance_sq
			nearest = pickup
	return nearest

func equip_weapon(item: Item, profile: WeaponCombatProfile) -> bool:
	if item == null or profile == null:
		return false
	if profile.basic_ability == null or profile.secondary_ability == null:
		return false

	_equipped_item = item
	_equipped_profile = profile
	jab_ability = WeaponItemRules.resolved_ability(profile.basic_ability, item, profile)
	heavy_ability = WeaponItemRules.resolved_ability(profile.secondary_ability, item, profile)
	utility_ability = WeaponItemRules.resolved_ability(profile.utility_ability, item, profile) if profile.utility_ability != null else null
	_reset_combat_cooldowns()
	_create_held_weapon_visual()
	set_meta("equipped_weapon_name", get_equipped_weapon_name())
	set_meta("weapon_rarity_id", get_weapon_rarity_id())
	return true

func drop_equipped_weapon(drop_distance: float = 0.9) -> void:
	if _equipped_item == null or _equipped_profile == null:
		return

	var item_to_drop: Item = _equipped_item
	var profile_to_drop: WeaponCombatProfile = _equipped_profile
	_set_unarmed_loadout()

	var pickup: WorldWeaponPickup3D = WorldWeaponPickup3D.new()
	pickup.name = "BotDroppedWeapon"
	pickup.base_item = item_to_drop.base
	pickup.combat_profile = profile_to_drop
	pickup.item_instance = item_to_drop

	var parent_3d: Node3D = get_parent() as Node3D
	if parent_3d == null:
		return
	parent_3d.add_child(pickup)
	var forward: Vector3 = -global_transform.basis.z.normalized()
	pickup.global_position = global_position + forward * drop_distance
	pickup.global_position.y = 0.18

func _set_unarmed_loadout() -> void:
	_equipped_item = null
	_equipped_profile = null
	jab_ability = _unarmed_jab
	heavy_ability = _unarmed_heavy
	utility_ability = null
	_reset_combat_cooldowns()
	_clear_held_weapon_visual()
	if has_meta("equipped_weapon_name"):
		remove_meta("equipped_weapon_name")
	if has_meta("weapon_rarity_id"):
		remove_meta("weapon_rarity_id")

func _reset_combat_cooldowns() -> void:
	_cooldowns.clear()
	if jab_ability != null:
		_cooldowns[jab_ability.ability_id] = 0.0
	if heavy_ability != null:
		_cooldowns[heavy_ability.ability_id] = 0.0
	if utility_ability != null:
		_cooldowns[utility_ability.ability_id] = 0.0

func _create_held_weapon_visual() -> void:
	_clear_held_weapon_visual()
	if _equipped_profile == null:
		return

	var root: Node3D = Node3D.new()
	root.name = "HeldWeapon"
	root.position = Vector3(0.46, 0.28, -0.38)
	root.rotation_degrees = Vector3(0.0, 0.0, -28.0)
	add_child(root)

	var mesh_instance: MeshInstance3D = MeshInstance3D.new()
	var cylinder: CylinderMesh = CylinderMesh.new()
	cylinder.top_radius = maxf(_equipped_profile.held_width * 0.42, 0.035)
	cylinder.bottom_radius = maxf(_equipped_profile.held_width * 0.58, 0.045)
	cylinder.height = _equipped_profile.held_length
	cylinder.radial_segments = 12
	mesh_instance.mesh = cylinder

	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = _equipped_profile.held_color
	material.roughness = 0.70
	mesh_instance.material_override = material
	root.add_child(mesh_instance)
	_held_weapon_visual = root

func _clear_held_weapon_visual() -> void:
	if _held_weapon_visual != null and is_instance_valid(_held_weapon_visual):
		_held_weapon_visual.queue_free()
	_held_weapon_visual = null

func _tick_cooldowns(delta: float) -> void:
	for key: Variant in _cooldowns.keys():
		_cooldowns[key] = maxf(float(_cooldowns[key]) - delta, 0.0)

func _update_decision() -> void:
	if _decision_left > 0.0 or _target == null:
		return

	_decision_left = decision_interval + randf_range(0.0, 0.12)
	var flat_to_target: Vector3 = _target.global_position - global_position
	flat_to_target.y = 0.0
	var distance: float = flat_to_target.length()

	if utility_ability != null and get_cooldown_remaining(utility_ability.ability_id) <= 0.0:
		if distance <= _effective_attack_range(utility_ability) and randf() < 0.24:
			_start_ability(utility_ability)
			return

	if heavy_ability != null and get_cooldown_remaining(heavy_ability.ability_id) <= 0.0:
		if distance <= _effective_attack_range(heavy_ability) and randf() < 0.30:
			_start_ability(heavy_ability)
			return

	if jab_ability != null and get_cooldown_remaining(jab_ability.ability_id) <= 0.0:
		if distance <= _effective_attack_range(jab_ability):
			_start_ability(jab_ability)
			return

	if randf() < 0.20:
		_strafe_sign *= -1.0

func _effective_attack_range(ability: CombatAbility) -> float:
	if ability == null:
		return 0.0
	if ability.mode == CombatAbility.AbilityMode.RANGED:
		return minf(ability.range_distance * 0.72, 13.0)
	return ability.range_distance + ability.radius * 0.78

func _preferred_fight_distance() -> float:
	if jab_ability != null and jab_ability.mode == CombatAbility.AbilityMode.RANGED:
		return clampf(jab_ability.range_distance * 0.34, 5.0, 7.5)
	return preferred_distance

func _update_facing(delta: float) -> void:
	if _current_ability != null or _stun_left > 0.0:
		return

	var face_target: Node3D = _target
	if _ai_mode == &"seek_weapon" and _weapon_target != null and is_instance_valid(_weapon_target):
		face_target = _weapon_target
	if face_target == null:
		return

	var direction: Vector3 = face_target.global_position - global_position
	direction.y = 0.0
	if direction.length_squared() < 0.001:
		return

	var target_yaw: float = atan2(-direction.x, -direction.z)
	rotation.y = lerp_angle(rotation.y, target_yaw, clampf(rotation_speed * delta, 0.0, 1.0))

func _update_combat_movement(delta: float, speed_multiplier: float) -> void:
	if _ai_mode == &"seek_weapon" and _weapon_target != null and is_instance_valid(_weapon_target):
		var to_weapon: Vector3 = _weapon_target.global_position - global_position
		to_weapon.y = 0.0
		var weapon_direction: Vector3 = to_weapon.normalized() if to_weapon.length_squared() > 0.001 else Vector3.ZERO
		var weapon_desired: Vector3 = weapon_direction * move_speed * 1.12 * speed_multiplier
		velocity.x = move_toward(velocity.x, weapon_desired.x, acceleration * delta)
		velocity.z = move_toward(velocity.z, weapon_desired.z, acceleration * delta)
		velocity.y = 0.0
		return

	if _target == null:
		velocity = Vector3.ZERO
		return

	var to_target: Vector3 = _target.global_position - global_position
	to_target.y = 0.0
	var distance: float = to_target.length()
	if distance < 0.001:
		velocity = Vector3.ZERO
		return

	var forward: Vector3 = to_target.normalized()
	var side: Vector3 = Vector3(-forward.z, 0.0, forward.x) * _strafe_sign
	var desired_direction: Vector3 = Vector3.ZERO
	var fight_distance: float = _preferred_fight_distance()

	if _current_ability != null:
		desired_direction = forward * (0.08 if _current_ability.mode == CombatAbility.AbilityMode.RANGED else 0.25)
	elif distance > fight_distance + 0.65:
		desired_direction = (forward + side * 0.18).normalized()
	elif distance < fight_distance - 0.55:
		desired_direction = (-forward + side * 0.30).normalized()
	else:
		desired_direction = side

	var desired: Vector3 = desired_direction * move_speed * speed_multiplier
	velocity.x = move_toward(velocity.x, desired.x, acceleration * delta)
	velocity.z = move_toward(velocity.z, desired.z, acceleration * delta)
	velocity.y = 0.0

func _start_ability(ability: CombatAbility) -> void:
	if ability == null or _target == null or _dead or _stun_left > 0.0:
		return
	if get_cooldown_remaining(ability.ability_id) > 0.0:
		return

	var direction: Vector3 = _target.global_position - global_position
	direction.y = 0.0
	if direction.length_squared() < 0.001:
		return

	_ability_forward = direction.normalized()
	var target_yaw: float = atan2(-_ability_forward.x, -_ability_forward.z)
	rotation.y = target_yaw

	_current_ability = ability
	_combat_phase = CombatPhase.WINDUP
	_phase_time_left = ability.windup
	_cooldowns[ability.ability_id] = ability.cooldown
	_show_telegraph(ability)

func _advance_combat_state(delta: float) -> void:
	if _current_ability == null:
		return

	_phase_time_left = maxf(_phase_time_left - delta, 0.0)
	if _phase_time_left > 0.0:
		return

	match _combat_phase:
		CombatPhase.WINDUP:
			_enter_active_phase()
		CombatPhase.ACTIVE:
			_enter_recovery_phase()
		CombatPhase.RECOVERY:
			_finish_ability()

func _enter_active_phase() -> void:
	if _current_ability == null:
		return

	_combat_phase = CombatPhase.ACTIVE
	_phase_time_left = _current_ability.active_time
	_hide_telegraph()
	_hitbox.activate(_current_ability, self)
	if _current_ability.self_impulse > 0.0:
		velocity += _ability_forward * _current_ability.self_impulse
	_attack_pulse()

func _enter_recovery_phase() -> void:
	if _current_ability == null:
		return
	_hitbox.deactivate()
	_combat_phase = CombatPhase.RECOVERY
	_phase_time_left = _current_ability.recovery

func _finish_ability() -> void:
	_hitbox.deactivate()
	_hide_telegraph()
	_current_ability = null
	_combat_phase = CombatPhase.READY
	_phase_time_left = 0.0

func _cancel_current_ability() -> void:
	_hitbox.deactivate()
	_hide_telegraph()
	_current_ability = null
	_combat_phase = CombatPhase.READY
	_phase_time_left = 0.0

func _setup_hitbox() -> void:
	var hitbox: MeleeHitbox3D = MeleeHitbox3D.new()
	hitbox.name = "MeleeHitbox"
	hitbox.collision_layer = 0
	hitbox.collision_mask = 1

	var collision: CollisionShape3D = CollisionShape3D.new()
	collision.name = "CollisionShape3D"
	var sphere: SphereShape3D = SphereShape3D.new()
	sphere.radius = 1.0
	collision.shape = sphere
	hitbox.add_child(collision)
	add_child(hitbox)

	_hitbox = hitbox
	_hitbox.hit_landed.connect(_on_hit_landed)

func _on_hit_landed(_impact_position: Vector3, hitstop: float) -> void:
	_hitstop_left = maxf(_hitstop_left, hitstop)

func _show_telegraph(ability: CombatAbility) -> void:
	_hide_telegraph()
	var telegraph: MeshInstance3D = MeshInstance3D.new()
	telegraph.name = "BotTelegraph"

	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = ability.telegraph_color
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	telegraph.material_override = material

	if ability.telegraph_shape == CombatAbility.TelegraphShape.BOX:
		var box: BoxMesh = BoxMesh.new()
		var length: float = maxf(ability.telegraph_length, ability.range_distance)
		box.size = Vector3(maxf(ability.radius * 2.0, 0.08), 0.025, length)
		telegraph.mesh = box
		telegraph.position = Vector3(0.0, -0.86, -length * 0.5)
	else:
		var disc: CylinderMesh = CylinderMesh.new()
		disc.top_radius = ability.radius
		disc.bottom_radius = ability.radius
		disc.height = 0.025
		disc.radial_segments = 48
		telegraph.mesh = disc
		telegraph.position = Vector3(0.0, -0.86, -ability.range_distance)

	add_child(telegraph)
	_telegraph = telegraph

func _hide_telegraph() -> void:
	if _telegraph != null and is_instance_valid(_telegraph):
		_telegraph.queue_free()
	_telegraph = null

func _check_for_wall_stun() -> void:
	if _wall_stun_window_left <= 0.0:
		return

	for index: int in range(get_slide_collision_count()):
		var collision: KinematicCollision3D = get_slide_collision(index)
		if collision == null:
			continue
		var normal: Vector3 = collision.get_normal()
		if absf(normal.y) > 0.5:
			continue
		var collider: Object = collision.get_collider()
		if collider is StaticBody3D:
			_wall_stun_window_left = 0.0
			_stun_left = maxf(_stun_left, wall_stun_duration)
			velocity = Vector3.ZERO
			_cancel_current_ability()
			return

func _attack_pulse() -> void:
	if _mesh == null:
		return
	var tween: Tween = create_tween()
	tween.tween_property(_mesh, "scale", Vector3(1.12, 0.88, 1.12), 0.06)
	tween.tween_property(_mesh, "scale", Vector3.ONE, 0.08)

func _hit_feedback() -> void:
	if _mesh == null:
		return
	var tween: Tween = create_tween()
	tween.tween_property(_mesh, "scale", Vector3(1.18, 0.74, 1.18), 0.06)
	tween.tween_property(_mesh, "scale", Vector3.ONE, 0.10)

func _die() -> void:
	if _equipped_item != null:
		drop_equipped_weapon(0.75)
	_dead = true
	_respawn_left = respawn_delay
	velocity = Vector3.ZERO
	_cancel_current_ability()
	if _mesh != null:
		var tween: Tween = create_tween()
		tween.tween_property(_mesh, "scale", Vector3(1.4, 0.15, 1.4), 0.14)
	_update_health_label()

func _reset_after_death() -> void:
	_dead = false
	_respawn_left = 0.0
	_stun_left = 0.0
	_hitstop_left = 0.0
	_wall_stun_window_left = 0.0
	_decision_left = 0.0
	health = max_health
	velocity = Vector3.ZERO
	global_position = _spawn_position
	_set_unarmed_loadout()
	_ai_mode = &"fight"
	_weapon_target = null
	if _mesh != null:
		_mesh.scale = Vector3.ONE
	_update_health_label()

func get_cooldown_remaining(ability_id: StringName) -> float:
	return float(_cooldowns.get(ability_id, 0.0))

func get_combat_phase_name() -> String:
	if _dead:
		return "DOWN"
	if _stun_left > 0.0:
		return "HITSTUN"
	return str(CombatPhase.keys()[_combat_phase])

func get_equipped_weapon_name() -> String:
	if _equipped_item == null or _equipped_item.base == null:
		return "UNARMED"
	return "%s %s" % [WeaponItemRules.rarity_name(_equipped_item).to_upper(), _equipped_item.base.name.to_upper()]

func get_weapon_rarity_id() -> StringName:
	if _equipped_item == null:
		return &"common"
	return StringName(WeaponItemRules.rarity_name(_equipped_item).to_lower())

func _update_health_label() -> void:
	if _health_label == null:
		return
	if _dead:
		_health_label.text = "DOWN\n%d / %d" % [int(health), int(max_health)]
	elif _stun_left > 0.0:
		_health_label.text = "STUNNED %.1fs\n%d / %d" % [_stun_left, int(health), int(max_health)]
	else:
		_health_label.text = "SPARRING BOT — %s\n%d / %d" % [get_equipped_weapon_name(), int(health), int(max_health)]
