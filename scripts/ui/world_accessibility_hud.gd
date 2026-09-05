class_name WorldAccessibilityHUD
extends CanvasLayer

@export var player_path: NodePath = NodePath("../Player")
@export var prompt_label_path: NodePath = NodePath("InteractionPrompt")

var _player: Node3D = null
var _prompt_label: Label = null

func _ready() -> void:
	_player = get_node_or_null(player_path) as Node3D
	_prompt_label = get_node_or_null(prompt_label_path) as Label
	_update_prompt()

func _process(_delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		_player = get_node_or_null(player_path) as Node3D
	_update_prompt()

func _unhandled_input(event: InputEvent) -> void:
	var key_event: InputEventKey = event as InputEventKey
	if key_event == null or not key_event.pressed or key_event.echo:
		return

	var toggle_requested: bool = key_event.keycode == KEY_F11
	if key_event.alt_pressed and (key_event.keycode == KEY_ENTER or key_event.physical_keycode == KEY_ENTER):
		toggle_requested = true

	if not toggle_requested:
		return

	_toggle_fullscreen()
	get_viewport().set_input_as_handled()

func _toggle_fullscreen() -> void:
	var mode: int = DisplayServer.window_get_mode()
	if mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

func _update_prompt() -> void:
	if _prompt_label == null:
		return
	if _player == null:
		_prompt_label.text = "F11 / ALT+ENTER   FULLSCREEN"
		return

	var nearest_prompt: String = ""
	var best_distance_sq: float = INF
	var interaction_radius: float = 2.2
	var radius_value: Variant = _player.get("interaction_radius")
	if radius_value != null:
		interaction_radius = maxf(float(radius_value), 0.5)
	var max_distance_sq: float = interaction_radius * interaction_radius

	for node: Node in get_tree().get_nodes_in_group("world_interactable"):
		var interactable: Node3D = node as Node3D
		if interactable == null or not interactable.has_method("get_interaction_prompt"):
			continue
		var distance_sq: float = _player.global_position.distance_squared_to(interactable.global_position)
		if distance_sq > max_distance_sq or distance_sq >= best_distance_sq:
			continue
		var prompt_value: Variant = interactable.call("get_interaction_prompt", _player)
		nearest_prompt = str(prompt_value)
		best_distance_sq = distance_sq

	for node: Node in get_tree().get_nodes_in_group("weapon_pickup"):
		var pickup: WorldWeaponPickup3D = node as WorldWeaponPickup3D
		if pickup == null or not pickup.is_available():
			continue
		var distance_sq: float = _player.global_position.distance_squared_to(pickup.global_position)
		if distance_sq > max_distance_sq or distance_sq >= best_distance_sq:
			continue
		var item: Item = pickup.get_item()
		var item_name: String = "WEAPON"
		if item != null and item.base != null:
			item_name = "%s %s" % [WeaponItemRules.rarity_name(item).to_upper(), item.base.name.to_upper()]
		nearest_prompt = "F   PICK UP %s" % item_name
		best_distance_sq = distance_sq

	if nearest_prompt.is_empty():
		_prompt_label.text = "F11 / ALT+ENTER   FULLSCREEN"
	else:
		_prompt_label.text = nearest_prompt + "\nF11 / ALT+ENTER   FULLSCREEN"
