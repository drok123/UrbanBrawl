class_name QuaterniusCityBuilding3D
extends Node3D

@export var target_size: Vector3 = Vector3(11.0, 5.0, 13.0)
@export var fallback_color: Color = Color(0.18, 0.20, 0.24, 1.0)
@export var collision_enabled: bool = true
@export var variant_index: int = 0
@export var preferred_tokens: Array[String] = []
@export var yaw_degrees: float = 0.0

var using_external_asset: bool = false
var loaded_asset_path: String = ""

func _ready() -> void:
	_build_collision()
	call_deferred("_load_visual")

func _build_collision() -> void:
	if not collision_enabled:
		return
	var body: StaticBody3D = StaticBody3D.new()
	body.name = "CollisionBody"
	add_child(body)
	var collision: CollisionShape3D = CollisionShape3D.new()
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = target_size
	collision.shape = shape
	body.add_child(collision)

func _load_visual() -> void:
	loaded_asset_path = QuaterniusAssetLocator.find_city_building_variant(variant_index, preferred_tokens)
	if loaded_asset_path.is_empty():
		_build_fallback()
		return

	var packed: PackedScene = load(loaded_asset_path) as PackedScene
	if packed == null:
		_build_fallback()
		return

	var instance: Node = packed.instantiate()
	var visual: Node3D = instance as Node3D
	if visual == null:
		instance.queue_free()
		_build_fallback()
		return

	visual.name = "QuaterniusBuildingVisual"
	add_child(visual)
	if not _fit_visual_to_footprint(visual):
		visual.queue_free()
		_build_fallback()
		return

	visual.rotation_degrees.y = yaw_degrees
	using_external_asset = true
	set_meta(&"quaternius_asset", loaded_asset_path)
	print("Urban Brawl: building ", name, " -> ", loaded_asset_path.get_file())

func _fit_visual_to_footprint(visual: Node3D) -> bool:
	var bounds: AABB = _combined_bounds(visual)
	if bounds.size.length_squared() <= 0.0001:
		return false

	var width_scale: float = target_size.x / maxf(bounds.size.x, 0.001)
	var depth_scale: float = target_size.z / maxf(bounds.size.z, 0.001)
	var height_scale: float = target_size.y / maxf(bounds.size.y, 0.001)
	# Keep architecture proportional. A little height overflow is preferable to
	# flattening a real building into the old graybox dimensions.
	var uniform_scale: float = minf(width_scale, depth_scale) * 0.94
	if height_scale < uniform_scale * 0.45:
		uniform_scale = maxf(height_scale / 0.45, 0.05)
	uniform_scale = clampf(uniform_scale, 0.05, 10.0)
	visual.scale = Vector3.ONE * uniform_scale

	var scaled_center_x: float = (bounds.position.x + bounds.size.x * 0.5) * uniform_scale
	var scaled_center_z: float = (bounds.position.z + bounds.size.z * 0.5) * uniform_scale
	var scaled_min_y: float = bounds.position.y * uniform_scale
	visual.position = Vector3(-scaled_center_x, -target_size.y * 0.5 - scaled_min_y, -scaled_center_z)
	return true

func _combined_bounds(root: Node3D) -> AABB:
	var initialized: bool = false
	var minimum: Vector3 = Vector3.ZERO
	var maximum: Vector3 = Vector3.ZERO
	for node: Node in root.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance: MeshInstance3D = node as MeshInstance3D
		if mesh_instance == null or mesh_instance.mesh == null:
			continue
		var mesh_bounds: AABB = mesh_instance.get_aabb()
		var to_root: Transform3D = root.global_transform.affine_inverse() * mesh_instance.global_transform
		for corner: Vector3 in _aabb_corners(mesh_bounds):
			var point: Vector3 = to_root * corner
			if not initialized:
				minimum = point
				maximum = point
				initialized = true
			else:
				minimum.x = minf(minimum.x, point.x)
				minimum.y = minf(minimum.y, point.y)
				minimum.z = minf(minimum.z, point.z)
				maximum.x = maxf(maximum.x, point.x)
				maximum.y = maxf(maximum.y, point.y)
				maximum.z = maxf(maximum.z, point.z)
	if not initialized:
		return AABB()
	return AABB(minimum, maximum - minimum)

func _aabb_corners(bounds: AABB) -> Array[Vector3]:
	var p: Vector3 = bounds.position
	var s: Vector3 = bounds.size
	return [
		p,
		p + Vector3(s.x, 0.0, 0.0),
		p + Vector3(0.0, s.y, 0.0),
		p + Vector3(0.0, 0.0, s.z),
		p + Vector3(s.x, s.y, 0.0),
		p + Vector3(s.x, 0.0, s.z),
		p + Vector3(0.0, s.y, s.z),
		p + s,
	]

func _build_fallback() -> void:
	var mesh_instance: MeshInstance3D = MeshInstance3D.new()
	mesh_instance.name = "FallbackBlockVisual"
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = target_size
	mesh_instance.mesh = mesh
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = fallback_color
	material.roughness = 0.90
	mesh_instance.material_override = material
	add_child(mesh_instance)
