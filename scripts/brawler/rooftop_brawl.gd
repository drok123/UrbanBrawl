extends Node3D

const Fighter = preload("res://scripts/brawler/brawler_fighter.gd")

var fighters: Array = []
var player
var spawn_points := [Vector3(0.0, 1.05, 4.8), Vector3(-6.2, 1.05, -3.4), Vector3(6.2, 1.05, -3.4)]
var camera: Camera3D
var camera_center := Vector3.ZERO
var camera_shake := 0.0
var hud_hero: Label
var hud_health: ProgressBar
var hud_score: Label
var hud_banner: Label
var hud_banner_timer := 0.0
var scores := {}

func _ready() -> void:
	randomize()
	_build_environment()
	_build_rooftop()
	_build_camera()
	_build_hud()
	_spawn_fighters()

func _process(delta: float) -> void:
	_update_camera(delta)
	_update_hud(delta)

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo): return
	match event.physical_keycode:
		KEY_1: _switch_player_hero(Fighter.HERO_BRICK)
		KEY_2: _switch_player_hero(Fighter.HERO_SPRING)
		KEY_3: _switch_player_hero(Fighter.HERO_VICE)
		KEY_R: _reset_brawl()

func _spawn_fighters() -> void:
	player = _spawn_fighter("Player", Fighter.HERO_BRICK, true, spawn_points[0])
	_spawn_fighter("SpringBot", Fighter.HERO_SPRING, false, spawn_points[1])
	_spawn_fighter("ViceBot", Fighter.HERO_VICE, false, spawn_points[2])
	_show_banner("FIGHT", 0.85)

func _spawn_fighter(node_name: String, hero: String, is_player: bool, at: Vector3):
	var fighter = Fighter.new()
	fighter.name = node_name
	fighter.hero_type = hero
	fighter.controlled_by_player = is_player
	fighter.arena_ref = self
	fighter.spawn_point = at
	fighter.position = at
	add_child(fighter)
	fighter.impact.connect(_on_impact)
	fighter.knocked_out.connect(_on_knocked_out)
	fighters.append(fighter)
	scores[fighter] = 0
	return fighter

func get_opponents(source) -> Array:
	var result: Array = []
	for fighter in fighters:
		if fighter != source and not fighter.eliminated: result.append(fighter)
	return result

func get_nearest_enemy(source):
	var nearest = null
	var nearest_distance := INF
	for fighter in fighters:
		if fighter == source or fighter.eliminated: continue
		var distance := source.global_position.distance_squared_to(fighter.global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest = fighter
	return nearest

func respawn_fighter(fighter) -> void:
	var index := fighters.find(fighter)
	if index >= 0: fighter.reset_fighter(spawn_points[index % spawn_points.size()])

func _on_impact(strength: float, _point: Vector3) -> void:
	camera_shake = max(camera_shake, strength)

func _on_knocked_out(victim, attacker) -> void:
	if attacker != null and scores.has(attacker):
		scores[attacker] += 1
		_show_banner("%s K.O." % attacker.hero_type, 0.9)
	else: _show_banner("RING OUT", 0.9)
	camera_shake = max(camera_shake, 1.8)

func _switch_player_hero(hero: String) -> void:
	if player == null: return
	var ratio := player.health / max(1.0, player.max_health)
	player.set_hero_type(hero)
	player.health = player.max_health * ratio
	player._update_nameplate()
	_show_banner(hero, 0.55)

func _reset_brawl() -> void:
	for i in range(fighters.size()):
		var fighter = fighters[i]
		scores[fighter] = 0
		fighter.reset_fighter(spawn_points[i % spawn_points.size()])
	_show_banner("RESET", 0.55)

func _build_environment() -> void:
	var world_env := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.035, 0.045, 0.065)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.38, 0.45, 0.58)
	env.ambient_light_energy = 0.82
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world_env.environment = env
	add_child(world_env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-56.0, -34.0, 0.0)
	sun.light_color = Color(1.0, 0.82, 0.68)
	sun.light_energy = 1.35
	sun.shadow_enabled = true
	add_child(sun)
	var fill := OmniLight3D.new()
	fill.position = Vector3(0.0, 7.0, 1.5)
	fill.light_color = Color(0.34, 0.50, 1.0)
	fill.light_energy = 4.0
	fill.omni_range = 22.0
	add_child(fill)

func _build_rooftop() -> void:
	_add_box_body("Roof", Vector3(0,-0.25,0), Vector3(24,0.5,16), Color(0.10,0.115,0.14))
	_add_box_visual(Vector3(0,0.01,0), Vector3(23,0.025,0.10), Color(0.85,0.25,0.13))
	var parapet := Color(0.22,0.24,0.28)
	_add_box_body("NorthA", Vector3(-8.75,0.45,-8), Vector3(6.5,0.9,0.35), parapet)
	_add_box_body("NorthB", Vector3(0,0.45,-8), Vector3(6,0.9,0.35), parapet)
	_add_box_body("NorthC", Vector3(8.75,0.45,-8), Vector3(6.5,0.9,0.35), parapet)
	_add_box_body("SouthA", Vector3(-7.5,0.45,8), Vector3(9,0.9,0.35), parapet)
	_add_box_body("SouthB", Vector3(7.5,0.45,8), Vector3(9,0.9,0.35), parapet)
	_add_box_body("WestA", Vector3(-12,0.45,-5.1), Vector3(0.35,0.9,5.8), parapet)
	_add_box_body("WestB", Vector3(-12,0.45,5.1), Vector3(0.35,0.9,5.8), parapet)
	_add_box_body("EastA", Vector3(12,0.45,-5.1), Vector3(0.35,0.9,5.8), parapet)
	_add_box_body("EastB", Vector3(12,0.45,5.1), Vector3(0.35,0.9,5.8), parapet)
	_add_box_body("HVAC_A", Vector3(-4.3,0.55,-0.8), Vector3(2.7,1.1,2.0), Color(0.32,0.36,0.39))
	_add_box_body("HVAC_B", Vector3(4.6,0.42,1.8), Vector3(2.2,0.84,1.6), Color(0.27,0.31,0.34))
	_add_box_body("Skylight", Vector3(0,0.24,-2.4), Vector3(3.4,0.48,1.9), Color(0.12,0.33,0.42))
	_add_box_visual(Vector3(0,0.50,-2.4), Vector3(3.0,0.035,1.5), Color(0.17,0.72,0.78))
	_add_box_body("BillboardPostL", Vector3(-3.5,1.9,-6.55), Vector3(0.25,3.8,0.25), Color(0.16,0.17,0.20))
	_add_box_body("BillboardPostR", Vector3(3.5,1.9,-6.55), Vector3(0.25,3.8,0.25), Color(0.16,0.17,0.20))
	var board := _add_box_body("Billboard", Vector3(0,3.25,-6.55), Vector3(7.6,2.35,0.28), Color(0.70,0.16,0.10))
	var sign := Label3D.new()
	sign.position = Vector3(0,0,0.17)
	sign.text = "URBAN BRAWL"
	sign.font_size = 82
	sign.outline_size = 14
	sign.pixel_size = 0.008
	board.add_child(sign)
	_add_box_body("TankBase", Vector3(-9,1.1,-5), Vector3(2.6,2.2,2.6), Color(0.25,0.29,0.34))
	var tank := MeshInstance3D.new()
	var tank_mesh := CylinderMesh.new()
	tank_mesh.top_radius = 1.65; tank_mesh.bottom_radius = 1.8; tank_mesh.height = 1.7
	var tank_mat := StandardMaterial3D.new(); tank_mat.albedo_color = Color(0.34,0.20,0.16); tank_mat.roughness = 0.92
	tank_mesh.material = tank_mat; tank.mesh = tank_mesh; tank.position = Vector3(-9,3,-5); add_child(tank)

func _build_camera() -> void:
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 20.0
	camera.position = Vector3(0,15.5,16.5)
	add_child(camera)
	camera.current = true
	camera.look_at(Vector3.ZERO, Vector3.UP)

func _update_camera(delta: float) -> void:
	if camera == null or fighters.is_empty(): return
	var active: Array = []
	for fighter in fighters:
		if not fighter.eliminated: active.append(fighter)
	if active.is_empty(): return
	var center := Vector3.ZERO
	for fighter in active: center += fighter.global_position
	center /= float(active.size()); center.y = 0
	camera_center = camera_center.lerp(center, min(1.0, delta * 3.8))
	var radius := 0.0
	for fighter in active: radius = max(radius, Vector2(fighter.global_position.x-center.x, fighter.global_position.z-center.z).length())
	camera.size = lerp(camera.size, clamp(16.5 + radius * 1.15, 18.0, 25.0), min(1.0, delta * 3.0))
	camera_shake = move_toward(camera_shake, 0.0, delta * 4.8)
	var shake := Vector3(randf_range(-1,1), randf_range(-0.45,0.45), randf_range(-1,1)) * camera_shake * 0.08
	camera.position = camera_center + Vector3(0,15.5,16.5) + shake
	camera.look_at(camera_center + Vector3(0,0.45,0), Vector3.UP)

func _build_hud() -> void:
	var layer := CanvasLayer.new(); add_child(layer)
	var plate := ColorRect.new(); plate.position = Vector2(20,18); plate.size = Vector2(440,142); plate.color = Color(0.025,0.03,0.045,0.82); layer.add_child(plate)
	var title := Label.new(); title.position = Vector2(38,30); title.text = "URBAN BRAWL · ROOFTOP 07"; title.add_theme_font_size_override("font_size",28); layer.add_child(title)
	hud_hero = Label.new(); hud_hero.position = Vector2(38,70); hud_hero.add_theme_font_size_override("font_size",22); layer.add_child(hud_hero)
	hud_health = ProgressBar.new(); hud_health.position = Vector2(38,108); hud_health.size = Vector2(390,18); hud_health.show_percentage = false; layer.add_child(hud_health)
	hud_score = Label.new(); hud_score.position = Vector2(38,132); hud_score.add_theme_font_size_override("font_size",16); layer.add_child(hud_score)
	var controls_plate := ColorRect.new(); controls_plate.position = Vector2(20,744); controls_plate.size = Vector2(710,132); controls_plate.color = Color(0.025,0.03,0.045,0.78); layer.add_child(controls_plate)
	var controls := Label.new(); controls.position = Vector2(38,756); controls.text = "WASD move · mouse aim · LMB/J quick · RMB/K heavy · F/L grab\nSPACE dash · E hero move · 1 BRICK · 2 SPRING · 3 VICE · R reset\nWall splats hurt. Open parapets are ring-out lanes. Dash-cancel attacks."; controls.add_theme_font_size_override("font_size",18); layer.add_child(controls)
	hud_banner = Label.new(); hud_banner.position = Vector2(590,190); hud_banner.size = Vector2(420,80); hud_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; hud_banner.add_theme_font_size_override("font_size",54); layer.add_child(hud_banner)

func _update_hud(delta: float) -> void:
	if player != null:
		hud_hero.text = "%s  ·  %d HP" % [player.hero_type, int(ceil(max(0.0, player.health)))]
		hud_health.max_value = player.max_health; hud_health.value = max(0.0, player.health)
		hud_score.text = "KOs %d   ·   Bots %d" % [scores.get(player,0), _bot_score_total()]
	if hud_banner_timer > 0.0:
		hud_banner_timer -= delta
		if hud_banner_timer <= 0.0: hud_banner.text = ""

func _bot_score_total() -> int:
	var total := 0
	for fighter in fighters:
		if fighter != player: total += int(scores.get(fighter,0))
	return total

func _show_banner(text: String, duration: float) -> void:
	if hud_banner == null: return
	hud_banner.text = text; hud_banner_timer = duration

func _add_box_body(node_name: String, at: Vector3, size: Vector3, color: Color) -> StaticBody3D:
	var body := StaticBody3D.new(); body.name = node_name; body.position = at
	var mesh := BoxMesh.new(); mesh.size = size
	var mat := StandardMaterial3D.new(); mat.albedo_color = color; mat.roughness = 0.88; mesh.material = mat
	var mi := MeshInstance3D.new(); mi.mesh = mesh; body.add_child(mi)
	var collision := CollisionShape3D.new(); var shape := BoxShape3D.new(); shape.size = size; collision.shape = shape; body.add_child(collision)
	add_child(body); return body

func _add_box_visual(at: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var mesh := BoxMesh.new(); mesh.size = size
	var mat := StandardMaterial3D.new(); mat.albedo_color = color; mat.roughness = 0.75; mesh.material = mat
	var instance := MeshInstance3D.new(); instance.position = at; instance.mesh = mesh; add_child(instance); return instance
