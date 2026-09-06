class_name CityRoadNetwork3D
extends Node3D

const ROAD_MANAGER_SCRIPT := "res://addons/road-generator/nodes/road_manager.gd"
const ROAD_CONTAINER_SCRIPT := "res://addons/road-generator/nodes/road_container.gd"
const ROAD_POINT_SCRIPT := "res://addons/road-generator/nodes/road_point.gd"
const PREFAB_4WAY := "res://addons/road-generator/custom_containers/4way_1x1.tscn"

const POINT_PRIOR := 0
const POINT_NEXT := 1

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
	print("Urban Brawl: Road Generator production network — ", _junctions.size(), " prefab intersections / ", _segment_serial, " straight containers")

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
	for value: Variant in records:
		if not value is Dictionary:
			continue
		var record := value as Dictionary
		var junction := intersection_scene.instantiate() as Node3D
		if junction == null:
			continue
		var junction_id: String = str(record.get("id", "Junction"))
		junction.name = junction_id
		junction.position = (record.get("position", Vector3.ZERO) as Vector3) + Vector3(0.0, 0.035, 0.0)
		_manager.add_child(junction)
		# The prefab owns its hand-modeled mesh, collision and RoadLanes.
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
		_create_straight_container(a_edge, b_edge, direction, str(record.get("class", "local")))

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
			var outward: Vector3 = rp.global_position - junction.global_position
			outward.y = 0.0
			if outward.length_squared() <= 0.001:
				continue
			outward = outward.normalized()
			_create_tail_container({"rp": rp, "dir": int(dirs[index])}, outward, tail)

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
			best = {"rp": rp, "dir": int(dirs[index]) if index < dirs.size() else POINT_NEXT}
	return best if best_score > 0.80 else {}

func _create_straight_container(a_edge: Dictionary, b_edge: Dictionary, direction: Vector3, road_class: String) -> void:
	var a_rp: Node3D = a_edge.get("rp", null) as Node3D
	var b_rp: Node3D = b_edge.get("rp", null) as Node3D
	if a_rp == null or b_rp == null:
		return
	var segment := _new_segment_container("Street_%03d_%s" % [_segment_serial, road_class])
	if segment == null:
		return
	var point_a := _new_segment_point(segment, a_rp.global_position, direction, a_rp)
	var point_b := _new_segment_point(segment, b_rp.global_position, direction, b_rp)
	if point_a == null or point_b == null:
		segment.queue_free()
		return

	if not bool(point_a.call("connect_roadpoint", POINT_NEXT, point_b, POINT_PRIOR)):
		segment.queue_free()
		return
	if segment.has_method("update_edges"):
		segment.call("update_edges")

	var a_connected: bool = bool(a_rp.call("connect_container", int(a_edge.get("dir", POINT_NEXT)), point_a, POINT_PRIOR))
	var b_connected: bool = bool(b_rp.call("connect_container", int(b_edge.get("dir", POINT_PRIOR)), point_b, POINT_NEXT))
	if not a_connected or not b_connected:
		push_warning("Urban Brawl: failed to bridge RoadContainer prefab edges for %s" % segment.name)
	_finalize_segment_container(segment)
	_segment_serial += 1

func _create_tail_container(source_edge: Dictionary, outward: Vector3, tail_length: float) -> void:
	var source_rp: Node3D = source_edge.get("rp", null) as Node3D
	if source_rp == null:
		return
	var segment := _new_segment_container("StreetTail_%03d" % _segment_serial)
	if segment == null:
		return
	var point_a := _new_segment_point(segment, source_rp.global_position, outward, source_rp)
	var point_b := _new_segment_point(segment, source_rp.global_position + outward * tail_length, outward, source_rp)
	if point_a == null or point_b == null:
		segment.queue_free()
		return
	if not bool(point_a.call("connect_roadpoint", POINT_NEXT, point_b, POINT_PRIOR)):
		segment.queue_free()
		return
	if segment.has_method("update_edges"):
		segment.call("update_edges")
	if not bool(source_rp.call("connect_container", int(source_edge.get("dir", POINT_NEXT)), point_a, POINT_PRIOR)):
		push_warning("Urban Brawl: failed to bridge outer RoadContainer edge for %s" % segment.name)
	_finalize_segment_container(segment)
	_segment_serial += 1

func _new_segment_container(node_name: String) -> Node3D:
	var container := _road_container_script.new() as Node3D
	if container == null:
		return null
	container.name = node_name
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

func _new_segment_point(container: Node3D, world_position: Vector3, direction: Vector3, template: Node3D) -> Node3D:
	var point := _road_point_script.new() as Node3D
	if point == null:
		return null
	point.name = "RoadPoint_%04d" % _point_serial
	_point_serial += 1
	container.add_child(point)
	point.set("container", container)
	if point.has_method("copy_settings_from"):
		point.call("copy_settings_from", template, false)
	var snapped_position := world_position
	snapped_position.y = 0.035
	point.global_position = snapped_position
	point.rotation.y = atan2(direction.x, direction.z)
	# Preserve the prefab's copied cross-section; only make the connecting road
	# handles straight and long enough to leave the modeled junction cleanly.
	point.set("prior_mag", 8.0)
	point.set("next_mag", 8.0)
	return point

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
	var min_x: float = float(road_x[0]) - tail
	var max_x: float = float(road_x[-1]) + tail
	var min_z: float = float(road_z[0]) - tail
	var max_z: float = float(road_z[-1]) + tail
	for z_value: Variant in road_z:
		_add_fallback_road(Vector3((min_x + max_x) * 0.5, 0.015, float(z_value)), Vector3(max_x - min_x, 0.03, 12.0))
	for x_value: Variant in road_x:
		_add_fallback_road(Vector3(float(x_value), 0.017, (min_z + max_z) * 0.5), Vector3(12.0, 0.03, max_z - min_z))

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
