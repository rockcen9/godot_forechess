extends Node

# PlayerController: Handles player state and actions through composition
# Responsible for: Player state management, confirmation handling, mode switching
# API: reset_confirmation_state(), get_current_mode(), is_ready_for_action()

class_name PlayerController

signal player_state_changed(player_id: int, state_data: Dictionary)
signal player_action_ready(player_id: int, action_data: Dictionary)

var player_id: int
var player_entity: Node
var confirmation_state: bool = false
var current_mode: int = 0  # 0 = MOVE, 1 = ATTACK

# State tracking
var last_confirmed_direction: Vector2i = Vector2i.ZERO
var attack_target_locked: bool = false

func _ready() -> void:
	# Connect to EventBus for player-related events
	EventBus.player_confirmed_action.connect(_on_player_confirmed_action)

func initialize(player_node: Node) -> void:
	player_entity = player_node
	player_id = player_node.player_id if player_node.has_method("get_player_id") else 0

	# Connect to player's mode changes if available
	if player_entity.has_signal("mode_changed"):
		player_entity.mode_changed.connect(_on_player_mode_changed)

# Controller API - called by managers instead of direct entity access
func reset_confirmation_state() -> void:
	confirmation_state = false
	last_confirmed_direction = Vector2i.ZERO
	attack_target_locked = false

	# Delegate to entity if it has specific reset logic
	if player_entity and player_entity.has_method("reset_confirmation_state"):
		player_entity.reset_confirmation_state()

	emit_state_changed()

func get_current_mode() -> int:
	if player_entity and player_entity.has_method("get_current_mode"):
		return player_entity.get_current_mode()
	return current_mode

func set_confirmation_state(confirmed: bool, direction: Vector2i = Vector2i.ZERO) -> void:
	confirmation_state = confirmed
	if confirmed:
		last_confirmed_direction = direction

	emit_state_changed()

func is_ready_for_action() -> bool:
	match get_current_mode():
		0: # MOVE mode
			return confirmation_state
		1: # ATTACK mode
			return is_attack_ready()
		_:
			return false

func is_attack_ready() -> bool:
	if not player_entity:
		return false

	# Check if player has shooting indicator and it's locked
	if player_entity.has_method("get_shooting_indicator"):
		var indicator = player_entity.get_shooting_indicator()
		return indicator and indicator.has_method("is_indicator_locked") and indicator.is_indicator_locked()

	# Fallback check
	return attack_target_locked

func get_confirmed_direction() -> Vector2i:
	return last_confirmed_direction

func get_action_data() -> Dictionary:
	var action_data = {
		"player_id": player_id,
		"mode": get_current_mode(),
		"confirmed": confirmation_state,
		"ready": is_ready_for_action()
	}

	match get_current_mode():
		0: # MOVE mode
			action_data["direction"] = last_confirmed_direction
		1: # ATTACK mode
			action_data["attack_ready"] = is_attack_ready()
			if player_entity and player_entity.has_method("get_shooting_indicator"):
				var indicator = player_entity.get_shooting_indicator()
				if indicator:
					action_data["attack_direction"] = indicator.rotation

	return action_data

# Entity delegation methods
func execute_movement(direction: Vector2i) -> bool:
	if not player_entity or not player_entity.has_method("move_by_direction"):
		return false

	return player_entity.move_by_direction(direction)

func get_position() -> Vector2i:
	if not player_entity:
		return Vector2i.ZERO

	return Vector2i(player_entity.grid_x, player_entity.grid_y)

func get_entity() -> Node:
	return player_entity

# Event handlers
func _on_player_confirmed_action(player: Node) -> void:
	if player != player_entity:
		return

	match get_current_mode():
		0: # MOVE mode - handled by input system
			pass
		1: # ATTACK mode
			attack_target_locked = true
			confirmation_state = true
			emit_state_changed()
			player_action_ready.emit(player_id, get_action_data())

func _on_player_mode_changed(new_mode: int) -> void:
	current_mode = new_mode
	# Reset state when mode changes
	reset_confirmation_state()

# State emission
func emit_state_changed() -> void:
	var state_data = {
		"confirmed": confirmation_state,
		"mode": get_current_mode(),
		"ready": is_ready_for_action(),
		"direction": last_confirmed_direction
	}

	player_state_changed.emit(player_id, state_data)

# Utility methods
func has_valid_entity() -> bool:
	return player_entity != null and is_instance_valid(player_entity)

func get_debug_info() -> Dictionary:
	return {
		"player_id": player_id,
		"confirmed": confirmation_state,
		"mode": get_current_mode(),
		"ready": is_ready_for_action(),
		"position": get_position(),
		"entity_valid": has_valid_entity()
	}