class_name CityRoadNetwork3D
extends Node3D

const ROAD_MANAGER_SCRIPT := "res://addons/road-generator/nodes/road_manager.gd"
const ROAD_CONTAINER_SCRIPT := "res://addons/road-generator/nodes/road_container.gd"
const ROAD_POINT_SCRIPT := "res://addons/road-generator/nodes/road_point.gd"

# RoadPoint enum values. Kept local so this bridge still parses before the
# managed Road Generator addon has been installed on a fresh clone.
const POINT_NEXT := 0
const POINT_PRIOR := 1
const LANE_FORWARD := 1
const LANE_REVERSE := 2

var _manager: Node3D = null
var _road_container_script: Script = null
var _road_point_script: Script = null

func _ready() -> void:
	call_deferred("_build_network")

func _build_network() -> void:
	if not _road_generator_available():
		push_warning("Urban Brawl: Road Generator is not installed; using emergency road fallback. Run INSTALL-DEPENDENCIES.bat.")
		_build_fallback_network()
		return

	var manager_script: Script = load(ROAD_MANAGER_SCRIPT) as Script
	_road_container_script = load(ROAD_CONTAINER_SCRIPT) as Script
	_road_point_script = load(ROAD_POINT_SCRIPT) as Script
	if manager_script == null or _road_container_script == null or _road_point_script == null:
		push_warning("Urban Brawl: Road Generator scripts failed to load; using emergency road fallback.")
		_build_fallback_network()
		return

	_manager = manager_script.new() as Node3D
	if _manager == null:
		_build_fallback_network()
		return
	_manager.name = "RoadManager"
	_manager.set("auto_refresh", false)
	add_child(_manager)

	# A compact believable street hierarchy: one four-lane avenue, one major
	# cross street, two district spines and two slightly offset neighborhood
	# streets. The tiny bends stop the city reading like a spreadsheet while
	# still giving gameplay clear sightlines.
	_add_generated_road(
		"CentralAvenue",
		[
			Vector3(-1.2, 0.04, -38.0),
			Vector3(-0.8, 0.04, -21.0),
			Vector3(0.0, 0.04, 0.0),
			Vector3(0.7, 0.04, 20.0),
			Vector3(0.0, 0.04, 38.0),
		],
		4,
		3.25
	)
	_add_generated_road(
		"DivisionStreet",
		[
			Vector3(-51.0, 0.045, -0.8),
			Vector3(-28.0, 0.045, -0.3),
			Vector3(0.0, 0.045, 0.0),
			Vector3(27.0, 0.045, 0.4),
			Vector3(51.0, 0.045, 1.2),
		],
		4,
		3.15
	)
	_add_generated_road(
		"WestAvenue",
		[
			Vector3(-27.0, 0.05, -38.0),
			Vector3(-27.8, 0.05, -21.0),
			Vector3(-27.0, 0.05, 0.0),
			Vector3(-26.2, 0.05, 20.0),
			Vector3(-27.0, 0.05, 38.0),
		],
		2,
		3.05
	)
	_add_generated_road(
		"EastAvenue",
		[
			Vector3(27.0, 0.05, -38.0),
			Vector3(26.2, 0.05, -20.0),
			Vector3(27.0, 0.05, 0.0),
			Vector3(27.8, 0.05, 20.0),
			Vector3(27.0, 0.05, 38.0),
		],
		2,
		3.05
	)
	_add_generated_road(
		"NorthStreet",
		[
			Vector3(-51.0, 0.055, -21.5),
			Vector3(-27.5, 0.055, -21.0),
			Vector3(-0.8, 0.055, -21.0),
			Vector3(26.2, 0.055, -20.0),
			Vector3(51.0, 0.055, -19.2),
		],
		2,
		3.0
	)
	_add_generated_road(
		"SouthStreet",
		[
			Vector3(-51.0, 0.055, 20.8),
			Vector3(-26.2, 0.055, 20.0),
			Vector3(0.7, 0.055, 20.0),
			Vector3(27.8, 0.055, 20.0),
			Vector3(51.0, 0.055, 20.8),
		],
		2,
		3.0
	)

	_build_intersections()
	_build_civic_plazas()

	_manager.set("auto_refresh", true)
	if _manager.has_method("rebuild_all_containers"):
		_manager.call_deferred("rebuild_all_containers", true)
	print("Urban Brawl: Road Generator street network active")

func _road_generator_available() -> bool:
	return (
		ResourceLoader.exists(ROAD_MANAGER_SCRIPT)
		and ResourceLoader.exists(ROAD_CONTAINER_SCRIPT)
		and ResourceLoader.exists(ROAD_POINT_SCRIPT)
	)

func _add_generated_road(road_name: String, points: Array[Vector3], lane_count: int, lane_width: float) -> void:
	if _manager == null or _road_container_script == null or _road_point_script == null or points.size() < 2:
		return
	var container: Node3D = _road_container_script.new() as Node3D
	if container == null:
		return
	container.name = road_name
	container.set("generate_ai_lanes", true)
	container.set("ai_lane_group", "city_traffic_lane")
	container.set("create_edge_curves", true)
	container.set("flatten_terrain", false)
	container.set("underside_thickness", 0.08)
	_manager.add_child(container)

	var road_points: Array[Node3D] = []
	for index: int in range(points.size()):
		var road_point: Node3D = _road_point_script.new() as Node3D
		if road_point == null:
			continue
		road_point.name = "P%02d" % index
		road_point.position = points[index]
		road_point.rotation.y = _point_yaw(points, index)
		road_point.set("lane_width", lane_width)
		road_point.set("shoulder_width_l", 0.28)
		road_point.set("shoulder_width_r", 0.28)
		road_point.set("gutter_profile", Vector2(0.45, -0.06))
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
				push_warning("Urban Brawl: Road Generator could not connect %s segment %d" % [road_name, index])
	if container.has_method("rebuild_segments"):
		container.call_deferred("rebuild_segments", true)

func _traffic_directions(lane_count: int) -> Array[int]:
	var directions: Array[int] = []
	var reverse_count: int = maxi(lane_count / 2, 1)
	var forward_count: int = maxi(lane_count - reverse_count, 1)
	for _index: int in range(reverse_count):
		directions.append(LANE_REVERSE)
	for _index: int in range(forward_count):
		directions.append(LANE_FORWARD)
	return directions

func _point_yaw(points: Array[Vector3], index: int) -> float:
	var direction: Vector3
	if index <= 0:
		direction = points[1] - points[0]
	elif index >= points.size() - 1:
		direction = points[index] - points[index - 1]
	else:
		direction = points[index + 1] - points[index - 1]
	direction.y = 0.0
	if direction.length_squared() <= 0.0001:
		return 0.0
	direction = direction.normalized()
	return atan2(direction.x, direction.z)

func _handle_length(points: Array[Vector3], index: int) -> float:
	var previous_distance: float = INF
	var next_distance: float = INF
	if index > 0:
		previous_distance = points[index].distance_to(points[index - 1])
	if index < points.size() - 1:
		next_distance = points[index].distance_to(points[index + 1])
	var nearest: float = minf(previous_distance, next_distance)
	if is_inf(nearest):
		nearest = maxf(previous_distance, next_distance)
	return clampf(nearest * 0.30, 3.5, 8.5)

func _build_intersections() -> void:
	# These pads intentionally sit just above the generated street meshes. They
	# suppress overlapping lane markings where independent authored roads cross;
	# the Road Generator still owns the actual road geometry, collision and AI lanes.
	var major: Array[Vector3] = [Vector3(0, 0, 0), Vector3(0, 0, -21), Vector3(0.7, 0, 20)]
	for position_value: Vector3 in major:
		_add_intersection_pad(position_value, Vector2(15.5, 12.0), true)

	var local: Array[Vector3] = [
		Vector3(-27, 0, 0), Vector3(27, 0, 0),
		Vector3(-27.5, 0, -21), Vector3(26.2, 0, -20),
		Vector3(-26.2, 0, 20), Vector3(27.8, 0, 20),
	]
	for position_value: Vector3 in local:
		_add_intersection_pad(position_value, Vector2(9.0, 9.0), false)

func _add_intersection_pad(position_value: Vector3, size: Vector2, crosswalks: bool) -> void:
	var pad: MeshInstance3D = MeshInstance3D.new()
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = Vector3(size.x, 0.035, size.y)
	pad.mesh = mesh
	pad.position = position_value + Vector3(0.0, 0.085, 0.0)
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = Color(0.075, 0.077, 0.08, 1.0)
	material.roughness = 0.94
	pad.material_override = material
	add_child(pad)
	if crosswalks:
		_add_crosswalk(position_value + Vector3(0.0, 0.11, -4.4), true)
		_add_crosswalk(position_value + Vector3(0.0, 0.11, 4.4), true)

func _add_crosswalk(position_value: Vector3, horizontal_stripes: bool) -> void:
	for index: int in range(-3, 4):
		var stripe: MeshInstance3D = MeshInstance3D.new()
		var mesh: BoxMesh = BoxMesh.new()
		mesh.size = Vector3(0.55, 0.018, 3.4) if horizontal_stripes else Vector3(3.4, 0.018, 0.55)
		stripe.mesh = mesh
		stripe.position = position_value + (Vector3(float(index) * 0.95, 0.0, 0.0) if horizontal_stripes else Vector3(0.0, 0.0, float(index) * 0.95))
		var material: StandardMaterial3D = StandardMaterial3D.new()
		material.albedo_color = Color(0.78, 0.79, 0.78, 1.0)
		material.roughness = 0.88
		stripe.material_override = material
		add_child(stripe)

func _build_civic_plazas() -> void:
	# Two small neutral pedestrian pockets stop Central Commons from being a road
	# median with vendors standing in traffic.
	_add_plaza(Vector3(-9.5, 0.0, -11.5), Vector2(8.0, 9.0))
	_add_plaza(Vector3(-9.5, 0.0, 12.5), Vector2(8.0, 10.0))

func _add_plaza(position_value: Vector3, size: Vector2) -> void:
	var plaza: MeshInstance3D = MeshInstance3D.new()
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = Vector3(size.x, 0.12, size.y)
	plaza.mesh = mesh
	plaza.position = position_value + Vector3(0.0, 0.045, 0.0)
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = Color(0.31, 0.305, 0.295, 1.0)
	material.roughness = 0.96
	plaza.material_override = material
	add_child(plaza)

func _build_fallback_network() -> void:
	# Only used when the managed addon is missing. It deliberately mirrors the
	# authored network rather than returning to the old three giant rectangles.
	_add_fallback_road(Vector3(0, 0.01, 0), Vector3(14.0, 0.04, 76.0))
	_add_fallback_road(Vector3(0, 0.015, 0), Vector3(102.0, 0.04, 13.0))
	_add_fallback_road(Vector3(-27, 0.02, 0), Vector3(7.0, 0.04, 76.0))
	_add_fallback_road(Vector3(27, 0.02, 0), Vector3(7.0, 0.04, 76.0))
	_add_fallback_road(Vector3(0, 0.025, -21), Vector3(102.0, 0.04, 7.0))
	_add_fallback_road(Vector3(0, 0.025, 20), Vector3(102.0, 0.04, 7.0))
	_build_intersections()
	_build_civic_plazas()

func _add_fallback_road(position_value: Vector3, size: Vector3) -> void:
	var road: MeshInstance3D = MeshInstance3D.new()
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = size
	road.mesh = mesh
	road.position = position_value
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = Color(0.065, 0.067, 0.07, 1.0)
	material.roughness = 0.96
	road.material_override = material
	add_child(road)
