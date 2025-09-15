extends Node

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

func _ready() -> void:
	# Enable input processing for button events
	set_process_input(true)
	# Enable processing for continuous analog stick checking
	set_process(true)

func _process(_delta: float) -> void:
	# Check analog stick input for both players
	check_player_analog_input(1, 0)  # Player 1, Controller 0
	check_player_analog_input(2, 1)  # Player 2, Controller 1

func _input(event: InputEvent) -> void:
	# Handle keyboard input for testing
	if event is InputEventKey and event.pressed:
		handle_keyboard_input(event)
	# Handle button confirmation for controllers
	elif event is InputEventJoypadButton and event.pressed:
		if event.device == 0 and event.button_index == JOY_BUTTON_X:
			player_confirmed.emit(1)
		elif event.device == 1 and event.button_index == JOY_BUTTON_X:
			player_confirmed.emit(2)
		elif event.device == 0 and event.button_index == JOY_BUTTON_A:
			player_cancelled.emit(1)
		elif event.device == 1 and event.button_index == JOY_BUTTON_A:
			player_cancelled.emit(2)
		elif event.device == 0 and event.button_index == JOY_BUTTON_Y:
			player_mode_switched.emit(1)
		elif event.device == 1 and event.button_index == JOY_BUTTON_Y:
			player_mode_switched.emit(2)

func check_player_analog_input(player_id: int, device: int) -> void:
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
		player_direction_changed.emit(player_id, new_direction)

	# Always emit stick input for continuous rotation in attack mode
	player_stick_input.emit(player_id, input_vector)

	last_input_strength[player_id] = input_vector

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
			direction = Vector2i(-1, 0)  # A = Left = decrease X
		KEY_S:
			player_id = 1
			direction = Vector2i(0, 1)   # S = Down = increase Y
		KEY_D:
			player_id = 1
			direction = Vector2i(1, 0)   # D = Right = increase X
		KEY_SPACE:
			player_id = 1
			player_confirmed.emit(player_id)
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
			player_confirmed.emit(player_id)
			return
		# Cancel buttons
		KEY_ESCAPE:
			player_id = 1
			player_cancelled.emit(player_id)
			return
		KEY_BACKSPACE:
			player_id = 2
			player_cancelled.emit(player_id)
			return
		# Mode switch buttons
		KEY_Q:
			player_id = 1
			player_mode_switched.emit(player_id)
			return
		KEY_SLASH:
			player_id = 2
			player_mode_switched.emit(player_id)
			return

	if player_id > 0:
		player_direction_changed.emit(player_id, direction)

func get_player_direction_vector(player_id: int) -> Vector2i:
	return player_directions[player_id]