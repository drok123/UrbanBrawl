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

enum CombatPhase {
	READY,
	WINDUP,
	ACTIVE,
	RECOVERY,
}

var jab_ability: CombatAbility = preload("res://resources/abilities/sparring_jab.tres") as CombatAbility
var heavy_ability: CombatAbility = preload("res://resources/abilities/sparring_heavy.tres") as CombatAbility

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

@onready var _target: Node3D = get_node_or_null(target_path) as Node3D
@onready var _mesh: MeshInstance3D = $Mesh
@onready var _health_label: Label3D = $HealthLabel

func _ready() -> void:
	add_to_group("damageable")
	_spawn_position = global_position
	health = max_health
	_cooldowns[jab_ability.ability_id] = 0.0
	_cooldowns[heavy_ability.ability_id] = 0.0
	_setup_hitbox()
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

	_update_facing(delta)

	if _stun_left <= 0.0:
		_advance_combat_state(delta)
		if _current_ability == null:
			_update_decision()

	if _stun_left > 0.0:
		velocity.x = move_toward(velocity.x, 0.0, knockback_drag * delta)
		velocity.z = move_toward(velocity.z, 0.0, knockback_drag * delta)
		velocity.y = 0.0
	elif _current_ability != null:
		var speed_multiplier: float = _current_ability.movement_multiplier
		_update_combat_movement(delta, speed_multiplier)
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

func _tick_cooldowns(delta: float) -> void:
	for key in _cooldowns.keys():
		_cooldowns[key] = maxf(float(_cooldowns[key]) - delta, 0.0)

func _update_decision() -> void:
	if _decision_left > 0.0 or _target == null:
		return

	_decision_left = decision_interval + randf_range(0.0, 0.12)
	var flat_to_target: Vector3 = _target.global_position - global_position
	flat_to_target.y = 0.0
	var distance: float = flat_to_target.length()

	if distance <= 2.35:
		var heavy_ready: bool = get_cooldown_remaining(heavy_ability.ability_id) <= 0.0
		var jab_ready: bool = get_cooldown_remaining(jab_ability.ability_id) <= 0.0

		if heavy_ready and distance <= 2.05 and randf() < 0.30:
			_start_ability(heavy_ability)
			return
		if jab_ready and distance <= 1.95:
			_start_ability(jab_ability)
			return

	if randf() < 0.20:
		_strafe_sign *= -1.0

func _update_facing(delta: float) -> void:
	if _target == null or _current_ability != null or _stun_left > 0.0:
		return

	var direction: Vector3 = _target.global_position - global_position
	direction.y = 0.0
	if direction.length_squared() < 0.001:
		return

	var target_yaw: float = atan2(-direction.x, -direction.z)
	rotation.y = lerp_angle(rotation.y, target_yaw, clampf(rotation_speed * delta, 0.0, 1.0))

func _update_combat_movement(delta: float, speed_multiplier: float) -> void:
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

	if _current_ability != null:
		desired_direction = forward * 0.25
	elif distance > preferred_distance + 0.55:
		desired_direction = (forward + side * 0.18).normalized()
	elif distance < preferred_distance - 0.45:
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
	health = max_health
	velocity = Vector3.ZERO
	global_position = _spawn_position
	if _mesh != null:
		_mesh.scale = Vector3.ONE
	_update_health_label()

func get_cooldown_remaining(ability_id: StringName) -> float:
	return float(_cooldowns.get(ability_id, 0.0))

func _update_health_label() -> void:
	if _health_label == null:
		return
	if _dead:
		_health_label.text = "DOWN\n%d / %d" % [int(health), int(max_health)]
	elif _stun_left > 0.0:
		_health_label.text = "STUNNED %.1fs\n%d / %d" % [_stun_left, int(health), int(max_health)]
	else:
		_health_label.text = "SPARRING BOT\n%d / %d" % [int(health), int(max_health)]
