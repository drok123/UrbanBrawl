class_name CityRoadNetwork3D
extends Node3D

const ROAD_MANAGER_SCRIPT := "res://addons/road-generator/nodes/road_manager.gd"
const ROAD_CONTAINER_SCRIPT := "res://addons/road-generator/nodes/road_container.gd"
const ROAD_POINT_SCRIPT := "res://addons/road-generator/nodes/road_point.gd"

const POINT_NEXT := 0
const POINT_PRIOR := 1
const LANE_FORWARD := 1
const LANE_REVERSE := 2

var _layout: Dictionary = {}
var _manager: Node3D = null
var _road_container_script: Script = null
var _road_point_script: Script = null
var _road_records: Array[Dictionary] = []

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
	if manager_script == null or _road_container_script == null or _road_point_script == null:
		_build_fallback_network()
		return

	_manager = manager_script.new() as Node3D
	if _manager == null:
		_build_fallback_network()
		return
	_manager.name = "RoadManager"
	_manager.set("auto_refresh", false)
	add_child(_manager)

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
		var points_variant: Variant = record.get("points", [])
		var points: Array[Vector3] = []
		if points_variant is Array:
			for point_value: Variant in points_variant:
				if point_value is Vector3:
					points.append(point_value as Vector3)
		if points.size() < 2:
			continue

		# Compact real-world-ish urban proportions. The old four-lane avenue used
		# tiny lanes just to fit the procedural block width and looked immediately
		# fake. Major roads are now two travel lanes with generous curb/parking
		# shoulders; local streets are two lanes with tighter shoulders.
		_add_generated_road(
			str(record.get("name", "Street")),
			points,
			2,
			3.20 if is_major else 3.05,
			0.78 if is_major else 0.58
		)

	_build_intersection_surfaces(major_horizontal, major_vertical)
	_manager.set("auto_refresh", true)
	if _manager.has_method("rebuild_all_containers"):
		_manager.call_deferred("rebuild_all_containers", true)
	print("Urban Brawl: Road Generator consuming CityCrafter topology — ", _road_records.size(), " road runs")

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
				"points": [Vector3(x0, 0.045, z), Vector3(x1, 0.045, z)],
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
				"points": [Vector3(x, 0.045, z0), Vector3(x, 0.045, z1)],
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

func _road_generator_available() -> bool:
	return ResourceLoader.exists(ROAD_MANAGER_SCRIPT) and ResourceLoader.exists(ROAD_CONTAINER_SCRIPT) and ResourceLoader.exists(ROAD_POINT_SCRIPT)

func _add_generated_road(road_name: String, points: Array[Vector3], lane_count: int, lane_width: float, shoulder_width: float) -> void:
	if _manager == null or _road_container_script == null or _road_point_script == null or points.size() < 2:
		return
	var container: Node3D = _road_container_script.new() as Node3D
	if container == null:
		return
	container.name = road_name
	_manager.add_child(container)
	container.set("generate_ai_lanes", true)
	container.set("ai_lane_group", "city_traffic_lane")
	container.set("create_edge_curves", true)
	container.set("flatten_terrain", false)
	container.set("underside_thickness", 0.06)

	var road_points: Array[Node3D] = []
	for index: int in range(points.size()):
		var road_point: Node3D = _road_point_script.new() as Node3D
		if road_point == null:
			continue
		road_point.name = "P%02d" % index
		road_point.position = points[index]
		road_point.rotation.y = _point_yaw(points, index)
		road_point.set("lane_width", lane_width)
		road_point.set("shoulder_width_l", shoulder_width)
		road_point.set("shoulder_width_r", shoulder_width)
		road_point.set("gutter_profile", Vector2(0.32, -0.05))
		road_point.set("prior_mag", _handle_length(points, index))
		road_point.set("next_mag", _handle_length(points, index))
		road_point.set("auto_lanes", true)
		road_point.set("traffic_dir", _traffic_directions(lane_count))
		container.add_child(road_point)
		road_points.append(road_point)

	for index: int in range(road_points.size() - 1):
		var from: Node3D = road_points[index]
		var target: Node3D = road_points[index + 1]
		if from.has_method("connect_roadpoint"):
			var connected: Variant = from.call("connect_roadpoint", POINT_NEXT, target, POINT_PRIOR)
			if connected != true:
				push_warning("Urban Brawl: could not connect CityCrafter road run %s" % road_name)
	if container.has_method("rebuild_segments"):
		container.call_deferred("rebuild_segments", true)

func _traffic_directions(lane_count: int) -> Array[int]:
	var directions: Array[int] = []
	var reverse_count: int = maxi(int(floor(float(lane_count) * 0.5)), 1)
	var forward_count: int = maxi(lane_count - reverse_count, 1)
	for _index: int in range(reverse_count):
		directions.append(LANE_REVERSE)
	for _index: int in range(forward_count):
		directions.append(LANE_FORWARD)
	return directions

func _point_yaw(points: Array[Vector3], index: int) -> float:
	var direction: Vector3 = points[1] - points[0] if index <= 0 else points[index] - points[index - 1]
	direction.y = 0.0
	if direction.length_squared() <= 0.0001:
		return 0.0
	direction = direction.normalized()
	return atan2(direction.x, direction.z)

func _handle_length(points: Array[Vector3], index: int) -> float:
	var nearest: float = points[0].distance_to(points[1]) if index <= 0 else points[index].distance_to(points[index - 1])
	return clampf(nearest * 0.22, 3.5, 8.0)

func _build_intersection_surfaces(major_horizontal: float, major_vertical: float) -> void:
	var street_width: float = float(_layout.get("street_width", 8.2))
	var horizontals: Array[Dictionary] = []
	var verticals: Array[Dictionary] = []
	for record: Dictionary in _road_records:
		if str(record.get("orientation", "")) == "horizontal":
			horizontals.append(record)
		else:
			verticals.append(record)

	var made: Dictionary = {}
	for horizontal: Dictionary in horizontals:
		var z: float = float(horizontal["coordinate"])
		for vertical: Dictionary in verticals:
			var x: float = float(vertical["coordinate"])
			if x < float(horizontal["min"]) - 0.1 or x > float(horizontal["max"]) + 0.1:
				continue
			if z < float(vertical["min"]) - 0.1 or z > float(vertical["max"]) + 0.1:
				continue
			var key := Vector2i(int(round(x * 10.0)), int(round(z * 10.0)))
			if made.has(key):
				continue
			made[key] = true
			var major: bool = is_equal_approx(z, major_horizontal) or is_equal_approx(x, major_vertical)
			_add_intersection_pad(Vector3(x, 0.0, z), street_width, major)

func _add_intersection_pad(position_value: Vector3, street_width: float, major: bool) -> void:
	var pad := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(street_width + 0.25, 0.028, street_width + 0.25)
	pad.mesh = mesh
	pad.position = position_value + Vector3(0.0, 0.082, 0.0)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.072, 0.074, 0.077, 1.0)
	material.roughness = 0.95
	pad.material_override = material
	add_child(pad)
	if major:
		_add_crosswalk(position_value + Vector3(0.0, 0.105, -street_width * 0.34))
		_add_crosswalk(position_value + Vector3(0.0, 0.105, street_width * 0.34))

func _add_crosswalk(position_value: Vector3) -> void:
	for index: int in range(-3, 4):
		var stripe := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(0.48, 0.016, 2.6)
		stripe.mesh = mesh
		stripe.position = position_value + Vector3(float(index) * 0.78, 0.0, 0.0)
		var material := StandardMaterial3D.new()
		material.albedo_color = Color(0.76, 0.77, 0.75, 1.0)
		material.roughness = 0.90
		stripe.material_override = material
		add_child(stripe)

func _build_fallback_network() -> void:
	var street_width: float = float(_layout.get("street_width", 8.2))
	for record: Dictionary in _road_records:
		var points_variant: Variant = record.get("points", [])
		if not points_variant is Array:
			continue
		var points: Array = points_variant as Array
		if points.size() < 2 or not points[0] is Vector3 or not points[1] is Vector3:
			continue
		var a: Vector3 = points[0] as Vector3
		var b: Vector3 = points[1] as Vector3
		var center: Vector3 = (a + b) * 0.5
		var length: float = a.distance_to(b)
		var road := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(length, 0.035, street_width) if str(record.get("orientation", "")) == "horizontal" else Vector3(street_width, 0.035, length)
		road.mesh = mesh
		road.position = Vector3(center.x, 0.025, center.z)
		var material := StandardMaterial3D.new()
		material.albedo_color = Color(0.066, 0.068, 0.071, 1.0)
		material.roughness = 0.96
		road.material_override = material
		add_child(road)
	_build_intersection_surfaces(_nearest_axis_coordinate("horizontal"), _nearest_axis_coordinate("vertical"))
