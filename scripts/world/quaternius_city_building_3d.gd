class_name QuaterniusCityBuilding3D
extends Node3D

# target_size is retained as the fallback/debug block size for compatibility.
# External Quaternius architecture is NOT stretched to target_size anymore.
@export var target_size: Vector3 = Vector3(16.0, 6.0, 14.0)
@export var max_footprint: Vector2 = Vector2(18.0, 18.0)
@export var fallback_color: Color = Color(0.18, 0.20, 0.24, 1.0)
@export var collision_enabled: bool = true
@export var variant_index: int = 0
@export var preferred_tokens: Array[String] = []
@export var yaw_degrees: float = 0.0
@export var allow_upscale: bool = false

var using_external_asset: bool = false
var loaded_asset_path: String = ""
var fitted_size: Vector3 = Vector3.ZERO
var applied_scale: float = 1.0

func _ready() -> void:
	call_deferred("_load_visual")

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
	var bounds: AABB = _combined_bounds(visual)
	if bounds.size.length_squared() <= 0.0001:
		visual.queue_free()
		_build_fallback()
		return

	_fit_native_visual(visual, bounds)
	visual.rotation_degrees.y = yaw_degrees
	if collision_enabled:
		_build_fitted_collision()
	using_external_asset = true
	set_meta(&"quaternius_asset", loaded_asset_path)
	set_meta(&"quaternius_native_scale", applied_scale)
	print("Urban Brawl: building ", name, " -> ", loaded_asset_path.get_file(), " | natural fit ", fitted_size, " @ ", snappedf(applied_scale, 0.001))

func _fit_native_visual(visual: Node3D, bounds: AABB) -> void:
	# Downtown MegaKit is authored in meter scale. Respect that 1:1 scale and only
	# shrink a building when its real footprint cannot fit the allocated lot.
	var footprint := max_footprint
	if footprint.x <= 0.01 or footprint.y <= 0.01:
		footprint = Vector2(maxf(target_size.x, 1.0), maxf(target_size.z, 1.0))
	var fit_x: float = footprint.x / maxf(bounds.size.x, 0.001)
	var fit_z: float = footprint.y / maxf(bounds.size.z, 0.001)
	var fit_scale: float = minf(fit_x, fit_z) * 0.97
	applied_scale = fit_scale if allow_upscale else minf(1.0, fit_scale)
	applied_scale = clampf(applied_scale, 0.05, 4.0)
	visual.scale = Vector3.ONE * applied_scale

	fitted_size = bounds.size * applied_scale
	var scaled_center_x: float = (bounds.position.x + bounds.size.x * 0.5) * applied_scale
	var scaled_center_z: float = (bounds.position.z + bounds.size.z * 0.5) * applied_scale
	var scaled_min_y: float = bounds.position.y * applied_scale
	# Node origin is ground-center. This makes authored lots/frontages independent
	# of the building's height and removes the old graybox-center assumption.
	visual.position = Vector3(-scaled_center_x, -scaled_min_y, -scaled_center_z)

func _build_fitted_collision() -> void:
	if fitted_size.length_squared() <= 0.0001:
		return
	var body := StaticBody3D.new()
	body.name = "CollisionBody"
	add_child(body)
	var collision := CollisionShape3D.new()
	collision.position = Vector3(0.0, fitted_size.y * 0.5, 0.0)
	var shape := BoxShape3D.new()
	# Slight inset avoids awnings/fire escapes turning into invisible sidewalk walls.
	shape.size = Vector3(maxf(fitted_size.x * 0.90, 0.5), maxf(fitted_size.y * 0.96, 0.5), maxf(fitted_size.z * 0.90, 0.5))
	collision.shape = shape
	body.add_child(collision)

func _combined_bounds(root: Node3D) -> AABB:
	var initialized: bool = false
	var minimum := Vector3.ZERO
	var maximum := Vector3.ZERO
	for node: Node in root.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := node as MeshInstance3D
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
	fitted_size = target_size
	applied_scale = 1.0
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = "FallbackBlockVisual"
	var mesh := BoxMesh.new()
	mesh.size = target_size
	mesh_instance.mesh = mesh
	mesh_instance.position = Vector3(0.0, target_size.y * 0.5, 0.0)
	var material := StandardMaterial3D.new()
	material.albedo_color = fallback_color
	material.roughness = 0.90
	mesh_instance.material_override = material
	add_child(mesh_instance)
	if collision_enabled:
		_build_fitted_collision()
