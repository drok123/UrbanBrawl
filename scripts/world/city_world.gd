class_name CityWorld3D
extends Node3D

@export var player_path: NodePath = NodePath("Player")

var _player: Node3D = null
var _layout: Dictionary = {}
var _anchors: Dictionary = {}
var _commons_rect: Dictionary = {}
var _building_serial: int = 0

func _ready() -> void:
	_player = get_node_or_null(player_path) as Node3D
	QuaterniusAssetLocator.print_install_summary()
	_layout = CityCrafterLayoutBridge.build_layout()
	_build_city()
	_restore_city_spawn()
	_update_territory()

func _process(_delta: float) -> void:
	_update_territory()

func _build_city() -> void:
	var bounds_size: Vector2 = _layout.get("bounds_size", Vector2(140.0, 140.0)) as Vector2
	_add_static_box(
		self,
		"CityFoundation",
		Vector3(bounds_size.x + 28.0, 0.30, bounds_size.y + 28.0),
		Vector3(0.0, -0.18, 0.0),
		Color(0.095, 0.098, 0.102, 1.0)
	)

	var road_network := CityRoadNetwork3D.new()
	road_network.name = "StreetNetwork"
	road_network.configure_from_layout(_layout)
	add_child(road_network)

	_select_anchor_blocks()
	_build_generated_blocks()
	_build_street_dressing()
	_place_gameplay_nodes()
	print("Urban Brawl: public city layout source = ", _layout.get("source", "fallback"), " | blocks = ", (_layout.get("active_blocks", []) as Array).size())

func _select_anchor_blocks() -> void:
	var bounds_min: Vector2 = _layout.get("bounds_min", Vector2(-60, -60)) as Vector2
	var bounds_max: Vector2 = _layout.get("bounds_max", Vector2(60, 60)) as Vector2
	var span := bounds_max - bounds_min
	var excluded: Dictionary = {}

	var commons := _choose_block(Vector2.ZERO, excluded, true)
	excluded[commons] = true
	var police := _choose_block(Vector2(bounds_min.x + span.x * 0.16, 0.0), excluded, true)
	excluded[police] = true
	var contraband := _choose_block(Vector2(bounds_min.x + span.x * 0.82, bounds_min.y + span.y * 0.20), excluded, true)
	excluded[contraband] = true
	var arms := _choose_block(Vector2(bounds_min.x + span.x * 0.82, bounds_min.y + span.y * 0.80), excluded, true)

	_anchors = {
		"commons": commons,
		"police": police,
		"contraband": contraband,
		"arms": arms,
	}
	_commons_rect = _block_rect(commons)

func _choose_block(target: Vector2, excluded: Dictionary, prefer_large: bool = false) -> Vector2i:
	var active_variant: Variant = _layout.get("active_blocks", [])
	var active: Array = active_variant as Array if active_variant is Array else []
	var best := Vector2i.ZERO
	var best_score: float = 1000000.0
	for value: Variant in active:
		if not value is Vector2i:
			continue
		var grid_pos := value as Vector2i
		if excluded.has(grid_pos):
			continue
		var rect: Dictionary = _block_rect(grid_pos)
		var center: Vector3 = rect.get("center", Vector3.ZERO) as Vector3
		var width: float = float(rect.get("width", 19.0))
		var depth: float = float(rect.get("depth", 19.0))
		var area_bonus: float = minf(width * depth / 180.0, 6.0) if prefer_large else 0.0
		var score: float = Vector2(center.x, center.z).distance_to(target) - area_bonus
		if score < best_score:
			best_score = score
			best = grid_pos
	return best

func _block_rect(grid_pos: Vector2i) -> Dictionary:
	var sizes_variant: Variant = _layout.get("block_sizes", {})
	var sizes: Dictionary = sizes_variant as Dictionary if sizes_variant is Dictionary else {}
	var grid_size: Vector2i = sizes.get(grid_pos, Vector2i.ONE)
	var block_size: float = float(_layout.get("block_size", 19.0))
	var street_width: float = float(_layout.get("street_width", 9.5))
	var stride: float = float(_layout.get("stride", block_size + street_width))
	var offset: Vector3 = _layout.get("origin_offset", Vector3.ZERO) as Vector3
	var width: float = float(grid_size.x) * block_size + float(grid_size.x - 1) * street_width
	var depth: float = float(grid_size.y) * block_size + float(grid_size.y - 1) * street_width
	var x0: float = float(grid_pos.x) * stride + offset.x
	var z0: float = float(grid_pos.y) * stride + offset.z
	return {
		"grid_pos": grid_pos,
		"grid_size": grid_size,
		"width": width,
		"depth": depth,
		"center": Vector3(x0 + width * 0.5, 0.0, z0 + depth * 0.5),
	}

func _build_generated_blocks() -> void:
	var active_variant: Variant = _layout.get("active_blocks", [])
	var active: Array = active_variant as Array if active_variant is Array else []
	var districts_variant: Variant = _layout.get("districts", {})
	var districts: Dictionary = districts_variant as Dictionary if districts_variant is Dictionary else {}

	for value: Variant in active:
		if not value is Vector2i:
			continue
		var grid_pos := value as Vector2i
		var rect: Dictionary = _block_rect(grid_pos)
		var district: String = str(districts.get(grid_pos, "residential"))
		_add_block_sidewalk(grid_pos, rect, district)

		if grid_pos == (_anchors.get("commons", Vector2i.ZERO) as Vector2i):
			_build_commons(rect)
		elif grid_pos == (_anchors.get("police", Vector2i.ZERO) as Vector2i):
			_build_faction_base(rect, "police")
		elif grid_pos == (_anchors.get("contraband", Vector2i.ZERO) as Vector2i):
			_build_faction_base(rect, "contraband")
		elif grid_pos == (_anchors.get("arms", Vector2i.ZERO) as Vector2i):
			_build_faction_base(rect, "arms")
		else:
			_build_generic_block(rect, district)

func _add_block_sidewalk(grid_pos: Vector2i, rect: Dictionary, district: String) -> void:
	var center: Vector3 = rect.get("center", Vector3.ZERO) as Vector3
	var width: float = float(rect.get("width", 19.0))
	var depth: float = float(rect.get("depth", 19.0))
	var pad := MeshInstance3D.new()
	pad.name = "Block_%d_%d" % [grid_pos.x, grid_pos.y]
	var mesh := BoxMesh.new()
	mesh.size = Vector3(maxf(width - 0.35, 1.0), 0.14, maxf(depth - 0.35, 1.0))
	pad.mesh = mesh
	pad.position = center + Vector3(0.0, 0.035, 0.0)
	var material := StandardMaterial3D.new()
	match district:
		"commercial":
			material.albedo_color = Color(0.255, 0.252, 0.245, 1.0)
		"industrial":
			material.albedo_color = Color(0.185, 0.188, 0.185, 1.0)
		_:
			material.albedo_color = Color(0.225, 0.225, 0.215, 1.0)
	material.roughness = 0.98
	pad.material_override = material
	add_child(pad)

func _build_generic_block(rect: Dictionary, district: String) -> void:
	var center: Vector3 = rect.get("center", Vector3.ZERO) as Vector3
	var width: float = float(rect.get("width", 19.0))
	var depth: float = float(rect.get("depth", 19.0))
	var large_x: bool = width > 29.0
	var large_z: bool = depth > 29.0
	var tokens: Array[String] = _district_tokens(district)
	var fallback: Color = _district_fallback(district)
	var base_height: float = 5.0 if district == "industrial" else (7.2 if district == "commercial" else 5.8)

	if large_x and large_z:
		# True superblock: four perimeter buildings with a usable interior court.
		var bw: float = minf(width * 0.36, 15.0)
		var bd: float = minf(depth * 0.36, 14.0)
		var x_offset: float = width * 0.5 - bw * 0.5 - 1.8
		var z_offset: float = depth * 0.5 - bd * 0.5 - 1.8
		for corner: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
			_add_external_building(
				"CityBuilding_%03d" % _building_serial,
				Vector3(bw, base_height + float(_building_serial % 3) * 0.8, bd),
				center + Vector3(corner.x * x_offset, (base_height + float(_building_serial % 3) * 0.8) * 0.5, corner.y * z_offset),
				fallback,
				_building_serial,
				tokens,
				0.0 if corner.y < 0.0 else 180.0
			)
			_building_serial += 1
		_add_courtyard(center, Vector2(maxf(width * 0.26, 5.0), maxf(depth * 0.26, 5.0)), district)
		return

	if large_x:
		var count: int = 3 if width > 48.0 else 2
		var slot: float = (width - 5.0) / float(count)
		for index: int in range(count):
			var x: float = center.x - width * 0.5 + 2.5 + slot * (float(index) + 0.5)
			var h: float = base_height + float((_building_serial + index) % 3) * 0.7
			_add_external_building("CityBuilding_%03d" % _building_serial, Vector3(slot * 0.80, h, minf(depth - 5.0, 13.0)), Vector3(x, h * 0.5, center.z), fallback, _building_serial, tokens, _street_yaw(center))
			_building_serial += 1
		return

	if large_z:
		var count: int = 3 if depth > 48.0 else 2
		var slot: float = (depth - 5.0) / float(count)
		for index: int in range(count):
			var z: float = center.z - depth * 0.5 + 2.5 + slot * (float(index) + 0.5)
			var h: float = base_height + float((_building_serial + index) % 3) * 0.7
			_add_external_building("CityBuilding_%03d" % _building_serial, Vector3(minf(width - 5.0, 13.0), h, slot * 0.80), Vector3(center.x, h * 0.5, z), fallback, _building_serial, tokens, _street_yaw(center))
			_building_serial += 1
		return

	# Normal city block. Industrial blocks leave more yard; commercial blocks
	# build tighter to the sidewalk; residential sits between those extremes.
	var inset: float = 5.8 if district == "industrial" else (3.8 if district == "commercial" else 4.8)
	var target_width: float = maxf(minf(width - inset, 15.0), 7.0)
	var target_depth: float = maxf(minf(depth - inset, 14.0), 7.0)
	var height: float = base_height + float(_building_serial % 4) * 0.65
	var toward: Vector3 = _toward_city(center)
	var setback: float = 1.8 if district == "commercial" else 2.8
	var building_center: Vector3 = center - toward * setback
	_add_external_building("CityBuilding_%03d" % _building_serial, Vector3(target_width, height, target_depth), Vector3(building_center.x, height * 0.5, building_center.z), fallback, _building_serial, tokens, _street_yaw(center))
	_building_serial += 1

	if district == "industrial":
		_add_prop("ServiceBin_%03d" % _building_serial, center + Vector3(width * 0.32, 0.0, depth * 0.30), ["dumpster", "trash", "bin"], _building_serial, 1.25, 1.8)

func _build_faction_base(rect: Dictionary, faction: String) -> void:
	var center: Vector3 = rect.get("center", Vector3.ZERO) as Vector3
	var width: float = float(rect.get("width", 19.0))
	var depth: float = float(rect.get("depth", 19.0))
	var toward: Vector3 = _toward_city(center)
	var height: float = 7.4 if faction == "police" else (5.8 if faction == "contraband" else 6.4)
	var tokens: Array[String]
	var fallback: Color
	match faction:
		"police":
			tokens = ["office", "civic", "building"]
			fallback = Color(0.16, 0.18, 0.22, 1.0)
		"contraband":
			tokens = ["apartment", "store", "shop", "building"]
			fallback = Color(0.16, 0.18, 0.16, 1.0)
		_:
			tokens = ["industrial", "warehouse", "store", "building"]
			fallback = Color(0.20, 0.17, 0.15, 1.0)

	var building_width: float = maxf(minf(width * 0.68, 20.0), 10.0)
	var building_depth: float = maxf(minf(depth * 0.62, 17.0), 9.0)
	var backshift: float = minf(minf(width, depth) * 0.10, 3.5)
	var building_center: Vector3 = center - toward * backshift
	_add_external_building("%sHeadquarters" % faction.capitalize(), Vector3(building_width, height, building_depth), Vector3(building_center.x, height * 0.5, building_center.z), fallback, 30 + _building_serial, tokens, _street_yaw(center))
	_building_serial += 1

	# Small forecourt keeps the entrance readable without giant faction paint.
	var front: Vector3 = _frontage_point(rect)
	_add_plaza("%sForecourt" % faction.capitalize(), (front + center) * 0.5, Vector2(5.0, 5.0), Color(0.30, 0.30, 0.29, 1.0))

func _build_commons(rect: Dictionary) -> void:
	var center: Vector3 = rect.get("center", Vector3.ZERO) as Vector3
	var width: float = float(rect.get("width", 19.0))
	var depth: float = float(rect.get("depth", 19.0))
	_add_plaza("CentralCommons", center, Vector2(maxf(width - 1.0, 8.0), maxf(depth - 1.0, 8.0)), Color(0.325, 0.315, 0.295, 1.0))

	var kiosk_height: float = 3.4
	var kiosk_width: float = minf(maxf(width * 0.20, 4.5), 7.0)
	var kiosk_depth: float = minf(maxf(depth * 0.22, 4.5), 7.0)
	_add_external_building("CommonsKioskA", Vector3(kiosk_width, kiosk_height, kiosk_depth), center + Vector3(-width * 0.30, kiosk_height * 0.5, depth * 0.28), Color(0.23, 0.23, 0.22, 1.0), 70, ["store", "shop", "building"], 90.0)
	_add_external_building("CommonsKioskB", Vector3(kiosk_width, kiosk_height, kiosk_depth), center + Vector3(width * 0.30, kiosk_height * 0.5, -depth * 0.28), Color(0.23, 0.23, 0.22, 1.0), 71, ["store", "shop", "building"], -90.0)

func _build_street_dressing() -> void:
	var active_variant: Variant = _layout.get("active_blocks", [])
	var active: Array = active_variant as Array if active_variant is Array else []
	var districts_variant: Variant = _layout.get("districts", {})
	var districts: Dictionary = districts_variant as Dictionary if districts_variant is Dictionary else {}
	var index: int = 0
	for value: Variant in active:
		if not value is Vector2i:
			continue
		var grid_pos := value as Vector2i
		var rect: Dictionary = _block_rect(grid_pos)
		var center: Vector3 = rect.get("center", Vector3.ZERO) as Vector3
		var width: float = float(rect.get("width", 19.0))
		var depth: float = float(rect.get("depth", 19.0))
		if index % 2 == 0:
			_add_prop("StreetLamp_%03d" % index, center + Vector3(-width * 0.5 + 1.0, 0.0, -depth * 0.5 + 1.0), ["streetlight", "street_light", "lamp"], index, 3.2, 1.0)
		if str(districts.get(grid_pos, "")) == "commercial" and index % 3 == 0:
			_add_prop("StreetTrash_%03d" % index, center + Vector3(width * 0.5 - 1.2, 0.0, depth * 0.5 - 1.2), ["trash", "garbage", "bin"], index, 1.0, 1.3)
		index += 1

	if not _commons_rect.is_empty():
		var commons_center: Vector3 = _commons_rect.get("center", Vector3.ZERO) as Vector3
		for offset: Vector3 in [Vector3(-3.8, 0, -2.5), Vector3(3.8, 0, 2.5)]:
			_add_prop("CommonsBench_%s" % str(offset), commons_center + offset, ["bench", "seat"], int(absf(offset.x) * 10.0), 0.95, 2.1, 90.0)

func _place_gameplay_nodes() -> void:
	var police_rect: Dictionary = _block_rect(_anchors.get("police", Vector2i.ZERO) as Vector2i)
	var contra_rect: Dictionary = _block_rect(_anchors.get("contraband", Vector2i.ZERO) as Vector2i)
	var arms_rect: Dictionary = _block_rect(_anchors.get("arms", Vector2i.ZERO) as Vector2i)
	var commons_center: Vector3 = _commons_rect.get("center", Vector3.ZERO) as Vector3

	_place_base_entrance("PrecinctEntrance", police_rect)
	_place_base_entrance("SafehouseEntrance", contra_rect)
	_place_base_entrance("WorkshopEntrance", arms_rect)

	var excluded: Dictionary = {
		_anchors.get("commons", Vector2i.ZERO): true,
		_anchors.get("police", Vector2i.ZERO): true,
		_anchors.get("contraband", Vector2i.ZERO): true,
		_anchors.get("arms", Vector2i.ZERO): true,
	}
	var bounds_min: Vector2 = _layout.get("bounds_min", Vector2(-60, -60)) as Vector2
	var bounds_max: Vector2 = _layout.get("bounds_max", Vector2(60, 60)) as Vector2
	var span := bounds_max - bounds_min
	var drug_block := _choose_block(Vector2(bounds_min.x + span.x * 0.28, bounds_min.y + span.y * 0.34), excluded)
	excluded[drug_block] = true
	var gun_block := _choose_block(Vector2(bounds_min.x + span.x * 0.70, bounds_min.y + span.y * 0.30), excluded)
	excluded[gun_block] = true
	var interdict_block := _choose_block(Vector2(bounds_min.x + span.x * 0.70, bounds_min.y + span.y * 0.70), excluded)

	var drug_pos: Vector3 = _frontage_point(_block_rect(drug_block))
	var gun_pos: Vector3 = _frontage_point(_block_rect(gun_block))
	var interdict_pos: Vector3 = _frontage_point(_block_rect(interdict_block))
	_set_node_position("DrugBuyer", drug_pos)
	_set_node_position("GunrunnerBuyer", gun_pos)
	_set_node_position("InterdictionCache", interdict_pos)

	_set_node_position("FFAEntrance", commons_center + Vector3(0.0, 0.0, -2.8))
	_set_node_position("KnifeVendor", commons_center + Vector3(-2.7, 0.0, 3.0))
	_set_node_position("BatVendor", commons_center + Vector3(0.0, 0.0, 3.0))
	_set_node_position("PistolVendor", commons_center + Vector3(2.7, 0.0, 3.0))

	_set_node_position("BeatCopA", drug_pos + Vector3(-3.0, 0.95, 3.0))
	_set_node_position("BeatCopB", _frontage_point(police_rect) + Vector3(3.0, 0.95, -3.0))
	_set_node_position("ContrabandGuardA", gun_pos + Vector3(-3.0, 0.95, 2.5))
	_set_node_position("ContrabandGuardB", _frontage_point(contra_rect) + Vector3(3.0, 0.95, 2.5))
	_set_node_position("ArmsGuardA", interdict_pos + Vector3(-3.0, 0.95, -2.5))
	_set_node_position("ArmsGuardB", _frontage_point(arms_rect) + Vector3(3.0, 0.95, -2.5))

	if _player != null:
		_player.global_position = commons_center + Vector3(0.0, 0.95, 0.0)

func _place_base_entrance(node_name: String, rect: Dictionary) -> void:
	var node: Node3D = get_node_or_null(node_name) as Node3D
	if node == null:
		return
	var front: Vector3 = _frontage_point(rect)
	var toward: Vector3 = _toward_city(rect.get("center", Vector3.ZERO) as Vector3)
	node.global_position = front
	node.set("city_return_position", front + toward * 2.3 + Vector3(0.0, 0.95, 0.0))

func _set_node_position(node_name: String, position_value: Vector3) -> void:
	var node: Node3D = get_node_or_null(node_name) as Node3D
	if node != null:
		node.global_position = position_value

func _frontage_point(rect: Dictionary) -> Vector3:
	var center: Vector3 = rect.get("center", Vector3.ZERO) as Vector3
	var width: float = float(rect.get("width", 19.0))
	var depth: float = float(rect.get("depth", 19.0))
	var toward: Vector3 = _toward_city(center)
	if absf(toward.x) >= absf(toward.z):
		var side_x: float = 1.0 if toward.x >= 0.0 else -1.0
		return Vector3(center.x + side_x * (width * 0.5 - 1.1), 0.0, center.z)
	var side_z: float = 1.0 if toward.z >= 0.0 else -1.0
	return Vector3(center.x, 0.0, center.z + side_z * (depth * 0.5 - 1.1))

func _toward_city(center: Vector3) -> Vector3:
	var direction := Vector3(-center.x, 0.0, -center.z)
	if direction.length_squared() < 0.001:
		return Vector3(0.0, 0.0, -1.0)
	return direction.normalized()

func _street_yaw(center: Vector3) -> float:
	var toward: Vector3 = _toward_city(center)
	return rad_to_deg(atan2(toward.x, toward.z))

func _district_tokens(district: String) -> Array[String]:
	match district:
		"commercial":
			return ["store", "shop", "office", "building"]
		"industrial":
			return ["industrial", "warehouse", "factory", "building"]
		_:
			return ["apartment", "residential", "house", "building"]

func _district_fallback(district: String) -> Color:
	match district:
		"commercial":
			return Color(0.19, 0.20, 0.21, 1.0)
		"industrial":
			return Color(0.19, 0.17, 0.15, 1.0)
		_:
			return Color(0.18, 0.19, 0.18, 1.0)

func _add_courtyard(center: Vector3, size: Vector2, district: String) -> void:
	var color := Color(0.22, 0.30, 0.21, 1.0) if district == "residential" else (Color(0.23, 0.23, 0.22, 1.0) if district == "commercial" else Color(0.15, 0.15, 0.15, 1.0))
	_add_plaza("Courtyard_%03d" % _building_serial, center, size, color)

func _add_plaza(node_name: String, center: Vector3, size: Vector2, color: Color) -> void:
	var pad := MeshInstance3D.new()
	pad.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = Vector3(size.x, 0.08, size.y)
	pad.mesh = mesh
	pad.position = center + Vector3(0.0, 0.12, 0.0)
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.98
	pad.material_override = material
	add_child(pad)

func _add_external_building(node_name: String, size: Vector3, position_value: Vector3, color: Color, variant: int, preferred: Array[String], yaw_degrees: float) -> void:
	var building := QuaterniusCityBuilding3D.new()
	building.name = node_name
	building.target_size = size
	building.fallback_color = color
	building.variant_index = variant
	building.preferred_tokens = preferred
	building.position = position_value
	building.rotation_degrees = Vector3(0.0, yaw_degrees, 0.0)
	add_child(building)

func _add_prop(node_name: String, position_value: Vector3, tokens: Array[String], variant: int, height: float, width: float = 0.0, yaw: float = 0.0) -> void:
	var prop := QuaterniusCityProp3D.new()
	prop.name = node_name
	prop.position = position_value
	prop.search_tokens = tokens
	prop.variant_index = variant
	prop.target_height = height
	prop.target_width = width
	prop.yaw_degrees = yaw
	add_child(prop)

func _add_static_box(parent: Node3D, node_name: String, size: Vector3, position_value: Vector3, color: Color) -> void:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = position_value
	parent.add_child(body)
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.98
	mesh_instance.material_override = material
	body.add_child(mesh_instance)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)

func _restore_city_spawn() -> void:
	if _player == null:
		return
	var spawn_data: Dictionary = GameSession.take_next_city_spawn()
	if spawn_data.is_empty():
		return
	var position_value: Variant = spawn_data.get("position", Vector3.ZERO)
	if position_value is Vector3:
		_player.global_position = position_value as Vector3

func _update_territory() -> void:
	if _player == null:
		return
	var position_value: Vector3 = _player.global_position
	if _point_in_rect(position_value, _commons_rect, 2.0):
		GameSession.set_territory(GameSession.Territory.NEUTRAL)
	elif position_value.x < 0.0:
		GameSession.set_territory(GameSession.Territory.POLICE)
	elif position_value.z < 0.0:
		GameSession.set_territory(GameSession.Territory.CONTRABAND)
	else:
		GameSession.set_territory(GameSession.Territory.ARMS)

func _point_in_rect(position_value: Vector3, rect: Dictionary, margin: float = 0.0) -> bool:
	if rect.is_empty():
		return false
	var center: Vector3 = rect.get("center", Vector3.ZERO) as Vector3
	var width: float = float(rect.get("width", 0.0)) + margin * 2.0
	var depth: float = float(rect.get("depth", 0.0)) + margin * 2.0
	return absf(position_value.x - center.x) <= width * 0.5 and absf(position_value.z - center.z) <= depth * 0.5
