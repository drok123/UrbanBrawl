class_name PlayerCharacterStyle
extends Node

const ACCENT_PARTS: Array[StringName] = [&"Waist", &"Face", &"HandMesh", &"Foot"]

func _ready() -> void:
	call_deferred("_apply_style")

func _apply_style() -> void:
	if not GameSession.character_created:
		return
	var visual: Node = get_parent().get_node_or_null("CharacterVisual")
	if visual == null:
		return
	var body_material: StandardMaterial3D = StandardMaterial3D.new()
	body_material.albedo_color = GameSession.character_body_color
	body_material.roughness = 0.74
	var accent_material: StandardMaterial3D = StandardMaterial3D.new()
	accent_material.albedo_color = GameSession.character_accent_color
	accent_material.roughness = 0.82
	_apply_recursive(visual, body_material, accent_material)

func _apply_recursive(node: Node, body_material: StandardMaterial3D, accent_material: StandardMaterial3D) -> void:
	for child: Node in node.get_children():
		var mesh_instance: MeshInstance3D = child as MeshInstance3D
		if mesh_instance != null:
			var use_accent: bool = child.name in ACCENT_PARTS
			mesh_instance.material_override = accent_material if use_accent else body_material
		_apply_recursive(child, body_material, accent_material)
