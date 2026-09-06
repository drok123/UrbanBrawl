class_name CityRoadNetwork3D
extends Node3D

const ROAD_MANAGER_SCRIPT := "res://addons/road-generator/nodes/road_manager.gd"
const ROAD_CONTAINER_SCRIPT := "res://addons/road-generator/nodes/road_container.gd"
const ROAD_POINT_SCRIPT := "res://addons/road-generator/nodes/road_point.gd"
const ROAD_INTERSECTION_SCRIPT := "res://addons/road-generator/nodes/road_intersection.gd"

const LANE_FORWARD := 1
const LANE_REVERSE := 2

var _layout: Dictionary = {}
var _manager: Node3D = null
var _road_container_script: Script = null
var _road_point_script: Script = null
var _road_intersection_script: Script = null
var _road_records: Array[Dictionary] = []
var _junction_positions: Dictionary = {}
var _junction_nodes: Dictionary = {}
var _point_serial: int = 0

func configure_from_layout(layout: Dictionary) -> void:
	_layout = layout.duplicate(true)

func _ready() -> void:
	call_deferred("_build_network")

func _build_network() -> void:
	if _layout.is_empty():
		_layout = CityCrafterLayoutBridge.build_layout()
	_road_records = _collect_road_records()
	if _road_records.is_empty():
		return

	if not _road_generator_available():
		push_warning("Urban Brawl: Road Generator is not installed; using topology-matched emergency roads. Run INSTALL-DEPENDENCIES.bat.")
		_build_fallback_network()
		return

	var manager_script: Script = load(ROAD_MANAGER_SCRIPT) as Script
	_road_container_script = load(ROAD_CONTAINER_SCRIPT) as Script
	_road_point_script = load(ROAD_POINT_SCRIPT) as Script
	_road_intersection_script = load(ROAD_INTERSECTION_SCRIPT) as Script
	if manager_script == null or _road_container_script == null or _road_point_script == null or _road_intersection_script == null:
		push_warning("Urban Brawl: Road Generator graph scripts failed to load; using emergency roads.")
		_build_fallback_network()
		return

	_manager = manager_script.new() as Node3D
	if _manager == null:
		_build_fallback_network()
		return
	_manager.name = "RoadManager"
	_manager.set("auto_refresh", false)
	add_child(_manager)

	_build_native_graph()

	_manager.set("auto_refresh", true)
	if _manager.has_method("rebuild_all_containers"):
		_manager.call_deferred("rebuild_all_containers", true)
	print(
		"Urban Brawl: native Road Generator graph active — ",
		_road_records.size(),
		" street runs / ",
		_junction_nodes.size(),
		" shared junctions"
	)

func _road_generator_available() -> bool:
	return (
		ResourceLoader.exists(ROAD_MANAGER_SCRIPT)
		and ResourceLoader.exists(ROAD_CONTAINER_SCRIPT)
		and ResourceLoader.exists(ROAD_POINT_SCRIPT)
		and ResourceLoader.exists(ROAD_INTERSECTION_SCRIPT)
	)

func _build_native_graph() -> void:
	var container: Node3D = _road_container_script.new() as Node3D
	if container == null:
		_build_fallback_network()
		return
	container.name = "CityStreetGraph"
	_manager.add_child(container)
	container.set("generate_ai_lanes", true)
	container.set("ai_lane_group", "city_traffic_lane")
	container.set("create_edge_curves", true)
	container.set("flatten_terrain", false)
	container.set("underside_thickness", 0.06)
	if container.has_method("setup_road_container"):
		container.call("setup_road_container")

	_collect_junction_positions()
	_create_junction_nodes(container)

	var major_horizontal: float = _nearest_axis_coordinate("horizontal")
	var major_vertical: float = _nearest_axis_coordinate("vertical")
	for record: Dictionary in _road_records:
		var orientation: String = str(record.get("orientation", "horizontal"))
		var coordinate: float = float(record.get("coordinate", 0.0))
		var is_major: bool = (
			orientation == "horizontal" and is_equal_approx(coordinate, major_horizontal)
		) or (
			orientation == "vertical" and is_equal_approx(coordinate, major_vertical)
		)
		_build_record_segments(container, record, is_major)

	if container.has_method("update_edges"):
		container.call("update_edges")
	if container.has_method("rebuild_segments"):
		container.call_deferred("rebuild_segments", true)

func _collect_junction_positions() -> void:
	_junction_positions.clear()
	var horizontals: Array[Dictionary] = []
	var verticals: Array[Dictionary] = []
	for record: Dictionary in _road_records:
		if str(record.get("orientation", "")) == "horizontal":
			horizontals.append(record)
		else:
			verticals.append(record)

	for horizontal: Dictionary in horizontals:
		var z: float = float(horizontal.get("coordinate", 0.0))
		for vertical: Dictionary in verticals:
			var x: float = float(vertical.get("coordinate", 0.0))
			if x < float(horizontal.get("min", 0.0)) - 0.01 or x > float(horizontal.get("max", 0.0)) + 0.01:
				continue
			if z < float(vertical.get("min", 0.0)) - 0.01 or z > float(vertical.get("max", 0.0)) + 0.01:
				continue
			var key: Vector2i = _junction_key(x, z)
			_junction_positions[key] = Vector3(x, 0.045, z)

func _create_junction_nodes(container: Node3D) -> void:
	_junction_nodes.clear()
	var serial: int = 0
	for key_value: Variant in _junction_positions.keys():
		if not key_value is Vector2i:
			continue
		var key := key_value as Vector2i
		var intersection: Node3D = _road_intersection_script.new() as Node3D
		if intersection == null:
			continue
		intersection.name = "Junction_%03d" % serial
		intersection.position = _junction_positions[key] as Vector3
		container.add_child(intersection)
		intersection.set("container", container)
		intersection.set("flatten_terrain", false)
		_junction_nodes[key] = intersection
		serial += 1

func _build_record_segments(container: Node3D, record: Dictionary, is_major: bool) -> void:
	var orientation: String = str(record.get("orientation", "horizontal"))
	var coordinate: float = float(record.get("coordinate", 0.0))
	var start_value: float = float(record.get("min", 0.0))
	var end_value: float = float(record.get("max", 0.0))
	if end_value <= start_value + 0.01:
		return

	var stops: Array[float] = [start_value, end_value]
	for key_value: Variant in _junction_positions.keys():
		if not key_value is Vector2i:
			continue
		var position_value: Vector3 = _junction_positions[key_value] as Vector3
		if orientation == "horizontal":
			if absf(position_value.z - coordinate) <= 0.02 and position_value.x > start_value + 0.01 and position_value.x < end_value - 0.01:
				stops.append(position_value.x)
		else:
			if absf(position_value.x - coordinate) <= 0.02 and position_value.z > start_value + 0.01 and position_value.z < end_value - 0.01:
				stops.append(position_value.z)
	stops.sort()

	for index: int in range(stops.size() - 1):
		var a_value: float = stops[index]
		var b_value: float = stops[index + 1]
		if b_value - a_value < 0.75:
			continue
		var a_position := Vector3(a_value, 0.045, coordinate) if orientation == "horizontal" else Vector3(coordinate, 0.045, a_value)
		var b_position := Vector3(b_value, 0.045, coordinate) if orientation == "horizontal" else Vector3(coordinate, 0.045, b_value)
		_build_graph_edge(container, a_position, b_position, is_major)

func _build_graph_edge(container: Node3D, a_position: Vector3, b_position: Vector3, is_major: bool) -> void:
	var direction: Vector3 = b_position - a_position
	direction.y = 0.0
	var segment_length: float = direction.length()
	if segment_length < 0.75:
		return
	direction /= segment_length

	var a_intersection: Node3D = _junction_node_at(a_position)
	var b_intersection: Node3D = _junction_node_at(b_position)
	var street_width: float = float(_layout.get("street_width", 8.2))
	var approach: float = minf(street_width * 0.66, segment_length * 0.26)
	approach = clampf(approach, 2.4, 5.4)

	var point_a_position: Vector3 = a_position + direction * approach if a_intersection != null else a_position
	var point_b_position: Vector3 = b_position - direction * approach if b_intersection != null else b_position
	if point_a_position.distance_to(point_b_position) < 1.2:
		var midpoint: Vector3 = (a_position + b_position) * 0.5
		point_a_position = midpoint - direction * 0.65
		point_b_position = midpoint + direction * 0.65

	var point_a: Node3D = _create_road_point(container, point_a_position, direction, is_major)
	var point_b: Node3D = _create_road_point(container, point_b_position, direction, is_major)
	if point_a == null or point_b == null:
		return

	# Every graph edge is one coherent chain. Intersections attach to the free
	# end of the nearest approach point using RoadIntersection.add_branch(), the
	# same API exercised by the addon's own tests.
	point_a.set("next_pt_init", point_a.get_path_to(point_b))
	point_b.set("prior_pt_init", point_b.get_path_to(point_a))

	if a_intersection != null and a_intersection.has_method("add_branch"):
		a_intersection.call("add_branch", point_a)
	if b_intersection != null and b_intersection.has_method("add_branch"):
		b_intersection.call("add_branch", point_b)

func _create_road_point(container: Node3D, position_value: Vector3, direction: Vector3, is_major: bool) -> Node3D:
	var point: Node3D = _road_point_script.new() as Node3D
	if point == null:
		return null
	point.name = "RoadPoint_%04d" % _point_serial
	_point_serial += 1
	point.position = position_value
	point.rotation.y = atan2(direction.x, direction.z)
	container.add_child(point)
	point.set("container", container)
	point.set("lane_width", 3.20 if is_major else 3.05)
	point.set("shoulder_width_l", 0.78 if is_major else 0.58)
	point.set("shoulder_width_r", 0.78 if is_major else 0.58)
	point.set("gutter_profile", Vector2(0.32, -0.05))
	point.set("prior_mag", 3.2)
	point.set("next_mag", 3.2)
	point.set("auto_lanes", true)
	point.set("traffic_dir", [LANE_REVERSE, LANE_FORWARD])
	return point

func _junction_node_at(position_value: Vector3) -> Node3D:
	var key: Vector2i = _junction_key(position_value.x, position_value.z)
	return _junction_nodes.get(key, null) as Node3D

func _junction_key(x: float, z: float) -> Vector2i:
	return Vector2i(int(round(x * 100.0)), int(round(z * 100.0)))

func _collect_road_records() -> Array[Dictionary]:
	var active_variant: Variant = _layout.get("active_blocks", [])
	var active: Array = active_variant as Array if active_variant is Array else []
	var sizes_variant: Variant = _layout.get("block_sizes", {})
	var sizes: Dictionary = sizes_variant as Dictionary if sizes_variant is Dictionary else {}
	var block_size: float = float(_layout.get("block_size", 22.0))
	var street_width: float = float(_layout.get("street_width", 8.2))
	var stride: float = float(_layout.get("stride", block_size + street_width))
	var offset: Vector3 = _layout.get("origin_offset", Vector3.ZERO) as Vector3
	var horizontal: Dictionary = {}
	var vertical: Dictionary = {}

	for value: Variant in active:
		if not value is Vector2i:
			continue
		var pos := value as Vector2i
		var size: Vector2i = sizes.get(pos, Vector2i.ONE)
		_append_interval(horizontal, pos.y, pos.x, pos.x + size.x - 1)
		_append_interval(horizontal, pos.y + size.y, pos.x, pos.x + size.x - 1)
		_append_interval(vertical, pos.x, pos.y, pos.y + size.y - 1)
		_append_interval(vertical, pos.x + size.x, pos.y, pos.y + size.y - 1)

	var records: Array[Dictionary] = []
	var serial: int = 0
	for seam_value: Variant in horizontal.keys():
		var seam: int = int(seam_value)
		var raw_intervals: Variant = horizontal[seam]
		var merged: Array[Dictionary] = _merge_intervals(raw_intervals as Array if raw_intervals is Array else [])
		for segment: Dictionary in merged:
			var start_cell: int = int(segment["start"])
			var end_cell: int = int(segment["end"])
			var frontage: float = float(end_cell - start_cell + 1) * block_size + float(end_cell - start_cell) * street_width
			var x0: float = float(start_cell) * stride - street_width * 0.5 + offset.x
			var x1: float = float(start_cell) * stride + frontage + street_width * 0.5 + offset.x
			var z: float = float(seam) * stride - street_width * 0.5 + offset.z
			records.append({
				"name": "StreetH_%02d" % serial,
				"orientation": "horizontal",
				"coordinate": z,
				"min": x0,
				"max": x1,
			})
			serial += 1

	for seam_value: Variant in vertical.keys():
		var seam: int = int(seam_value)
		var raw_intervals: Variant = vertical[seam]
		var merged: Array[Dictionary] = _merge_intervals(raw_intervals as Array if raw_intervals is Array else [])
		for segment: Dictionary in merged:
			var start_cell: int = int(segment["start"])
			var end_cell: int = int(segment["end"])
			var frontage: float = float(end_cell - start_cell + 1) * block_size + float(end_cell - start_cell) * street_width
			var z0: float = float(start_cell) * stride - street_width * 0.5 + offset.z
			var z1: float = float(start_cell) * stride + frontage + street_width * 0.5 + offset.z
			var x: float = float(seam) * stride - street_width * 0.5 + offset.x
			records.append({
				"name": "StreetV_%02d" % serial,
				"orientation": "vertical",
				"coordinate": x,
				"min": z0,
				"max": z1,
			})
			serial += 1
	return records

func _append_interval(target: Dictionary, seam: int, start_value: int, end_value: int) -> void:
	if not target.has(seam):
		target[seam] = []
	var intervals: Array = target[seam] as Array
	intervals.append({"start": start_value, "end": end_value})

func _merge_intervals(values: Array) -> Array[Dictionary]:
	if values.is_empty():
		return []
	var sorted_values: Array = values.duplicate(true)
	sorted_values.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["start"]) < int(b["start"]))
	var merged: Array[Dictionary] = []
	var current: Dictionary = (sorted_values[0] as Dictionary).duplicate(true)
	for index: int in range(1, sorted_values.size()):
		var candidate: Dictionary = sorted_values[index] as Dictionary
		if int(candidate["start"]) <= int(current["end"]) + 1:
			current["end"] = maxi(int(current["end"]), int(candidate["end"]))
		else:
			merged.append(current)
			current = candidate.duplicate(true)
	merged.append(current)
	return merged

func _nearest_axis_coordinate(orientation: String) -> float:
	var best: float = 1000000.0
	var best_abs: float = 1000000.0
	for record: Dictionary in _road_records:
		if str(record.get("orientation", "")) != orientation:
			continue
		var value: float = float(record.get("coordinate", 0.0))
		if absf(value) < best_abs:
			best_abs = absf(value)
			best = value
	return best

func _build_fallback_network() -> void:
	var street_width: float = float(_layout.get("street_width", 8.2))
	for record: Dictionary in _road_records:
		var orientation: String = str(record.get("orientation", "horizontal"))
		var coordinate: float = float(record.get("coordinate", 0.0))
		var start_value: float = float(record.get("min", 0.0))
		var end_value: float = float(record.get("max", 0.0))
		var length: float = end_value - start_value
		if length <= 0.01:
			continue
		var road := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		if orientation == "horizontal":
			mesh.size = Vector3(length, 0.035, street_width)
			road.position = Vector3((start_value + end_value) * 0.5, 0.025, coordinate)
		else:
			mesh.size = Vector3(street_width, 0.035, length)
			road.position = Vector3(coordinate, 0.025, (start_value + end_value) * 0.5)
		road.mesh = mesh
		var material := StandardMaterial3D.new()
		material.albedo_color = Color(0.066, 0.068, 0.071, 1.0)
		material.roughness = 0.96
		road.material_override = material
		add_child(road)
