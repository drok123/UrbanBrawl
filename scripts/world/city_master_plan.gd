class_name CityMasterPlan
extends RefCounted

# Production public-city geometry is intentionally authored. Generic resources
# own the geometry they are good at (roads/buildings); Urban Brawl owns where
# those pieces go so faction routes, sightlines and activity spaces stay useful.

const ROAD_X: Array[float] = [-86.0, -32.0, 24.0, 86.0]
const ROAD_Z: Array[float] = [-82.0, -26.0, 32.0, 88.0]
const ROAD_HALF_WIDTH := 6.15
const ROAD_TAIL := 34.0
const SIDEWALK_WIDTH := 2.15
const CITY_MARGIN := 12.0

static func build_plan() -> Dictionary:
	var intersections: Array[Dictionary] = []
	var segments: Array[Dictionary] = []
	var blocks: Array[Dictionary] = []

	for row: int in range(ROAD_Z.size()):
		for col: int in range(ROAD_X.size()):
			intersections.append({
				"id": _junction_id(col, row),
				"grid": Vector2i(col, row),
				"position": Vector3(ROAD_X[col], 0.0, ROAD_Z[row]),
				"kind": "4way",
			})

	for row: int in range(ROAD_Z.size()):
		for col: int in range(ROAD_X.size() - 1):
			segments.append({"a": _junction_id(col, row), "b": _junction_id(col + 1, row), "class": _road_class(col, row, true)})
	for col: int in range(ROAD_X.size()):
		for row: int in range(ROAD_Z.size() - 1):
			segments.append({"a": _junction_id(col, row), "b": _junction_id(col, row + 1), "class": _road_class(col, row, false)})

	# Buildable lot boundaries begin at the authored road edge, not at an abstract
	# generator-cell seam. The Road Generator 1x1 prefab is roughly six meters
	# from centerline to curb/road edge in its modeled cross section.
	for row: int in range(ROAD_Z.size() - 1):
		for col: int in range(ROAD_X.size() - 1):
			var x0: float = ROAD_X[col] + ROAD_HALF_WIDTH
			var x1: float = ROAD_X[col + 1] - ROAD_HALF_WIDTH
			var z0: float = ROAD_Z[row] + ROAD_HALF_WIDTH
			var z1: float = ROAD_Z[row + 1] - ROAD_HALF_WIDTH
			var grid := Vector2i(col, row)
			var identity: Dictionary = _block_identity(grid)
			blocks.append({
				"id": "B_%d_%d" % [col, row],
				"grid": grid,
				"center": Vector3((x0 + x1) * 0.5, 0.0, (z0 + z1) * 0.5),
				"width": x1 - x0,
				"depth": z1 - z0,
				"district": identity["district"],
				"role": identity["role"],
				"primary_frontage": identity["primary_frontage"],
				"secondary_frontage": identity["secondary_frontage"],
			})

	var bounds_min := Vector2(ROAD_X[0] - ROAD_TAIL - CITY_MARGIN, ROAD_Z[0] - ROAD_TAIL - CITY_MARGIN)
	var bounds_max := Vector2(ROAD_X[-1] + ROAD_TAIL + CITY_MARGIN, ROAD_Z[-1] + ROAD_TAIL + CITY_MARGIN)
	return {
		"source": "Urban Brawl authored production plan",
		"intersections": intersections,
		"segments": segments,
		"blocks": blocks,
		"road_x": ROAD_X.duplicate(),
		"road_z": ROAD_Z.duplicate(),
		"road_half_width": ROAD_HALF_WIDTH,
		"road_tail": ROAD_TAIL,
		"sidewalk_width": SIDEWALK_WIDTH,
		"bounds_min": bounds_min,
		"bounds_max": bounds_max,
		"bounds_size": bounds_max - bounds_min,
	}

static func block_by_role(plan: Dictionary, role: String) -> Dictionary:
	var raw: Variant = plan.get("blocks", [])
	if not raw is Array:
		return {}
	var blocks: Array = raw as Array
	for value: Variant in blocks:
		if value is Dictionary and str((value as Dictionary).get("role", "")) == role:
			return (value as Dictionary).duplicate(true)
	return {}

static func block_by_grid(plan: Dictionary, grid: Vector2i) -> Dictionary:
	var raw: Variant = plan.get("blocks", [])
	if not raw is Array:
		return {}
	var blocks: Array = raw as Array
	for value: Variant in blocks:
		if value is Dictionary and (value as Dictionary).get("grid", Vector2i(-99, -99)) == grid:
			return (value as Dictionary).duplicate(true)
	return {}

static func _junction_id(col: int, row: int) -> String:
	return "J_%d_%d" % [col, row]

static func _road_class(col: int, row: int, horizontal: bool) -> String:
	# Keep compatible geometry through every prefab. Class is metadata for future
	# traffic/parking/signage, not a reason to distort intersection cross-sections.
	if horizontal and row == 1:
		return "main"
	if not horizontal and col == 1:
		return "main"
	return "local"

static func _block_identity(grid: Vector2i) -> Dictionary:
	# Directions point from the lot toward its intended street frontage.
	match grid:
		Vector2i(0, 0):
			return _identity("residential", "neighborhood_nw", Vector3(1, 0, 0), Vector3(0, 0, 1))
		Vector2i(1, 0):
			return _identity("commercial", "market_north", Vector3(0, 0, 1), Vector3(1, 0, 0))
		Vector2i(2, 0):
			return _identity("mixed", "contraband", Vector3(-1, 0, 0), Vector3(0, 0, 1))
		Vector2i(0, 1):
			return _identity("civic", "police", Vector3(1, 0, 0), Vector3(0, 0, -1))
		Vector2i(1, 1):
			return _identity("commercial", "commons", Vector3(0, 0, -1), Vector3(1, 0, 0))
		Vector2i(2, 1):
			return _identity("commercial", "market_east", Vector3(-1, 0, 0), Vector3(0, 0, -1))
		Vector2i(0, 2):
			return _identity("residential", "neighborhood_sw", Vector3(1, 0, 0), Vector3(0, 0, -1))
		Vector2i(1, 2):
			return _identity("industrial", "foundry_west", Vector3(0, 0, -1), Vector3(1, 0, 0))
		Vector2i(2, 2):
			return _identity("industrial", "arms", Vector3(-1, 0, 0), Vector3(0, 0, -1))
	return _identity("mixed", "generic", Vector3(0, 0, -1), Vector3(1, 0, 0))

static func _identity(district: String, role: String, primary: Vector3, secondary: Vector3) -> Dictionary:
	return {
		"district": district,
		"role": role,
		"primary_frontage": primary,
		"secondary_frontage": secondary,
	}
