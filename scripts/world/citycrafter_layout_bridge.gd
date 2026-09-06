class_name CityCrafterLayoutBridge
extends RefCounted

const CITYCRAFTER_SCRIPT := "res://addons/citycrafter/citycrafter.gd"
const CONFIG_SCRIPT := "res://addons/citycrafter/city_configuration.gd"
const CITY_SEED := 731942

static func build_layout() -> Dictionary:
	if not ResourceLoader.exists(CITYCRAFTER_SCRIPT) or not ResourceLoader.exists(CONFIG_SCRIPT):
		push_warning("Urban Brawl: CityCrafter is not installed; using deterministic fallback block topology. Run INSTALL-DEPENDENCIES.bat.")
		return _fallback_layout()

	var config_script: Script = load(CONFIG_SCRIPT) as Script
	var crafter_script: Script = load(CITYCRAFTER_SCRIPT) as Script
	if config_script == null or crafter_script == null:
		return _fallback_layout()

	var config: Resource = config_script.new() as Resource
	var crafter: Node = crafter_script.new() as Node
	if config == null or crafter == null:
		return _fallback_layout()

	# Compact-city values, scaled for an on-foot top-down game rather than the
	# 200 m default blocks in CityCrafter's example project.
	config.set("grid_width", 5)
	config.set("grid_height", 5)
	config.set("block_size", 19.0)
	config.set("street_width", 9.5)
	config.set("empty_block_chance", 0.0)
	config.set("enable_multi_size_blocks", true)
	config.set("large_block_chance", 0.13)
	config.set("wide_block_chance", 0.22)
	config.set("tall_block_chance", 0.18)
	config.set("enable_edge_variations", true)
	config.set("edge_variation_chance", 0.20)
	config.set("enable_random_extensions", true)
	config.set("random_extensions_count", 4)
	config.set("extension_spawn_chance", 0.55)
	# Zoned areas gives us a believable downtown/core -> mixed middle -> outer
	# service/industrial density gradient. Faction territory remains our own layer.
	config.set("district_mode", 1)
	config.set("residential_ratio", 0.42)
	config.set("commercial_ratio", 0.38)
	config.set("industrial_ratio", 0.20)
	config.set("noise_scale", 0.12)
	config.set("enable_residential_subdivisions", false)
	config.set("generate_ground", false)
	config.set("generate_roads", false)
	config.set("generate_intersections", false)
	config.set("rotation_mode", 1)
	config.set("scale_variation", 0.0)

	crafter.set("city_configuration", config)
	var noise := FastNoiseLite.new()
	noise.seed = CITY_SEED
	noise.frequency = 0.12
	crafter.set("noise", noise)

	# CityCrafter's topology generator currently uses global randf/randi. Seed it
	# only for this calculation, then restore normal nondeterministic game RNG.
	seed(CITY_SEED)
	crafter.call("generate_active_blocks")

	var raw_blocks: Variant = crafter.get("active_blocks")
	var raw_sizes: Variant = crafter.get("block_sizes")
	var active_blocks: Array = raw_blocks.duplicate(true) if raw_blocks is Array else []
	var block_sizes: Dictionary = raw_sizes.duplicate(true) if raw_sizes is Dictionary else {}
	var districts: Dictionary = {}
	for value: Variant in active_blocks:
		if value is Vector2i:
			var grid_pos := value as Vector2i
			districts[grid_pos] = str(crafter.call("get_district_type", grid_pos.x, grid_pos.y))

	randomize()
	crafter.free()

	if active_blocks.is_empty():
		return _fallback_layout()

	return _finalize_layout(active_blocks, block_sizes, districts, 19.0, 9.5)

static func _finalize_layout(active_blocks: Array, block_sizes: Dictionary, districts: Dictionary, block_size: float, street_width: float) -> Dictionary:
	var stride: float = block_size + street_width
	var min_x: float = 1000000.0
	var min_z: float = 1000000.0
	var max_x: float = -1000000.0
	var max_z: float = -1000000.0

	for value: Variant in active_blocks:
		if not value is Vector2i:
			continue
		var grid_pos := value as Vector2i
		var grid_size: Vector2i = block_sizes.get(grid_pos, Vector2i.ONE)
		var width: float = float(grid_size.x) * block_size + float(grid_size.x - 1) * street_width
		var depth: float = float(grid_size.y) * block_size + float(grid_size.y - 1) * street_width
		var x0: float = float(grid_pos.x) * stride
		var z0: float = float(grid_pos.y) * stride
		min_x = minf(min_x, x0)
		min_z = minf(min_z, z0)
		max_x = maxf(max_x, x0 + width)
		max_z = maxf(max_z, z0 + depth)

	var offset := Vector3(-(min_x + max_x) * 0.5, 0.0, -(min_z + max_z) * 0.5)
	return {
		"active_blocks": active_blocks,
		"block_sizes": block_sizes,
		"districts": districts,
		"block_size": block_size,
		"street_width": street_width,
		"stride": stride,
		"origin_offset": offset,
		"bounds_min": Vector2(min_x + offset.x, min_z + offset.z),
		"bounds_max": Vector2(max_x + offset.x, max_z + offset.z),
		"bounds_size": Vector2(max_x - min_x, max_z - min_z),
		"source": "CityCrafter",
	}

static func _fallback_layout() -> Dictionary:
	var active_blocks: Array = []
	var sizes: Dictionary = {}
	var districts: Dictionary = {}
	for x: int in range(5):
		for z: int in range(5):
			var pos := Vector2i(x, z)
			active_blocks.append(pos)
			sizes[pos] = Vector2i.ONE
			var edge_distance: int = mini(mini(x, 4 - x), mini(z, 4 - z))
			districts[pos] = "industrial" if edge_distance == 0 else ("commercial" if x in [2] and z in [2] else "residential")
	return _finalize_layout(active_blocks, sizes, districts, 19.0, 9.5)
