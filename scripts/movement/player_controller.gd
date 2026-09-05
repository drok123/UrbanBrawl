extends CharacterBody3D

@export var move_speed: float = 7.0
@export var acceleration: float = 30.0
@export var rotation_speed: float = 18.0
@export var interaction_radius: float = 2.2

@export_category("Survivability")
@export var max_health: float = 500.0
@export var hitstun_duration: float = 0.12
@export var knockback_drag: float = 18.0
@export var respawn_delay: float = 1.25

@export_category("Dash")
@export var dash_speed: float = 18.0
@export var dash_duration: float = 0.14
@export var dash_cooldown: float = 0.85
@export var dash_invulnerability_padding: float = 0.04

enum CombatPhase {
	READY,
	WINDUP,
	ACTIVE,
	RECOVERY,
}

var _unarmed_basic: CombatAbility = preload("res://resources/abilities/basic_attack.tres") as CombatAbility
var _unarmed_cleave: CombatAbility = preload("res://resources/abilities/heavy_cleave.tres") as CombatAbility
var _unarmed_charge: CombatAbility = preload("res://resources/abilities/shoulder_charge.tres") as CombatAbility

var basic_ability: CombatAbility = preload("res://resources/abilities/basic_attack.tres") as CombatAbility
var cleave_ability: CombatAbility = preload("res://resources/abilities/heavy_cleave.tres") as CombatAbility
var charge_ability: CombatAbility = preload("res://resources/abilities/shoulder_charge.tres") as CombatAbility

var aim_point: Vector3 = Vector3.ZERO
var last_move_direction: Vector3 = Vector3.FORWARD
var health: float = 0.0

var _spawn_position: Vector3 = Vector3.ZERO
var _dead: bool = false
var _respawn_left: float = 0.0
var _stun_left: float = 0.0
var _invulnerable_left: float = 0.0

var _current_ability: CombatAbility = null
var _combat_phase: CombatPhase = CombatPhase.READY
var _phase_time_left: float = 0.0
var _ability_forward: Vector3 = Vector3.FORWARD
var _cooldowns: Dictionary = {}

var _dash_cooldown_left: float = 0.0
var _dash_time_left: float = 0.0
var _dash_direction: Vector3 = Vector3.ZERO
var _hitstop_left: float = 0.0

var _hitbox: MeleeHitbox3D = null
var _telegraph: MeshInstance3D = null
var _held_weapon_visual: Node3D = null
var _equipped_item: Item = null
var _equipped_profile: WeaponCombatProfile = null

func _ready() -> void:
	add_to_group("damageable")
	_ensure_input_actions()
	_spawn_position = global_position
	health = max_health
	_reset_combat_cooldowns()
	_setup_hitbox()

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
	_dash_cooldown_left = maxf(_dash_cooldown_left - delta, 0.0)
	_dash_time_left = maxf(_dash_time_left - delta, 0.0)
	_stun_left = maxf(_stun_left - delta, 0.0)
	_invulnerable_left = maxf(_invulnerable_left - delta, 0.0)

	_update_aim(delta)

	if _stun_left <= 0.0:
		_advance_combat_state(delta)
		_handle_weapon_input()
		_handle_combat_input()

	if _stun_left > 0.0:
		velocity.x = move_toward(velocity.x, 0.0, knockback_drag * delta)
		velocity.z = move_toward(velocity.z, 0.0, knockback_drag * delta)
		velocity.y = 0.0
	elif _dash_time_left > 0.0:
		velocity = _dash_direction * dash_speed
	elif _current_ability != null and _combat_phase == CombatPhase.ACTIVE and _current_ability.mode == CombatAbility.AbilityMode.CHARGE:
		velocity = _ability_forward * _current_ability.charge_speed
	else:
		var movement_multiplier: float = 1.0
		if _current_ability != null:
			movement_multiplier = _current_ability.movement_multiplier
		_update_movement(delta, movement_multiplier)

	move_and_slide()
	_check_charge_wall_collision()

func receive_hit(hit: CombatHit) -> void:
	if hit == null or _dead or is_invulnerable():
		return

	health = maxf(health - hit.damage, 0.0)
	velocity += Vector3(hit.impulse.x, 0.0, hit.impulse.z)
	_hitstop_left = maxf(_hitstop_left, hit.hitstop)
	_stun_left = maxf(_stun_left, hitstun_duration)
	_cancel_current_ability()
	_pulse_player(Vector3(1.16, 0.78, 1.16), 0.065)

	if health <= 0.0:
		_die()

func is_invulnerable() -> bool:
	return _invulnerable_left > 0.0 or _dead

func _die() -> void:
	_cancel_current_ability()
	if _equipped_item != null:
		drop_equipped_weapon(0.75)
	_dead = true
	_respawn_left = respawn_delay
	velocity = Vector3.ZERO
	_hitbox.deactivate()

	var mesh: MeshInstance3D = get_node_or_null("Mesh") as MeshInstance3D
	if mesh != null:
		var tween: Tween = create_tween()
		tween.tween_property(mesh, "scale", Vector3(1.35, 0.18, 1.35), 0.13)

func _reset_after_death() -> void:
	_dead = false
	_respawn_left = 0.0
	_stun_left = 0.0
	_invulnerable_left = 0.35
	_hitstop_left = 0.0
	health = max_health
	velocity = Vector3.ZERO
	global_position = _spawn_position
	_set_unarmed_loadout()

	var mesh: MeshInstance3D = get_node_or_null("Mesh") as MeshInstance3D
	if mesh != null:
		mesh.scale = Vector3.ONE

func _tick_cooldowns(delta: float) -> void:
	for key: Variant in _cooldowns.keys():
		_cooldowns[key] = maxf(float(_cooldowns[key]) - delta, 0.0)

func _update_movement(delta: float, speed_multiplier: float = 1.0) -> void:
	var input: Vector2 = _movement_input()
	if input.length_squared() > 0.0:
		last_move_direction = Vector3(input.x, 0.0, input.y).normalized()

	var desired: Vector3 = Vector3(input.x, 0.0, input.y) * move_speed * speed_multiplier
	velocity.x = move_toward(velocity.x, desired.x, acceleration * delta)
	velocity.z = move_toward(velocity.z, desired.z, acceleration * delta)
	velocity.y = 0.0

func _movement_input() -> Vector2:
	return Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")

func _handle_weapon_input() -> void:
	if not Input.is_action_just_pressed(&"interact"):
		return
	if _current_ability != null or _dash_time_left > 0.0 or _stun_left > 0.0 or _dead:
		return

	var pickup: WorldWeaponPickup3D = _nearest_weapon_pickup()
	if pickup != null:
		var profile: WeaponCombatProfile = pickup.get_profile()
		if profile == null:
			return
		if _equipped_item != null:
			drop_equipped_weapon(0.75)
		var item: Item = pickup.take_item()
		if item != null:
			equip_weapon(item, profile)
		return

	if _equipped_item != null:
		drop_equipped_weapon()

func _nearest_weapon_pickup() -> WorldWeaponPickup3D:
	var nearest: WorldWeaponPickup3D = null
	var best_distance_sq: float = interaction_radius * interaction_radius
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
	if profile.basic_ability == null or profile.secondary_ability == null or profile.utility_ability == null:
		return false

	_equipped_item = item
	_equipped_profile = profile
	basic_ability = WeaponItemRules.resolved_ability(profile.basic_ability, item, profile)
	cleave_ability = WeaponItemRules.resolved_ability(profile.secondary_ability, item, profile)
	charge_ability = WeaponItemRules.resolved_ability(profile.utility_ability, item, profile)
	_reset_combat_cooldowns()
	_create_held_weapon_visual()
	return true

func drop_equipped_weapon(drop_distance: float = 1.25) -> void:
	if _equipped_item == null or _equipped_profile == null:
		return

	var item_to_drop: Item = _equipped_item
	var profile_to_drop: WeaponCombatProfile = _equipped_profile
	_set_unarmed_loadout()

	var pickup: WorldWeaponPickup3D = WorldWeaponPickup3D.new()
	pickup.name = "DroppedWeapon"
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
	basic_ability = _unarmed_basic
	cleave_ability = _unarmed_cleave
	charge_ability = _unarmed_charge
	_reset_combat_cooldowns()
	_clear_held_weapon_visual()

func _reset_combat_cooldowns() -> void:
	_cooldowns[&"basic"] = 0.0
	_cooldowns[&"cleave"] = 0.0
	_cooldowns[&"charge"] = 0.0

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

func _handle_combat_input() -> void:
	if _current_ability != null or _dash_time_left > 0.0 or _stun_left > 0.0 or _dead:
		return

	if Input.is_action_pressed(&"basic_attack") and get_cooldown_remaining(&"basic") <= 0.0:
		_start_ability(basic_ability)
		return

	if Input.is_action_just_pressed(&"cleave") and get_cooldown_remaining(&"cleave") <= 0.0:
		_start_ability(cleave_ability)
		return

	if Input.is_action_just_pressed(&"charge") and get_cooldown_remaining(&"charge") <= 0.0:
		_start_ability(charge_ability)
		return

	if Input.is_action_just_pressed(&"dash") and _dash_cooldown_left <= 0.0:
		_start_dash()

func _start_ability(ability: CombatAbility) -> void:
	if ability == null or _dead or _stun_left > 0.0:
		return
	if get_cooldown_remaining(ability.ability_id) > 0.0:
		return

	_current_ability = ability
	_combat_phase = CombatPhase.WINDUP
	_phase_time_left = ability.windup
	_ability_forward = -global_transform.basis.z.normalized()
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

	match _current_ability.ability_id:
		&"basic":
			_pulse_player(Vector3(1.06, 0.94, 1.06), 0.055)
		&"cleave":
			_pulse_player(Vector3(1.14, 0.86, 1.14), 0.075)
		&"charge":
			_pulse_player(Vector3(0.90, 1.02, 1.20), 0.07)

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

func _check_charge_wall_collision() -> void:
	if _current_ability == null:
		return
	if _combat_phase != CombatPhase.ACTIVE or _current_ability.mode != CombatAbility.AbilityMode.CHARGE:
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
			_enter_recovery_phase()
			return

func _start_dash() -> void:
	_dash_cooldown_left = dash_cooldown
	_dash_time_left = dash_duration
	_invulnerable_left = maxf(_invulnerable_left, dash_duration + dash_invulnerability_padding)
	_cancel_current_ability()

	var input: Vector2 = _movement_input()
	if input.length_squared() > 0.0:
		_dash_direction = Vector3(input.x, 0.0, input.y).normalized()
	else:
		_dash_direction = -global_transform.basis.z.normalized()

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

func _on_hit_landed(impact_position: Vector3, hitstop: float) -> void:
	_hitstop_left = maxf(_hitstop_left, hitstop)
	_spawn_impact_fx(impact_position)

func _show_telegraph(ability: CombatAbility) -> void:
	_hide_telegraph()

	var telegraph: MeshInstance3D = MeshInstance3D.new()
	telegraph.name = "AbilityTelegraph"

	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = ability.telegraph_color
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	telegraph.material_override = material

	if ability.telegraph_shape == CombatAbility.TelegraphShape.BOX:
		var box: BoxMesh = BoxMesh.new()
		var length: float = maxf(ability.telegraph_length, ability.range_distance * 2.0)
		box.size = Vector3(ability.radius * 2.0, 0.025, length)
		telegraph.mesh = box
		telegraph.position = Vector3(0.0, -0.88, -length * 0.5)
	else:
		var disc: CylinderMesh = CylinderMesh.new()
		disc.top_radius = ability.radius
		disc.bottom_radius = ability.radius
		disc.height = 0.025
		disc.radial_segments = 48
		telegraph.mesh = disc
		telegraph.position = Vector3(0.0, -0.88, -ability.range_distance)

	add_child(telegraph)
	_telegraph = telegraph

func _hide_telegraph() -> void:
	if _telegraph != null and is_instance_valid(_telegraph):
		_telegraph.queue_free()
	_telegraph = null

func _spawn_impact_fx(world_position: Vector3) -> void:
	var fx: MeshInstance3D = MeshInstance3D.new()
	fx.name = "ImpactFlash"

	var sphere: SphereMesh = SphereMesh.new()
	sphere.radius = 0.16
	sphere.height = 0.32
	fx.mesh = sphere

	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = Color(1.0, 0.82, 0.42, 0.95)
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fx.material_override = material

	var parent_node: Node = get_parent()
	parent_node.add_child(fx)
	fx.global_position = world_position
	fx.scale = Vector3(0.25, 0.25, 0.25)

	var tween: Tween = fx.create_tween()
	tween.tween_property(fx, "scale", Vector3(1.45, 1.45, 1.45), 0.07)
	tween.tween_property(fx, "scale", Vector3(0.0, 0.0, 0.0), 0.08)
	tween.tween_callback(Callable(fx, "queue_free"))

func _pulse_player(target_scale: Vector3, duration: float) -> void:
	var mesh: MeshInstance3D = get_node_or_null("Mesh") as MeshInstance3D
	if mesh == null:
		return
	var tween: Tween = create_tween()
	tween.tween_property(mesh, "scale", target_scale, duration)
	tween.tween_property(mesh, "scale", Vector3.ONE, duration)

func get_cooldown_remaining(ability_id: StringName) -> float:
	return float(_cooldowns.get(ability_id, 0.0))

func get_cooldown_total(ability_id: StringName) -> float:
	match ability_id:
		&"basic":
			return basic_ability.cooldown
		&"cleave":
			return cleave_ability.cooldown
		&"charge":
			return charge_ability.cooldown
	return 0.0

func get_dash_cooldown_remaining() -> float:
	return _dash_cooldown_left

func get_combat_phase_name() -> String:
	if _dead:
		return "DOWN"
	if _stun_left > 0.0:
		return "HITSTUN"
	if is_invulnerable():
		return "DODGE I-FRAMES"
	return str(CombatPhase.keys()[_combat_phase])

func get_health() -> float:
	return health

func get_max_health() -> float:
	return max_health

func get_ability_display_name(ability_id: StringName) -> String:
	match ability_id:
		&"basic":
			return basic_ability.display_name.to_upper()
		&"cleave":
			return cleave_ability.display_name.to_upper()
		&"charge":
			return charge_ability.display_name.to_upper()
	return "ABILITY"

func get_equipped_weapon_name() -> String:
	if _equipped_item == null or _equipped_item.base == null:
		return "UNARMED"
	return "%s %s" % [WeaponItemRules.rarity_name(_equipped_item).to_upper(), _equipped_item.base.name.to_upper()]

func get_weapon_rarity_id() -> StringName:
	if _equipped_item == null:
		return &"common"
	return StringName(WeaponItemRules.rarity_name(_equipped_item).to_lower())

func _update_aim(delta: float) -> void:
	var camera: Camera3D = get_viewport().get_camera_3d()
	if camera == null:
		return

	var mouse: Vector2 = get_viewport().get_mouse_position()
	var ray_origin: Vector3 = camera.project_ray_origin(mouse)
	var ray_end: Vector3 = ray_origin + camera.project_ray_normal(mouse) * 1000.0
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	query.exclude = [self]
	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return

	aim_point = hit.position
	var flat_direction: Vector3 = aim_point - global_position
	flat_direction.y = 0.0
	if flat_direction.length_squared() < 0.0001:
		return

	if _current_ability != null or _stun_left > 0.0 or _dead:
		return

	var target_yaw: float = atan2(-flat_direction.x, -flat_direction.z)
	rotation.y = lerp_angle(rotation.y, target_yaw, clampf(rotation_speed * delta, 0.0, 1.0))

func _ensure_input_actions() -> void:
	_ensure_key_action(&"move_left", KEY_A)
	_ensure_key_action(&"move_right", KEY_D)
	_ensure_key_action(&"move_up", KEY_W)
	_ensure_key_action(&"move_down", KEY_S)
	_ensure_key_action(&"cleave", KEY_Q)
	_ensure_key_action(&"charge", KEY_E)
	_ensure_key_action(&"dash", KEY_SPACE)
	_ensure_key_action(&"interact", KEY_F)
	_ensure_mouse_action(&"basic_attack", MOUSE_BUTTON_LEFT)

func _ensure_key_action(action: StringName, keycode: int) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	if not InputMap.action_get_events(action).is_empty():
		return
	var event: InputEventKey = InputEventKey.new()
	event.keycode = keycode
	InputMap.action_add_event(action, event)

func _ensure_mouse_action(action: StringName, button_index: int) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	if not InputMap.action_get_events(action).is_empty():
		return
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.button_index = button_index
	InputMap.action_add_event(action, event)
