class_name GrowOperation3D
extends Node3D

@export var cycle_seconds: float = 25.0

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

func interact(_actor: Node) -> void:
	if GameSession.grow_ready_units > 0:
		var harvested: int = GameSession.harvest_grow()
		_flash_message("HARVESTED %d CONTRABAND" % harvested)
		return

	if GameSession.grow_cycle_left > 0.0:
		_flash_message("BATCH STILL GROWING")
		return

	if GameSession.start_grow_cycle(cycle_seconds):
		_flash_message("GROW CYCLE STARTED")

func get_interaction_prompt(_actor: Node) -> String:
	if GameSession.grow_ready_units > 0:
		return "GROW ROOM — %d READY\nF  HARVEST" % GameSession.grow_ready_units
	if GameSession.grow_cycle_left > 0.0:
		return "GROW ROOM — %.0fs LEFT" % ceilf(GameSession.grow_cycle_left)
	return "GROW ROOM\nF  START %ds BATCH" % int(cycle_seconds)

func _flash_message(value: String) -> void:
	_message = value
	_message_left = 1.3
	_refresh_label()

func _refresh_label() -> void:
	if _label == null:
		return
	_label.text = _message if not _message.is_empty() else get_interaction_prompt(null)

func _build_visuals() -> void:
	for x_offset: float in [-0.85, 0.0, 0.85]:
		var planter: MeshInstance3D = MeshInstance3D.new()
		var box: BoxMesh = BoxMesh.new()
		box.size = Vector3(0.62, 0.42, 1.0)
		planter.mesh = box
		planter.position = Vector3(x_offset, 0.22, 0.0)
		var material: StandardMaterial3D = StandardMaterial3D.new()
		material.albedo_color = Color(0.12, 0.28, 0.14, 1.0)
		material.roughness = 0.9
		planter.material_override = material
		add_child(planter)

	_label = Label3D.new()
	_label.position = Vector3(0.0, 1.55, 0.0)
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.font_size = 38
	_label.outline_size = 10
	_label.pixel_size = 0.008
	add_child(_label)
