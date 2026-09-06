class_name QuaterniusCityProp3D
extends Node3D

@export var search_tokens: Array[String] = []
@export var variant_index: int = 0
@export var target_height: float = 1.5
@export var target_width: float = 0.0
@export var yaw_degrees: float = 0.0

var loaded_asset_path: String = ""

func _ready() -> void:
	call_deferred("_load_visual")

func _load_visual() -> void:
	loaded_asset_path = QuaterniusAssetLocator.find_city_prop(search_tokens, variant_index)
	if loaded_asset_path.is_empty():
		queue_free()
		return
	var packed: PackedScene = load(loaded_asset_path) as PackedScene
	if packed == null:
		queue_free()
		return
	var instance: Node = packed.instantiate()
	var visual: Node3D = instance as Node3D
	if visual == null:
		instance.queue_free()
		queue_free()
		return
	add_child(visual)
	var bounds: AABB = _combined_bounds(visual)
	if bounds.size.length_squared() <= 0.0001:
		visual.queue_free()
		queue_free()
		return
	var scale_factor: float = target_height / maxf(bounds.size.y, 0.001)
	if target_width > 0.0:
		scale_factor = minf(scale_factor, target_width / maxf(maxf(bounds.size.x, bounds.size.z), 0.001))
	scale_factor = clampf(scale_factor, 0.05, 8.0)
	visual.scale = Vector3.ONE * scale_factor
	var center_x: float = (bounds.position.x + bounds.size.x * 0.5) * scale_factor
	var center_z: float = (bounds.position.z + bounds.size.z * 0.5) * scale_factor
	var min_y: float = bounds.position.y * scale_factor
	visual.position = Vector3(-center_x, -min_y, -center_z)
	visual.rotation_degrees.y = yaw_degrees
	set_meta(&"quaternius_asset", loaded_asset_path)

func _combined_bounds(root: Node3D) -> AABB:
	var initialized: bool = false
	var minimum: Vector3 = Vector3.ZERO
	var maximum: Vector3 = Vector3.ZERO
	for node: Node in root.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance: MeshInstance3D = node as MeshInstance3D
		if mesh_instance == null or mesh_instance.mesh == null:
			continue
		var bounds: AABB = mesh_instance.get_aabb()
		var to_root: Transform3D = root.global_transform.affine_inverse() * mesh_instance.global_transform
		for corner: Vector3 in _aabb_corners(bounds):
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
	return AABB(minimum, maximum - minimum) if initialized else AABB()

func _aabb_corners(bounds: AABB) -> Array[Vector3]:
	var p: Vector3 = bounds.position
	var s: Vector3 = bounds.size
	return [p, p + Vector3(s.x, 0, 0), p + Vector3(0, s.y, 0), p + Vector3(0, 0, s.z), p + Vector3(s.x, s.y, 0), p + Vector3(s.x, 0, s.z), p + Vector3(0, s.y, s.z), p + s]
