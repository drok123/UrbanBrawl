class_name BeatCop3D
extends CharacterBody3D

@export var target_path: NodePath = NodePath("../Player")
@export var max_health: float = 420.0
@export var move_speed: float = 5.8
@export var acceleration: float = 24.0
@export var rotation_speed: float = 12.0
@export var observation_radius: float = 12.0
@export var response_seconds: float = 32.0
@export var arrest_distance: float = 2.1
@export var respawn_delay: float = 7.0
@export var hitstun_duration: float = 0.14
@export var knockback_drag: float = 17.0

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

var _current_ability: CombatAbility = null
var _combat_phase: CombatPhase = CombatPhase.READY
var _phase_time_left: float = 0.0
var _cooldowns: Dictionary = {}
var _ability_forward: Vector3 = Vector3.FORWARD

var _hitbox: MeleeHitbox3D = null
var _behavior_tree: BeehaveTree = null
var _target: Node3D = null
var _active_crime_event: Dictionary = {}
var _engaged: bool = false
var _response_left: float = 0.0
var _bust_processed: bool = false
var _last_hit_source: Node3D = null

var _move_enabled: bool = false
var _move_target: Vector3 = Vector3.ZERO
var _patrol_index: int = 0
var _patrol_points: Array[Vector3] = []

var _status_message: String = ""
var _status_left: float = 0.0

@onready var _mesh: MeshInstance3D = $Mesh
@onready var _health_label: Label3D = $HealthLabel

func _ready() -> void:
	add_to_group("damageable")
	add_to_group("police_actor")
	_spawn_position = global_position
	health = max_health
	_target = get_node_or_null(target_path) as Node3D
	_patrol_points = [
		_spawn_position + Vector3(-4.8, 0.0, 2.8),
		_spawn_position + Vector3(4.2, 0.0, 2.4),
		_spawn_position + Vector3(4.5, 0.0, -4.2),
		_spawn_position + Vector3(-4.0, 0.0, -4.6),
	]
	_reset_cooldowns()
	_setup_hitbox()
	_setup_behavior_tree()
	_create_baton_visual()
	if not GameSession.crime_committed.is_connected(_on_crime_committed):
		GameSession.crime_committed.connect(_on_crime_committed)
	_update_label()

func _exit_tree() -> void:
	if GameSession.crime_committed.is_connected(_on_crime_committed):
		GameSession.crime_committed.disconnect(_on_crime_committed)

func _physics_process(delta: float) -> void:
	_status_left = maxf(_status_left - delta, 0.0)
	if _status_left <= 0.0:
		_status_message = ""

	if _dead:
		_respawn_left = maxf(_respawn_left - delta, 0.0)
		velocity = Vector3.ZERO
		if _respawn_left <= 0.0:
			_reset_after_death()
		_update_label()
		return

	if _hitstop_left > 0.0:
		_hitstop_left = maxf(_hitstop_left - delta, 0.0)
		return

	_tick_cooldowns(delta)
	_stun_left = maxf(_stun_left - delta, 0.0)
	_response_left = maxf(_response_left - delta, 0.0)

	if _engaged and _response_left <= 0.0 and not _is_target_down():
		_clear_response("LOST SUSPECT")

	if _stun_left <= 0.0:
		_advance_combat_state(delta)
		_move_enabled = false
		if _current_ability == null and _behavior_tree != null:
			_behavior_tree.tick()

	if _stun_left > 0.0:
		velocity.x = move_toward(velocity.x, 0.0, knockback_drag * delta)
		velocity.z = move_toward(velocity.z, 0.0, knockback_drag * delta)
		velocity.y = 0.0
	else:
		_update_motion(delta)

	move_and_slide()
	_try_bust()
	_update_label()

func _setup_behavior_tree() -> void:
	var tree: BeehaveTree = BeehaveTree.new()
	tree.name = "BeatCopBehaviorTree"
	tree.process_thread = BeehaveTree.ProcessThread.MANUAL
	add_child(tree)

	var selector: SelectorComposite = SelectorComposite.new()
	selector.name = "RespondOrPatrol"
	tree.add_child(selector)

	var respond: PoliceRespondCrimeAction = PoliceRespondCrimeAction.new()
	respond.name = "RespondToCrime"
	selector.add_child(respond)

	var patrol: PolicePatrolAction = PolicePatrolAction.new()
	patrol.name = "Patrol"
	selector.add_child(patrol)

	_behavior_tree = tree

func ai_respond_to_crime() -> bool:
	if not _engaged or _target == null or not is_instance_valid(_target):
		return false
	if _dead:
		return false

	_move_enabled = true
	_move_target = _target.global_position

	if _is_target_down():
		return true
	if _current_ability != null or _stun_left > 0.0:
		return true

	var distance: float = global_position.distance_to(_target.global_position)
	if heavy_ability != null and distance <= heavy_ability.range_distance + heavy_ability.radius * 0.75:
		if get_cooldown_remaining(heavy_ability.ability_id) <= 0.0 and randf() < 0.32:
			_start_ability(heavy_ability)
			return true
	if jab_ability != null and distance <= jab_ability.range_distance + jab_ability.radius * 0.78:
		if get_cooldown_remaining(jab_ability.ability_id) <= 0.0:
			_start_ability(jab_ability)
	return true

func ai_patrol() -> bool:
	if _dead or _engaged or _patrol_points.is_empty():
		return false
	var point: Vector3 = _patrol_points[_patrol_index]
	if global_position.distance_squared_to(point) <= 0.8 * 0.8:
		_patrol_index = (_patrol_index + 1) % _patrol_points.size()
		point = _patrol_points[_patrol_index]
	_move_enabled = true
	_move_target = point
	return true

func _on_crime_committed(event: Dictionary) -> void:
	if _dead:
		return
	if int(event.get("territory", GameSession.Territory.NEUTRAL)) != GameSession.Territory.POLICE:
		return
	var position_value: Variant = event.get("position", global_position)
	if not position_value is Vector3:
		return
	var event_position: Vector3 = position_value as Vector3
	if global_position.distance_squared_to(event_position) > observation_radius * observation_radius:
		return
	_activate_response(event, "CRIME OBSERVED")

func _activate_response(event: Dictionary, message: String) -> void:
	_active_crime_event = event.duplicate(true)
	_engaged = true
	_response_left = response_seconds
	_bust_processed = false
	_flash_status(message)

func _clear_response(message: String = "") -> void:
	_engaged = false
	_response_left = 0.0
	_active_crime_event = {}
	_bust_processed = false
	if not message.is_empty():
		_flash_status(message)

func receive_hit(hit: CombatHit) -> void:
	if hit == null or _dead:
		return

	_last_hit_source = hit.source
	if hit.source == _target:
		var assault_event: Dictionary = {}
		if GameSession.get_flag_state() != GameSession.FlagState.CRIMINAL:
			assault_event = GameSession.commit_crime(
				&"assault_police",
				_target.global_position,
				12,
				8,
				45.0,
				{"street_value": 0, "direct_observation": true}
			)
		elif not GameSession.last_crime_event.is_empty():
			assault_event = GameSession.last_crime_event.duplicate(true)
		if not assault_event.is_empty():
			_activate_response(assault_event, "OFFICER ATTACKED")

	health = maxf(health - hit.damage, 0.0)
	velocity += Vector3(hit.impulse.x, 0.0, hit.impulse.z)
	_hitstop_left = maxf(_hitstop_left, hit.hitstop)
	_stun_left = maxf(_stun_left, hitstun_duration)
	_cancel_current_ability()

	if health <= 0.0:
		_die()

func _die() -> void:
	_dead = true
	_respawn_left = respawn_delay
	velocity = Vector3.ZERO
	_cancel_current_ability()
	if _last_hit_source == _target and _target != null:
		GameSession.commit_crime(
			&"officer_down",
			_target.global_position,
			18,
			12,
			60.0,
			{"street_value": 0, "direct_observation": true}
		)
	_clear_response()
	_flash_status("OFFICER DOWN")

func _reset_after_death() -> void:
	_dead = false
	_respawn_left = 0.0
	_stun_left = 0.0
	_hitstop_left = 0.0
	health = max_health
	velocity = Vector3.ZERO
	global_position = _spawn_position
	_last_hit_source = null
	_reset_cooldowns()
	_clear_response()
	_flash_status("BACK ON PATROL")

func _try_bust() -> void:
	if GameSession.is_arrest_pending():
		return
	if not _engaged or _bust_processed or _target == null:
		return
	if not _is_target_down():
		return
	if global_position.distance_to(_target.global_position) > arrest_distance:
		return

	_bust_processed = true
	var seized_units: int = GameSession.seize_contraband(6)
	var seized_weapon: String = _seize_nearby_weapon()
	var package: Dictionary = GameSession.create_evidence_package(_active_crime_event, seized_units, seized_weapon)
	GameSession.register_bust()
	GameSession.queue_arrest_return(0.65, 100)
	var case_value: int = int(package.get("case_value", 0)) if not package.is_empty() else 0
	_flash_status("ARREST  +%d CASE  SEIZED %d" % [case_value, seized_units])
	_engaged = false
	_response_left = 0.0
	_active_crime_event = {}

func _seize_nearby_weapon() -> String:
	if _target == null:
		return ""
	var best: WorldWeaponPickup3D = null
	var best_distance_sq: float = 2.6 * 2.6
	for node: Node in get_tree().get_nodes_in_group("weapon_pickup"):
		var pickup: WorldWeaponPickup3D = node as WorldWeaponPickup3D
		if pickup == null or not pickup.is_available():
			continue
		var distance_sq: float = _target.global_position.distance_squared_to(pickup.global_position)
		if distance_sq <= best_distance_sq:
			best_distance_sq = distance_sq
			best = pickup
	if best == null:
		return ""
	var item: Item = best.get_item()
	var weapon_name: String = "WEAPON"
	if item != null and item.base != null:
		weapon_name = "%s %s" % [WeaponItemRules.rarity_name(item).to_upper(), item.base.name.to_upper()]
	best.take_item()
	return weapon_name

func _is_target_down() -> bool:
	if _target == null or not _target.has_method("get_combat_phase_name"):
		return false
	return str(_target.call("get_combat_phase_name")) == "DOWN"

func _update_motion(delta: float) -> void:
	if not _move_enabled:
		velocity.x = move_toward(velocity.x, 0.0, acceleration * delta)
		velocity.z = move_toward(velocity.z, 0.0, acceleration * delta)
		velocity.y = 0.0
		return

	var to_target: Vector3 = _move_target - global_position
	to_target.y = 0.0
	if to_target.length_squared() < 0.01:
		velocity.x = move_toward(velocity.x, 0.0, acceleration * delta)
		velocity.z = move_toward(velocity.z, 0.0, acceleration * delta)
		return

	var direction: Vector3 = to_target.normalized()
	var movement_scale: float = 0.32 if _current_ability != null else 1.0
	var desired: Vector3 = direction * move_speed * movement_scale
	velocity.x = move_toward(velocity.x, desired.x, acceleration * delta)
	velocity.z = move_toward(velocity.z, desired.z, acceleration * delta)
	velocity.y = 0.0

	if _current_ability == null and _stun_left <= 0.0:
		var target_yaw: float = atan2(-direction.x, -direction.z)
		rotation.y = lerp_angle(rotation.y, target_yaw, clampf(rotation_speed * delta, 0.0, 1.0))

func _start_ability(ability: CombatAbility) -> void:
	if ability == null or _dead or _stun_left > 0.0 or _target == null:
		return
	if get_cooldown_remaining(ability.ability_id) > 0.0:
		return
	var direction: Vector3 = _target.global_position - global_position
	direction.y = 0.0
	if direction.length_squared() < 0.001:
		return
	_ability_forward = direction.normalized()
	rotation.y = atan2(-_ability_forward.x, -_ability_forward.z)
	_current_ability = ability
	_combat_phase = CombatPhase.WINDUP
	_phase_time_left = ability.windup
	_cooldowns[ability.ability_id] = ability.cooldown

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
	_hitbox.activate(_current_ability, self)

func _enter_recovery_phase() -> void:
	if _current_ability == null:
		return
	_hitbox.deactivate()
	_combat_phase = CombatPhase.RECOVERY
	_phase_time_left = _current_ability.recovery

func _finish_ability() -> void:
	_hitbox.deactivate()
	_current_ability = null
	_combat_phase = CombatPhase.READY
	_phase_time_left = 0.0

func _cancel_current_ability() -> void:
	if _hitbox != null:
		_hitbox.deactivate()
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

func _reset_cooldowns() -> void:
	_cooldowns.clear()
	if jab_ability != null:
		_cooldowns[jab_ability.ability_id] = 0.0
	if heavy_ability != null:
		_cooldowns[heavy_ability.ability_id] = 0.0

func _tick_cooldowns(delta: float) -> void:
	for key: Variant in _cooldowns.keys():
		_cooldowns[key] = maxf(float(_cooldowns[key]) - delta, 0.0)

func get_cooldown_remaining(ability_id: StringName) -> float:
	return float(_cooldowns.get(ability_id, 0.0))

func get_combat_phase_name() -> String:
	if _dead:
		return "DOWN"
	if _stun_left > 0.0:
		return "HITSTUN"
	return str(CombatPhase.keys()[_combat_phase])

func get_equipped_weapon_name() -> String:
	return "POLICE BATON"

func get_weapon_rarity_id() -> StringName:
	return &"common"

func _create_baton_visual() -> void:
	var root: Node3D = Node3D.new()
	root.name = "HeldWeapon"
	root.position = Vector3(0.46, 0.28, -0.38)
	root.rotation_degrees = Vector3(0.0, 0.0, -28.0)
	add_child(root)
	var mesh_instance: MeshInstance3D = MeshInstance3D.new()
	var cylinder: CylinderMesh = CylinderMesh.new()
	cylinder.top_radius = 0.055
	cylinder.bottom_radius = 0.065
	cylinder.height = 0.9
	cylinder.radial_segments = 10
	mesh_instance.mesh = cylinder
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = Color(0.08, 0.09, 0.11, 1.0)
	material.roughness = 0.72
	mesh_instance.material_override = material
	root.add_child(mesh_instance)

func _flash_status(value: String) -> void:
	_status_message = value
	_status_left = 2.2

func _update_label() -> void:
	if _health_label == null:
		return
	if not _status_message.is_empty():
		_health_label.text = "BEAT COP\n%s\n%d / %d" % [_status_message, int(health), int(max_health)]
	elif _dead:
		_health_label.text = "BEAT COP — DOWN\n%d / %d" % [int(health), int(max_health)]
	elif _engaged:
		_health_label.text = "BEAT COP — RESPONDING\n%d / %d" % [int(health), int(max_health)]
	else:
		_health_label.text = "BEAT COP — PATROL\n%d / %d" % [int(health), int(max_health)]
