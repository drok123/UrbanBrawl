extends CharacterBody3D

signal impact(strength: float, point: Vector3)
signal knocked_out(victim, attacker)

const HERO_BRICK := "BRICK"
const HERO_SPRING := "SPRING"
const HERO_VICE := "VICE"

var controlled_by_player := false
var arena_ref: Node
var hero_type := HERO_BRICK
var max_health := 100.0
var health := 100.0
var move_speed := 8.6
var acceleration := 58.0
var facing := Vector3(0.0, 0.0, -1.0)
var spawn_point := Vector3.ZERO

var stun_timer := 0.0
var hitstop_timer := 0.0
var flash_timer := 0.0
var dash_timer := 0.0
var dash_cooldown := 0.0
var ability_timer := 0.0
var ability_cooldown := 0.0
var wall_splat_cooldown := 0.0
var attack_timer := 0.0
var attack_elapsed := 0.0
var attack_fired := false
var attack_kind := ""
var queued_attack := ""
var queued_attack_timer := 0.0
var respawn_timer := 0.0
var eliminated := false
var last_attacker: Node
var last_attacker_timer := 0.0
var stored_charge := 0.0
var vice_boost_ready := false
var ai_think_timer := 0.0
var ai_move := Vector3.ZERO
var ai_strafe_sign := 1.0

var visual_root: Node3D
var body_material: StandardMaterial3D
var accent_material: StandardMaterial3D
var right_arm: MeshInstance3D
var left_arm: MeshInstance3D
var torso: MeshInstance3D
var head: MeshInstance3D
var name_label: Label3D

func _ready() -> void:
	floor_snap_length = 0.25
	_build_collision()
	_build_visual()
	set_hero_type(hero_type)
	health = max_health
	_update_nameplate()
	if controlled_by_player:
		set_process_unhandled_input(true)

func configure(new_hero: String, is_player: bool, owner_arena: Node, at: Vector3) -> void:
	hero_type = new_hero
	controlled_by_player = is_player
	arena_ref = owner_arena
	spawn_point = at
	global_position = at
	if is_inside_tree():
		set_hero_type(hero_type)
		set_process_unhandled_input(controlled_by_player)

func set_hero_type(new_hero: String) -> void:
	hero_type = new_hero.to_upper()
	match hero_type:
		HERO_BRICK:
			max_health = 125.0
			move_speed = 7.7
			_set_palette(Color(0.91, 0.39, 0.19), Color(0.24, 0.08, 0.04))
		HERO_SPRING:
			max_health = 92.0
			move_speed = 10.0
			_set_palette(Color(0.24, 0.82, 0.78), Color(0.03, 0.18, 0.18))
		HERO_VICE:
			max_health = 108.0
			move_speed = 8.3
			_set_palette(Color(0.72, 0.40, 0.92), Color(0.16, 0.06, 0.22))
		_:
			hero_type = HERO_BRICK
			max_health = 125.0
			move_speed = 7.7
			_set_palette(Color(0.91, 0.39, 0.19), Color(0.24, 0.08, 0.04))
	health = min(health, max_health)
	if health <= 0.0:
		health = max_health
	_update_nameplate()

func reset_fighter(at: Vector3) -> void:
	spawn_point = at
	global_position = at
	velocity = Vector3.ZERO
	health = max_health
	stun_timer = 0.0
	hitstop_timer = 0.0
	dash_timer = 0.0
	dash_cooldown = 0.0
	ability_timer = 0.0
	ability_cooldown = 0.0
	wall_splat_cooldown = 0.0
	attack_timer = 0.0
	attack_kind = ""
	queued_attack = ""
	queued_attack_timer = 0.0
	respawn_timer = 0.0
	eliminated = false
	visible = true
	collision_layer = 1
	collision_mask = 1
	last_attacker = null
	last_attacker_timer = 0.0
	stored_charge = 0.0
	vice_boost_ready = false
	_update_nameplate()

func _physics_process(delta: float) -> void:
	_tick_timers(delta)
	if eliminated:
		respawn_timer -= delta
		if respawn_timer <= 0.0 and arena_ref and arena_ref.has_method("respawn_fighter"):
			arena_ref.respawn_fighter(self)
		return

	if global_position.y < -5.0:
		_knock_out(last_attacker)
		return

	if hitstop_timer > 0.0:
		_update_visual(delta)
		return

	if controlled_by_player:
		_update_player_facing()
		_update_player_motion(delta)
	else:
		_update_ai(delta)

	_update_attack(delta)

	if not is_on_floor():
		velocity.y -= 28.0 * delta
	elif velocity.y < 0.0:
		velocity.y = -0.4

	var pre_slide_speed := Vector2(velocity.x, velocity.z).length()
	move_and_slide()
	_check_wall_contacts(pre_slide_speed)
	_update_visual(delta)

func _tick_timers(delta: float) -> void:
	stun_timer = max(0.0, stun_timer - delta)
	hitstop_timer = max(0.0, hitstop_timer - delta)
	flash_timer = max(0.0, flash_timer - delta)
	dash_timer = max(0.0, dash_timer - delta)
	dash_cooldown = max(0.0, dash_cooldown - delta)
	ability_timer = max(0.0, ability_timer - delta)
	ability_cooldown = max(0.0, ability_cooldown - delta)
	wall_splat_cooldown = max(0.0, wall_splat_cooldown - delta)
	last_attacker_timer = max(0.0, last_attacker_timer - delta)
	if last_attacker_timer <= 0.0:
		last_attacker = null
	if queued_attack_timer > 0.0:
		queued_attack_timer -= delta
		if queued_attack_timer <= 0.0:
			queued_attack = ""
	if attack_timer <= 0.0 and queued_attack != "" and stun_timer <= 0.0:
		var queued := queued_attack
		queued_attack = ""
		queued_attack_timer = 0.0
		_start_attack(queued)

func _update_player_motion(delta: float) -> void:
	if stun_timer > 0.0:
		velocity.x = move_toward(velocity.x, 0.0, 10.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 10.0 * delta)
		return
	if dash_timer > 0.0:
		var dash_speed := 19.5 if hero_type != HERO_SPRING else 23.0
		velocity.x = facing.x * dash_speed
		velocity.z = facing.z * dash_speed
		return

	var input_vec := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_A):
		input_vec.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D):
		input_vec.x += 1.0
	if Input.is_physical_key_pressed(KEY_W):
		input_vec.y -= 1.0
	if Input.is_physical_key_pressed(KEY_S):
		input_vec.y += 1.0
	input_vec = input_vec.normalized()
	var desired := Vector3(input_vec.x, 0.0, input_vec.y) * move_speed
	var control_accel := acceleration if Vector2(velocity.x, velocity.z).length() <= move_speed + 1.0 else 18.0
	velocity.x = move_toward(velocity.x, desired.x, control_accel * delta)
	velocity.z = move_toward(velocity.z, desired.z, control_accel * delta)

func _update_player_facing() -> void:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	var mouse := get_viewport().get_mouse_position()
	var ray_origin := camera.project_ray_origin(mouse)
	var ray_direction := camera.project_ray_normal(mouse)
	var plane := Plane(Vector3.UP, global_position.y)
	var hit = plane.intersects_ray(ray_origin, ray_direction)
	if hit == null:
		return
	var look: Vector3 = hit - global_position
	look.y = 0.0
	if look.length_squared() > 0.02:
		facing = look.normalized()

func _update_ai(delta: float) -> void:
	if arena_ref == null or not arena_ref.has_method("get_nearest_enemy"):
		return
	ai_think_timer -= delta
	var target = arena_ref.get_nearest_enemy(self)
	if target == null:
		ai_move = Vector3.ZERO
		return
	var to_target: Vector3 = target.global_position - global_position
	to_target.y = 0.0
	var distance := to_target.length()
	if distance > 0.05:
		facing = to_target.normalized()

	if ai_think_timer <= 0.0:
		ai_think_timer = randf_range(0.08, 0.16)
		if randf() < 0.18:
			ai_strafe_sign *= -1.0
		var side := Vector3(-facing.z, 0.0, facing.x) * ai_strafe_sign
		if distance > 2.25:
			ai_move = (facing + side * 0.18).normalized()
		else:
			ai_move = (side * 0.85 - facing * 0.12).normalized()
		if distance < 1.65:
			var roll := randf()
			if roll < 0.48:
				try_quick()
			elif roll < 0.77:
				try_heavy()
			else:
				try_grab()
		elif distance < 3.8 and randf() < 0.28:
			try_heavy()
		elif distance > 5.2 and dash_cooldown <= 0.0 and randf() < 0.30:
			try_dash()
		if ability_cooldown <= 0.0 and randf() < 0.12:
			try_ability()

	if stun_timer > 0.0:
		velocity.x = move_toward(velocity.x, 0.0, 9.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 9.0 * delta)
	elif dash_timer > 0.0:
		var dash_speed := 19.5 if hero_type != HERO_SPRING else 23.0
		velocity.x = facing.x * dash_speed
		velocity.z = facing.z * dash_speed
	else:
		var desired := ai_move * move_speed * 0.92
		velocity.x = move_toward(velocity.x, desired.x, acceleration * delta)
		velocity.z = move_toward(velocity.z, desired.z, acceleration * delta)

func _unhandled_input(event: InputEvent) -> void:
	if not controlled_by_player or eliminated:
		return
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			try_quick()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			try_heavy()
	elif event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_J:
				try_quick()
			KEY_K:
				try_heavy()
			KEY_F, KEY_L:
				try_grab()
			KEY_SPACE:
				try_dash()
			KEY_E:
				try_ability()

func try_quick() -> void:
	_queue_or_start("quick")

func try_heavy() -> void:
	_queue_or_start("heavy")

func try_grab() -> void:
	_queue_or_start("grab")

func _queue_or_start(kind: String) -> void:
	if eliminated:
		return
	if stun_timer > 0.0 or attack_timer > 0.0:
		queued_attack = kind
		queued_attack_timer = 0.14
		return
	_start_attack(kind)

func _start_attack(kind: String) -> void:
	attack_kind = kind
	attack_elapsed = 0.0
	attack_fired = false
	match kind:
		"quick":
			attack_timer = 0.16
		"heavy":
			attack_timer = 0.31
		"grab":
			attack_timer = 0.23

func _update_attack(delta: float) -> void:
	if attack_timer <= 0.0:
		return
	attack_timer = max(0.0, attack_timer - delta)
	attack_elapsed += delta
	var fire_at := 0.035
	if attack_kind == "heavy":
		fire_at = 0.085
	elif attack_kind == "grab":
		fire_at = 0.045
	if not attack_fired and attack_elapsed >= fire_at:
		attack_fired = true
		_perform_attack(attack_kind)
	if attack_timer <= 0.0:
		attack_kind = ""

func _perform_attack(kind: String) -> void:
	if arena_ref == null or not arena_ref.has_method("get_opponents"):
		return
	var range := 1.65
	var damage := 8.0
	var force := 6.8
	var stun := 0.13
	var launch := 0.0
	var arc_dot := 0.42
	match kind:
		"quick":
			range = 1.72
			damage = 8.0
			force = 6.2
			stun = 0.13
			arc_dot = 0.30
		"heavy":
			range = 1.95
			damage = 16.0
			force = 11.5
			stun = 0.29
			launch = 1.4
			arc_dot = 0.18
			if hero_type == HERO_BRICK:
				force *= 1.12 + stored_charge * 0.55
				damage *= 1.08 + stored_charge * 0.22
				stored_charge = 0.0
		"grab":
			range = 1.58
			damage = 5.0
			force = 10.0
			stun = 0.34
			launch = 0.8
			arc_dot = 0.35
			if hero_type == HERO_VICE:
				range = 1.92 if not vice_boost_ready else 2.55
				force = 14.5 if not vice_boost_ready else 19.0
				damage = 7.0 if not vice_boost_ready else 10.0
				vice_boost_ready = false

	var hit_any := false
	var best_grab_target: Node = null
	var best_distance := INF
	for target in arena_ref.get_opponents(self):
		if target == null or target.eliminated:
			continue
		var delta_pos: Vector3 = target.global_position - global_position
		delta_pos.y = 0.0
		var distance := delta_pos.length()
		if distance > range or distance <= 0.01:
			continue
		var direction := delta_pos / distance
		if facing.dot(direction) < arc_dot:
			continue
		if kind == "grab":
			if distance < best_distance:
				best_distance = distance
				best_grab_target = target
			continue
		target.receive_hit(self, damage, direction * force, stun, launch, kind)
		hit_any = true

	if kind == "grab" and best_grab_target != null:
		var throw_dir := facing.normalized()
		best_grab_target.receive_hit(self, damage, throw_dir * force, stun, launch, "grab")
		hit_any = true

	if hit_any:
		hitstop_timer = 0.035 if kind == "quick" else 0.055
		impact.emit(0.75 if kind == "quick" else 1.15, global_position + facing)

func try_dash() -> void:
	if eliminated or stun_timer > 0.0 or dash_cooldown > 0.0:
		return
	attack_timer = 0.0
	attack_kind = ""
	queued_attack = ""
	dash_timer = 0.14 if hero_type != HERO_SPRING else 0.18
	dash_cooldown = 0.48 if hero_type != HERO_SPRING else 0.31
	velocity.x = facing.x * (19.5 if hero_type != HERO_SPRING else 23.0)
	velocity.z = facing.z * (19.5 if hero_type != HERO_SPRING else 23.0)

func try_ability() -> void:
	if eliminated or stun_timer > 0.0 or ability_cooldown > 0.0:
		return
	match hero_type:
		HERO_BRICK:
			ability_timer = 0.58
			ability_cooldown = 0.85
		HERO_SPRING:
			ability_timer = 0.24
			ability_cooldown = 0.56
			dash_timer = 0.24
			dash_cooldown = 0.0
			velocity.x = facing.x * 25.0
			velocity.z = facing.z * 25.0
		HERO_VICE:
			ability_timer = 0.8
			ability_cooldown = 0.70
			vice_boost_ready = true

func receive_hit(attacker: Node, damage: float, force: Vector3, stun: float, launch: float, kind: String) -> void:
	if eliminated:
		return
	last_attacker = attacker
	last_attacker_timer = 4.0
	var damage_scale := 1.0
	var force_scale := 1.0
	if hero_type == HERO_BRICK and ability_timer > 0.0:
		damage_scale = 0.38
		force_scale = 0.14
		stored_charge = clamp(stored_charge + force.length() / 14.0, 0.0, 1.0)
		ability_timer = 0.0
	health -= damage * damage_scale
	velocity.x += force.x * force_scale
	velocity.z += force.z * force_scale
	velocity.y = max(velocity.y, launch * force_scale)
	stun_timer = max(stun_timer, stun * max(0.45, force_scale))
	hitstop_timer = max(hitstop_timer, 0.025 if kind == "quick" else 0.045)
	flash_timer = 0.10
	impact.emit(0.58 if kind == "quick" else 1.0, global_position)
	_update_nameplate()
	if health <= 0.0:
		_knock_out(attacker)

func _check_wall_contacts(pre_slide_speed: float) -> void:
	for i in range(get_slide_collision_count()):
		var collision := get_slide_collision(i)
		var normal := collision.get_normal()
		if abs(normal.y) > 0.45:
			continue
		if hero_type == HERO_SPRING and dash_timer > 0.0:
			dash_cooldown = 0.0
			velocity = velocity.bounce(normal) * 0.92
			facing = Vector3(velocity.x, 0.0, velocity.z).normalized()
			impact.emit(0.55, global_position)
		if stun_timer > 0.0 and wall_splat_cooldown <= 0.0 and pre_slide_speed >= 7.5:
			_wall_splat(normal)
			break

func _wall_splat(normal: Vector3) -> void:
	wall_splat_cooldown = 0.40
	health -= 7.0
	stun_timer = max(stun_timer, 0.24)
	hitstop_timer = max(hitstop_timer, 0.055)
	flash_timer = 0.12
	velocity = velocity.bounce(normal) * 0.28
	velocity.y = max(velocity.y, 1.1)
	impact.emit(1.35, global_position)
	_update_nameplate()
	if health <= 0.0:
		_knock_out(last_attacker)

func _knock_out(attacker: Node) -> void:
	if eliminated:
		return
	eliminated = true
	visible = false
	collision_layer = 0
	collision_mask = 0
	velocity = Vector3.ZERO
	respawn_timer = 1.25
	knocked_out.emit(self, attacker)

func _build_collision() -> void:
	if get_node_or_null("Collision") != null:
		return
	var collision := CollisionShape3D.new()
	collision.name = "Collision"
	var shape := CapsuleShape3D.new()
	shape.radius = 0.43
	shape.height = 1.85
	collision.shape = shape
	add_child(collision)

func _build_visual() -> void:
	visual_root = Node3D.new()
	visual_root.name = "Visual"
	add_child(visual_root)
	body_material = StandardMaterial3D.new()
	body_material.roughness = 0.78
	accent_material = StandardMaterial3D.new()
	accent_material.roughness = 0.72

	torso = _make_box(Vector3(0.0, 0.28, 0.0), Vector3(0.74, 0.82, 0.42), body_material)
	_make_box(Vector3(0.0, -0.18, 0.0), Vector3(0.62, 0.26, 0.36), accent_material)
	head = _make_sphere(Vector3(0.0, 0.93, -0.02), Vector3(0.42, 0.46, 0.42), body_material)
	left_arm = _make_box(Vector3(-0.56, 0.28, 0.0), Vector3(0.22, 0.72, 0.22), body_material)
	right_arm = _make_box(Vector3(0.56, 0.28, 0.0), Vector3(0.22, 0.72, 0.22), body_material)
	_make_box(Vector3(-0.22, -0.67, 0.0), Vector3(0.27, 0.74, 0.29), body_material)
	_make_box(Vector3(0.22, -0.67, 0.0), Vector3(0.27, 0.74, 0.29), body_material)
	_make_box(Vector3(0.0, 0.35, -0.24), Vector3(0.28, 0.16, 0.08), accent_material)

	name_label = Label3D.new()
	name_label.position = Vector3(0.0, 1.55, 0.0)
	name_label.font_size = 42
	name_label.outline_size = 10
	name_label.pixel_size = 0.0075
	name_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(name_label)

func _make_box(at: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = material
	var instance := MeshInstance3D.new()
	instance.position = at
	instance.mesh = mesh
	visual_root.add_child(instance)
	return instance

func _make_sphere(at: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	mesh.material = material
	var instance := MeshInstance3D.new()
	instance.position = at
	instance.scale = size
	instance.mesh = mesh
	visual_root.add_child(instance)
	return instance

func _set_palette(body: Color, accent: Color) -> void:
	if body_material:
		body_material.albedo_color = body
	if accent_material:
		accent_material.albedo_color = accent

func _update_visual(delta: float) -> void:
	if visual_root == null:
		return
	var target_yaw := atan2(-facing.x, -facing.z)
	visual_root.rotation.y = lerp_angle(visual_root.rotation.y, target_yaw, min(1.0, delta * 20.0))
	var speed_ratio: float = clampf(Vector2(velocity.x, velocity.z).length() / maxf(0.01, move_speed), 0.0, 1.5)
	var t := Time.get_ticks_msec() * 0.001
	visual_root.position.y = sin(t * 9.0) * 0.025 * speed_ratio
	right_arm.position.z = lerp(right_arm.position.z, 0.0, min(1.0, delta * 22.0))
	left_arm.position.z = lerp(left_arm.position.z, 0.0, min(1.0, delta * 22.0))
	torso.rotation.z = lerp(torso.rotation.z, 0.0, min(1.0, delta * 16.0))
	if attack_kind == "quick":
		right_arm.position.z = -0.38
		torso.rotation.z = -0.08
	elif attack_kind == "heavy":
		right_arm.position.z = -0.28
		left_arm.position.z = -0.22
		torso.rotation.z = -0.15
	elif attack_kind == "grab":
		right_arm.position.z = -0.28
		left_arm.position.z = -0.28
	if dash_timer > 0.0:
		visual_root.rotation.x = lerp(visual_root.rotation.x, -0.20, min(1.0, delta * 24.0))
	else:
		visual_root.rotation.x = lerp(visual_root.rotation.x, 0.0, min(1.0, delta * 18.0))
	if flash_timer > 0.0:
		body_material.emission_enabled = true
		body_material.emission = Color(1.0, 0.92, 0.78)
		body_material.emission_energy_multiplier = 1.5
	else:
		body_material.emission_enabled = false

func _update_nameplate() -> void:
	if name_label == null:
		return
	var prefix := "YOU · " if controlled_by_player else ""
	name_label.text = "%s%s\n%d / %d" % [prefix, hero_type, int(ceil(max(0.0, health))), int(max_health)]
