class_name CityRoadNetwork3D
extends Node3D

const ROAD_MANAGER_SCRIPT := "res://addons/road-generator/nodes/road_manager.gd"
const ROAD_CONTAINER_SCRIPT := "res://addons/road-generator/nodes/road_container.gd"
const ROAD_POINT_SCRIPT := "res://addons/road-generator/nodes/road_point.gd"
const PREFAB_4WAY := "res://addons/road-generator/custom_containers/4way_1x1.tscn"

# Road Generator 0.9.3 intentionally defines PointInit in this order:
# NEXT = 0, PRIOR = 1, NEITHER = 2. Do not "correct" this ordering locally.
const POINT_NEXT := 0
const POINT_PRIOR := 1
const POINT_NEITHER := 2

var _plan: Dictionary = {}
var _manager: Node3D = null
var _road_container_script: Script = null
var _road_point_script: Script = null
var _junctions: Dictionary = {}
var _point_serial: int = 0
var _segment_serial: int = 0

func configure_from_plan(plan: Dictionary) -> void:
	_plan = plan.duplicate(true)

func _ready() -> void:
	call_deferred("_build_network")

func _build_network() -> void:
	if _plan.is_empty():
		_plan = CityMasterPlan.build_plan()
	if not _road_generator_available():
		push_warning("Urban Brawl: Road Generator is unavailable; using emergency road geometry. Run INSTALL-DEPENDENCIES.bat.")
		_build_fallback_network()
		return

	var manager_script: Script = load(ROAD_MANAGER_SCRIPT) as Script
	_road_container_script = load(ROAD_CONTAINER_SCRIPT) as Script
	_road_point_script = load(ROAD_POINT_SCRIPT) as Script
	var intersection_scene: PackedScene = load(PREFAB_4WAY) as PackedScene
	if manager_script == null or _road_container_script == null or _road_point_script == null or intersection_scene == null:
		push_warning("Urban Brawl: Road Generator production resources failed to load; using emergency roads.")
		_build_fallback_network()
		return

	_manager = manager_script.new() as Node3D
	if _manager == null:
		_build_fallback_network()
		return
	_manager.name = "RoadManager"
	_manager.set("auto_refresh", false)
	add_child(_manager)

	_create_prefab_junctions(intersection_scene)
	_connect_authored_segments()
	_extend_outer_streets()

	_manager.set("auto_refresh", true)
	if _manager.has_method("rebuild_all_containers"):
		_manager.call_deferred("rebuild_all_containers", true)
	print(
		"Urban Brawl: Road Generator production network — ",
		_junctions.size(),
		" prefab intersections / ",
		_segment_serial,
		" straight containers @ scale ",
		_road_scale(),
		" | native bridge semantics"
	)

func _road_scale() -> float:
	return clampf(float(_plan.get("road_scale", 1.0)), 0.25, 2.0)

func _road_generator_available() -> bool:
	return (
		ResourceLoader.exists(ROAD_MANAGER_SCRIPT)
		and ResourceLoader.exists(ROAD_CONTAINER_SCRIPT)
		and ResourceLoader.exists(ROAD_POINT_SCRIPT)
		and ResourceLoader.exists(PREFAB_4WAY)
	)

func _create_prefab_junctions(intersection_scene: PackedScene) -> void:
	_junctions.clear()
	var raw: Variant = _plan.get("intersections", [])
	if not raw is Array:
		return
	var records: Array = raw as Array
	var scale_value: float = _road_scale()
	for value: Variant in records:
		if not value is Dictionary:
			continue
		var record := value as Dictionary
		var junction := intersection_scene.instantiate() as Node3D
		if junction == null:
			continue
		var junction_id: String = str(record.get("id", "Junction"))
		junction.name = junction_id
		# Scale the complete authored RoadContainer uniformly. Connecting straight
		# containers receive the same scale, so lane/shoulder/gutter proportions and
		# endpoint transforms remain compatible with the prefab.
		junction.scale = Vector3.ONE * scale_value
		junction.position = (record.get("position", Vector3.ZERO) as Vector3) + Vector3(0.0, 0.035, 0.0)
		_manager.add_child(junction)
		if junction.has_method("update_edges"):
			junction.call("update_edges")
		_junctions[junction_id] = junction

func _connect_authored_segments() -> void:
	var raw: Variant = _plan.get("segments", [])
	if not raw is Array:
		return
	var records: Array = raw as Array
	for value: Variant in records:
		if not value is Dictionary:
			continue
		var record := value as Dictionary
		var a_id: String = str(record.get("a", ""))
		var b_id: String = str(record.get("b", ""))
		var a_junction: Node3D = _junctions.get(a_id, null) as Node3D
		var b_junction: Node3D = _junctions.get(b_id, null) as Node3D
		if a_junction == null or b_junction == null:
			continue
		var direction: Vector3 = b_junction.global_position - a_junction.global_position
		direction.y = 0.0
		if direction.length_squared() <= 0.001:
			continue
		direction = direction.normalized()
		var a_edge: Dictionary = _edge_toward(a_junction, direction)
		var b_edge: Dictionary = _edge_toward(b_junction, -direction)
		if a_edge.is_empty() or b_edge.is_empty():
			push_warning("Urban Brawl: Road Generator prefab edge lookup failed for %s -> %s" % [a_id, b_id])
			continue
		_create_straight_container(a_edge, b_edge, str(record.get("class", "local")))

func _extend_outer_streets() -> void:
	var tail: float = float(_plan.get("road_tail", 34.0))
	for junction_value: Variant in _junctions.values():
		var junction := junction_value as Node3D
		if junction == null:
			continue
		var locals_variant: Variant = junction.get("edge_rp_locals")
		var dirs_variant: Variant = junction.get("edge_rp_local_dirs")
		var containers_variant: Variant = junction.get("edge_containers")
		if not locals_variant is Array or not dirs_variant is Array or not containers_variant is Array:
			continue
		var locals: Array = locals_variant as Array
		var dirs: Array = dirs_variant as Array
		var containers: Array = containers_variant as Array
		for index: int in range(locals.size()):
			if index < containers.size() and not str(containers[index]).is_empty():
				continue
			var rp: Node3D = junction.get_node_or_null(locals[index]) as Node3D
			if rp == null:
				continue
			var open_dir: int = _open_dir(rp)
			if open_dir == POINT_NEITHER:
				continue
			if index < dirs.size() and int(dirs[index]) != open_dir:
				push_warning(
					"Urban Brawl: prefab edge metadata/open-direction mismatch at %s/%s (edge %d, open %d)" % [
						junction.name, rp.name, int(dirs[index]), open_dir
					]
				)
			_create_tail_container(rp, open_dir, tail)

func _edge_toward(container: Node3D, wanted_direction: Vector3) -> Dictionary:
	var locals_variant: Variant = container.get("edge_rp_locals")
	var dirs_variant: Variant = container.get("edge_rp_local_dirs")
	if not locals_variant is Array or not dirs_variant is Array:
		return {}
	var locals: Array = locals_variant as Array
	var dirs: Array = dirs_variant as Array
	var best_score: float = -1000.0
	var best: Dictionary = {}
	for index: int in range(locals.size()):
		var rp: Node3D = container.get_node_or_null(locals[index]) as Node3D
		if rp == null:
			continue
		var radial: Vector3 = rp.global_position - container.global_position
		radial.y = 0.0
		if radial.length_squared() <= 0.001:
			continue
		radial = radial.normalized()
		var score: float = radial.dot(wanted_direction)
		if score > best_score:
			best_score = score
			best = {
				"rp": rp,
				"dir": int(dirs[index]) if index < dirs.size() else _open_dir(rp),
			}
	return best if best_score > 0.80 else {}

func _create_straight_container(a_edge: Dictionary, b_edge: Dictionary, road_class: String) -> void:
	var a_rp: Node3D = a_edge.get("rp", null) as Node3D
	var b_rp: Node3D = b_edge.get("rp", null) as Node3D
	if a_rp == null or b_rp == null:
		return

	# Mirror Road Generator's own bridge_rps_with_new_container() semantics:
	# 1) determine which side of each existing edge point is actually open;
	# 2) copy each endpoint's complete transform and cross-section settings;
	# 3) use the same open side for the bridge's internal road connection;
	# 4) use the flipped side for the cross-container connection back to the prefab.
	var a_dir: int = _open_dir(a_rp)
	var b_dir: int = _open_dir(b_rp)
	if a_dir == POINT_NEITHER or b_dir == POINT_NEITHER:
		push_warning("Urban Brawl: cannot bridge fully-connected prefab RoadPoints %s / %s" % [a_rp.name, b_rp.name])
		return
	var a_edge_dir: int = _opposite_dir(a_dir)
	var b_edge_dir: int = _opposite_dir(b_dir)

	if int(a_edge.get("dir", a_dir)) != a_dir or int(b_edge.get("dir", b_dir)) != b_dir:
		push_warning(
			"Urban Brawl: prefab edge table disagrees with live RoadPoint state for %s -> %s; live open directions win" % [
				a_rp.name, b_rp.name
			]
		)

	var segment := _new_segment_container("Street_%03d_%s" % [_segment_serial, road_class])
	if segment == null:
		return
	var point_a := _new_segment_point_from_template(segment, a_rp)
	var point_b := _new_segment_point_from_template(segment, b_rp)
	if point_a == null or point_b == null:
		segment.queue_free()
		return

	if not bool(point_a.call("connect_roadpoint", a_dir, point_b, b_dir)):
		push_warning("Urban Brawl: internal RoadPoint bridge failed for %s" % segment.name)
		segment.queue_free()
		return
	if segment.has_method("update_edges"):
		segment.call("update_edges")

	var a_connected: bool = bool(point_a.call("connect_container", a_edge_dir, a_rp, a_dir))
	var b_connected: bool = bool(point_b.call("connect_container", b_edge_dir, b_rp, b_dir))
	if not a_connected or not b_connected:
		push_warning("Urban Brawl: failed native-style prefab bridge for %s (A=%s B=%s)" % [segment.name, a_connected, b_connected])
	_finalize_segment_container(segment)
	_segment_serial += 1

func _create_tail_container(source_rp: Node3D, source_dir: int, tail_length: float) -> void:
	if source_rp == null or source_dir == POINT_NEITHER:
		return
	var segment := _new_segment_container("StreetTail_%03d" % _segment_serial)
	if segment == null:
		return

	var point_a := _new_segment_point_from_template(segment, source_rp)
	var point_b := _new_tail_end_point(segment, source_rp, source_dir, tail_length)
	if point_a == null or point_b == null:
		segment.queue_free()
		return

	var end_connection_dir: int = _opposite_dir(source_dir)
	if not bool(point_a.call("connect_roadpoint", source_dir, point_b, end_connection_dir)):
		push_warning("Urban Brawl: outer street internal connection failed for %s" % segment.name)
		segment.queue_free()
		return
	if segment.has_method("update_edges"):
		segment.call("update_edges")

	var seam_dir: int = _opposite_dir(source_dir)
	if not bool(point_a.call("connect_container", seam_dir, source_rp, source_dir)):
		push_warning("Urban Brawl: failed native-style outer RoadContainer bridge for %s" % segment.name)
	_finalize_segment_container(segment)
	_segment_serial += 1

func _new_segment_container(node_name: String) -> Node3D:
	var container := _road_container_script.new() as Node3D
	if container == null:
		return null
	container.name = node_name
	container.scale = Vector3.ONE * _road_scale()
	container.set("_auto_refresh", false)
	container.set("generate_ai_lanes", true)
	container.set("ai_lane_group", "city_traffic_lane")
	container.set("create_edge_curves", true)
	container.set("flatten_terrain", false)
	container.set("underside_thickness", 0.06)
	_manager.add_child(container)
	if container.has_method("setup_road_container"):
		container.call("setup_road_container")
	return container

func _new_segment_point_from_template(container: Node3D, template: Node3D) -> Node3D:
	var point := _road_point_script.new() as Node3D
	if point == null:
		return null
	point.name = "RoadPoint_%04d" % _point_serial
	_point_serial += 1
	container.add_child(point)
	point.set("container", container)
	if point.has_method("copy_settings_from"):
		# The addon bridge copies settings and the original transform. Keeping the
		# authored basis is critical: it preserves lane ordering and which side is
		# PRIOR/NEXT at the exact intersection seam.
		point.call("copy_settings_from", template, true)
	point.global_transform = template.global_transform
	return point

func _new_tail_end_point(container: Node3D, template: Node3D, source_dir: int, tail_length: float) -> Node3D:
	var point := _new_segment_point_from_template(container, template)
	if point == null:
		return null
	var outward: Vector3 = template.global_basis.z.normalized()
	if source_dir == POINT_PRIOR:
		outward = -outward
	var target_transform: Transform3D = template.global_transform
	target_transform.origin = template.global_position + outward * tail_length
	point.global_transform = target_transform
	return point

func _open_dir(rp: Node3D) -> int:
	if rp == null:
		return POINT_NEITHER
	var prior_path: NodePath = rp.get("prior_pt_init")
	var next_path: NodePath = rp.get("next_pt_init")
	if prior_path.is_empty():
		return POINT_PRIOR
	if next_path.is_empty():
		return POINT_NEXT
	return POINT_NEITHER

func _opposite_dir(direction_value: int) -> int:
	if direction_value == POINT_NEXT:
		return POINT_PRIOR
	if direction_value == POINT_PRIOR:
		return POINT_NEXT
	return POINT_NEITHER

func _finalize_segment_container(container: Node3D) -> void:
	container.set("_auto_refresh", true)
	if container.has_method("update_edges"):
		container.call("update_edges")
	if container.has_method("rebuild_segments"):
		container.call_deferred("rebuild_segments", true)

func _build_fallback_network() -> void:
	var road_x_variant: Variant = _plan.get("road_x", [])
	var road_z_variant: Variant = _plan.get("road_z", [])
	if not road_x_variant is Array or not road_z_variant is Array:
		return
	var road_x: Array = road_x_variant as Array
	var road_z: Array = road_z_variant as Array
	if road_x.is_empty() or road_z.is_empty():
		return
	var tail: float = float(_plan.get("road_tail", 34.0))
	var road_width: float = float(_plan.get("road_half_width", 6.1)) * 2.0
	var min_x: float = float(road_x[0]) - tail
	var max_x: float = float(road_x[-1]) + tail
	var min_z: float = float(road_z[0]) - tail
	var max_z: float = float(road_z[-1]) + tail
	for z_value: Variant in road_z:
		_add_fallback_road(Vector3((min_x + max_x) * 0.5, 0.015, float(z_value)), Vector3(max_x - min_x, 0.03, road_width))
	for x_value: Variant in road_x:
		_add_fallback_road(Vector3(float(x_value), 0.017, (min_z + max_z) * 0.5), Vector3(road_width, 0.03, max_z - min_z))

func _add_fallback_road(position_value: Vector3, size: Vector3) -> void:
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	mesh_instance.position = position_value
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.075, 0.078, 0.082, 1.0)
	material.roughness = 0.98
	mesh_instance.material_override = material
	add_child(mesh_instance)
