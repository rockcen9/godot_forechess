extends Node

# InputManager: Centralized input handling for all players
# Responsible for: Input capture, input validation, input routing
# API: get_player_input(), is_input_valid(), update()

signal player_direction_changed(player_id: int, direction: Vector2i)
signal player_stick_input(player_id: int, stick_vector: Vector2)
signal player_confirmed(player_id: int)
signal player_cancelled(player_id: int)
signal player_mode_switched(player_id: int)

var player_directions: Dictionary = {
	1: Vector2i.ZERO,
	2: Vector2i.ZERO
}

var last_input_strength: Dictionary = {
	1: Vector2.ZERO,
	2: Vector2.ZERO
}

# Input state tracking
var input_enabled: bool = true
var blocked_players: Array[int] = []

func _ready() -> void:
	print("InputManager initialized")
	set_process_input(true)
	set_process(true)

# Manager API - called by GameManager during update loop
func update(delta: float) -> void:
	if not input_enabled:
		return

	# Check analog stick input for both players
	check_player_analog_input(1, 0)  # Player 1, Controller 0
	check_player_analog_input(2, 1)  # Player 2, Controller 1

func _input(event: InputEvent) -> void:
	if not input_enabled:
		return

	# Skip ui_cancel (ESC) - let GameManager handle pause menu
	if event.is_action_pressed("ui_cancel"):
		return

	# Handle keyboard input for testing
	if event is InputEventKey and event.pressed:
		handle_keyboard_input(event)
	# Handle button confirmation for controllers
	elif event is InputEventJoypadButton and event.pressed:
		handle_controller_input(event)

func handle_keyboard_input(event: InputEventKey) -> void:
	var player_id = 0
	var direction = Vector2i.ZERO

	# Player 1 controls: WASD
	match event.keycode:
		KEY_W:
			player_id = 1
			direction = Vector2i(0, -1)
		KEY_A:
			player_id = 1
			direction = Vector2i(-1, 0)
		KEY_S:
			player_id = 1
			direction = Vector2i(0, 1)
		KEY_D:
			player_id = 1
			direction = Vector2i(1, 0)
		KEY_SPACE:
			player_id = 1
			emit_player_confirmed(player_id)
			return
		# Player 2 controls: Arrow keys
		KEY_UP:
			player_id = 2
			direction = Vector2i(0, -1)
		KEY_LEFT:
			player_id = 2
			direction = Vector2i(-1, 0)
		KEY_DOWN:
			player_id = 2
			direction = Vector2i(0, 1)
		KEY_RIGHT:
			player_id = 2
			direction = Vector2i(1, 0)
		KEY_ENTER:
			player_id = 2
			emit_player_confirmed(player_id)
			return
		# Cancel buttons
		KEY_C:
			player_id = 1
			emit_player_cancelled(player_id)
			return
		KEY_BACKSPACE:
			player_id = 2
			emit_player_cancelled(player_id)
			return
		# Mode switch buttons
		KEY_Q:
			player_id = 1
			emit_player_mode_switched(player_id)
			return
		KEY_SLASH:
			player_id = 2
			emit_player_mode_switched(player_id)
			return

	if player_id > 0 and not is_player_blocked(player_id):
		emit_player_direction_changed(player_id, direction)

func handle_controller_input(event: InputEventJoypadButton) -> void:
	var player_id = 0

	if event.device == 0:
		player_id = 1
	elif event.device == 1:
		player_id = 2
	else:
		return

	if is_player_blocked(player_id):
		return

	match event.button_index:
		JOY_BUTTON_X:
			emit_player_confirmed(player_id)
		JOY_BUTTON_A:
			emit_player_cancelled(player_id)
		JOY_BUTTON_Y:
			emit_player_mode_switched(player_id)

func check_player_analog_input(player_id: int, device: int) -> void:
	if is_player_blocked(player_id):
		return

	# Get analog stick input
	var horizontal = Input.get_joy_axis(device, JOY_AXIS_LEFT_X)
	var vertical = Input.get_joy_axis(device, JOY_AXIS_LEFT_Y)

	var input_vector = Vector2(horizontal, vertical)
	var threshold = 0.5

	# Convert analog input to discrete direction
	var new_direction = Vector2i.ZERO

	# Prioritize the axis with larger absolute value
	if abs(horizontal) > abs(vertical) and abs(horizontal) > threshold:
		new_direction = Vector2i(1 if horizontal > 0 else -1, 0)
	elif abs(vertical) > threshold:
		new_direction = Vector2i(0, 1 if vertical > 0 else -1)

	# Only emit signal if direction changed
	if new_direction != player_directions[player_id]:
		player_directions[player_id] = new_direction
		emit_player_direction_changed(player_id, new_direction)

	# Always emit stick input for continuous rotation in attack mode
	player_stick_input.emit(player_id, input_vector)
	last_input_strength[player_id] = input_vector

# Signal emission with validation
func emit_player_direction_changed(player_id: int, direction: Vector2i) -> void:
	if not is_input_valid(player_id, "direction"):
		return
	player_direction_changed.emit(player_id, direction)

func emit_player_confirmed(player_id: int) -> void:
	if not is_input_valid(player_id, "confirm"):
		return
	player_confirmed.emit(player_id)

func emit_player_cancelled(player_id: int) -> void:
	if not is_input_valid(player_id, "cancel"):
		return
	player_cancelled.emit(player_id)

func emit_player_mode_switched(player_id: int) -> void:
	if not is_input_valid(player_id, "mode_switch"):
		return
	player_mode_switched.emit(player_id)

# Manager API functions
func get_player_direction_vector(player_id: int) -> Vector2i:
	return player_directions.get(player_id, Vector2i.ZERO)

func get_player_stick_input(player_id: int) -> Vector2:
	return last_input_strength.get(player_id, Vector2.ZERO)

func is_input_valid(player_id: int, input_type: String) -> bool:
	if not input_enabled:
		return false
	if is_player_blocked(player_id):
		return false
	# Add additional validation logic here if needed
	return true

func is_player_blocked(player_id: int) -> bool:
	return player_id in blocked_players

# Input state management
func enable_input() -> void:
	input_enabled = true
	print("InputManager: Input enabled globally")

func disable_input() -> void:
	input_enabled = false
	print("InputManager: Input disabled globally")

func block_player_input(player_id: int) -> void:
	if player_id not in blocked_players:
		blocked_players.append(player_id)
	print("InputManager: Player ", player_id, " input blocked")

func unblock_player_input(player_id: int) -> void:
	blocked_players.erase(player_id)
	print("InputManager: Player ", player_id, " input unblocked")

func clear_all_blocks() -> void:
	blocked_players.clear()
	print("InputManager: All player input blocks cleared")

func reset_input_state() -> void:
	player_directions.clear()
	player_directions = {1: Vector2i.ZERO, 2: Vector2i.ZERO}
	last_input_strength.clear()
	last_input_strength = {1: Vector2.ZERO, 2: Vector2.ZERO}
	clear_all_blocks()
	print("InputManager: Input state reset")