class_name WorldWeaponPickup3D
extends Node3D

@export var base_item: ItemBase
@export var combat_profile: WeaponCombatProfile
@export var hover_height: float = 0.28
@export var spin_speed: float = 0.75

var item_instance: Item = null
var _visual_root: Node3D = null
var _label: Label3D = null
var _rarity_disc: MeshInstance3D = null

func _ready() -> void:
	add_to_group("weapon_pickup")
	if item_instance == null and base_item != null:
		item_instance = WeaponItemRules.create_rolled_item(base_item)
	_build_visuals()
	_update_presentation()

func _process(delta: float) -> void:
	if _visual_root != null:
		_visual_root.rotation.y += spin_speed * delta

func is_available() -> bool:
	return item_instance != null and combat_profile != null

func take_item() -> Item:
	if not is_available():
		return null
	var result: Item = item_instance
	item_instance = null
	queue_free()
	return result

func get_profile() -> WeaponCombatProfile:
	return combat_profile

func get_item() -> Item:
	return item_instance

func _build_visuals() -> void:
	_visual_root = Node3D.new()
	_visual_root.name = "PickupVisual"
	_visual_root.position = Vector3(0.0, hover_height, 0.0)
	add_child(_visual_root)

	var weapon_mesh: MeshInstance3D = MeshInstance3D.new()
	weapon_mesh.name = "WeaponMesh"
	var cylinder: CylinderMesh = CylinderMesh.new()
	cylinder.top_radius = 0.065
	cylinder.bottom_radius = 0.09
	cylinder.height = maxf(combat_profile.held_length if combat_profile != null else 1.5, 0.5)
	cylinder.radial_segments = 12
	weapon_mesh.mesh = cylinder
	weapon_mesh.rotation_degrees = Vector3(0.0, 0.0, 72.0)

	var weapon_material: StandardMaterial3D = StandardMaterial3D.new()
	weapon_material.albedo_color = combat_profile.held_color if combat_profile != null else Color(0.58, 0.38, 0.20, 1.0)
	weapon_material.roughness = 0.72
	weapon_mesh.material_override = weapon_material
	_visual_root.add_child(weapon_mesh)

	_rarity_disc = MeshInstance3D.new()
	_rarity_disc.name = "RarityDisc"
	var disc: CylinderMesh = CylinderMesh.new()
	disc.top_radius = 0.62
	disc.bottom_radius = 0.62
	disc.height = 0.018
	disc.radial_segments = 40
	_rarity_disc.mesh = disc
	_rarity_disc.position = Vector3(0.0, -hover_height + 0.03, 0.0)
	add_child(_rarity_disc)

	_label = Label3D.new()
	_label.name = "PickupLabel"
	_label.position = Vector3(0.0, 1.05, 0.0)
	_label.font_size = 24
	_label.outline_size = 6
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(_label)

func _update_presentation() -> void:
	if item_instance == null:
		return
	var rarity_name: String = WeaponItemRules.rarity_name(item_instance)
	var rarity_color: Color = WeaponItemRules.rarity_color(item_instance)
	var item_name: String = item_instance.base.name if item_instance.base != null else "Weapon"
	var affix_text: String = _affix_summary(item_instance)

	if _label != null:
		_label.modulate = rarity_color
		_label.text = "%s %s\nF  PICK UP%s" % [rarity_name.to_upper(), item_name.to_upper(), affix_text]

	if _rarity_disc != null:
		var rarity_material: StandardMaterial3D = StandardMaterial3D.new()
		rarity_material.albedo_color = Color(rarity_color.r, rarity_color.g, rarity_color.b, 0.34)
		rarity_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		rarity_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_rarity_disc.material_override = rarity_material

func _affix_summary(item: Item) -> String:
	if item == null or item.affixes.is_empty():
		return ""
	var names: Array[String] = []
	for affix: AffixInstance in item.affixes:
		names.append(affix.id.replace("_", " ").capitalize())
	return "\n" + " / ".join(names)
