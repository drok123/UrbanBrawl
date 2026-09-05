class_name WeaponVendorStand3D
extends Node3D

@export var base_item: ItemBase
@export var combat_profile: WeaponCombatProfile
@export var price: int = 200
@export var stand_color: Color = Color(0.22, 0.20, 0.18, 1.0)

var _label: Label3D = null
var _message_left: float = 0.0
var _message: String = ""

func _ready() -> void:
	add_to_group("world_interactable")
	_build_visuals()
	_refresh_label()

func _process(delta: float) -> void:
	if _message_left > 0.0:
		_message_left = maxf(_message_left - delta, 0.0)
		if _message_left <= 0.0:
			_message = ""
			_refresh_label()

func interact(actor: Node) -> void:
	if actor == null or base_item == null or combat_profile == null:
		return
	if not actor.has_method("equip_weapon"):
		return
	if not GameSession.spend_cash(price):
		_flash_message("NOT ENOUGH CASH")
		return

	if actor.has_method("drop_equipped_weapon"):
		actor.call("drop_equipped_weapon", 0.8)

	var item: Item = WeaponItemRules.create_rolled_item(base_item)
	if item == null:
		GameSession.add_cash(price)
		_flash_message("STOCK ERROR")
		return

	var equipped_value: Variant = actor.call("equip_weapon", item, combat_profile)
	var equipped: bool = bool(equipped_value)
	if not equipped:
		GameSession.add_cash(price)
		_flash_message("CAN'T EQUIP")
		return

	GameSession.capture_player(actor)
	_flash_message("SOLD — %s %s" % [WeaponItemRules.rarity_name(item).to_upper(), base_item.name.to_upper()])

func get_interaction_prompt(_actor: Node) -> String:
	var item_name: String = "WEAPON"
	if base_item != null:
		item_name = base_item.name.to_upper()
	return "%s  $%d\nF  BUY" % [item_name, price]

func _flash_message(value: String) -> void:
	_message = value
	_message_left = 1.25
	_refresh_label()

func _refresh_label() -> void:
	if _label == null:
		return
	_label.text = _message if not _message.is_empty() else get_interaction_prompt(null)

func _build_visuals() -> void:
	var stand: MeshInstance3D = MeshInstance3D.new()
	var box: BoxMesh = BoxMesh.new()
	box.size = Vector3(1.4, 0.75, 0.8)
	stand.mesh = box
	stand.position = Vector3(0.0, 0.38, 0.0)
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = stand_color
	material.roughness = 0.9
	stand.material_override = material
	add_child(stand)

	var item_mesh: MeshInstance3D = MeshInstance3D.new()
	var cylinder: CylinderMesh = CylinderMesh.new()
	cylinder.height = maxf(combat_profile.held_length if combat_profile != null else 1.0, 0.45)
	cylinder.top_radius = maxf(combat_profile.held_width * 0.45 if combat_profile != null else 0.06, 0.035)
	cylinder.bottom_radius = maxf(combat_profile.held_width * 0.58 if combat_profile != null else 0.08, 0.045)
	cylinder.radial_segments = 10
	item_mesh.mesh = cylinder
	item_mesh.position = Vector3(0.0, 0.92, 0.0)
	item_mesh.rotation_degrees = Vector3(0.0, 0.0, 75.0)
	var item_material: StandardMaterial3D = StandardMaterial3D.new()
	item_material.albedo_color = combat_profile.held_color if combat_profile != null else Color(0.7, 0.7, 0.7, 1.0)
	item_mesh.material_override = item_material
	add_child(item_mesh)

	_label = Label3D.new()
	_label.position = Vector3(0.0, 1.65, 0.0)
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.font_size = 24
	_label.outline_size = 6
	add_child(_label)
