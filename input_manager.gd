extends Node

signal player_direction_changed(player_id: int, direction: Vector2i)
signal player_confirmed(player_id: int)

enum Direction {
	NONE,
	UP,
	DOWN,
	LEFT,
	RIGHT
}

var player_directions: Dictionary = {
	1: Direction.NONE,
	2: Direction.NONE
}

func _ready() -> void:
	# Enable input processing
	set_process_input(true)

func _input(event: InputEvent) -> void:
	# Handle keyboard input for testing
	if event is InputEventKey and event.pressed:
		handle_keyboard_input(event)
	# Player 1 controls (device 0)
	elif event.device == 0:
		handle_player_input(1, event)
	# Player 2 controls (device 1)
	elif event.device == 1:
		handle_player_input(2, event)

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

	if player_id > 0:
		print("Keyboard input - Player ", player_id, " direction: ", direction)
		player_direction_changed.emit(player_id, direction)

func handle_player_input(player_id: int, event: InputEvent) -> void:
	# Handle direction input
	if event is InputEventJoypadMotion:
		handle_joystick_direction(player_id, event)
	elif event is InputEventJoypadButton:
		handle_joystick_button(player_id, event)

func handle_joystick_direction(player_id: int, event: InputEventJoypadMotion) -> void:
	var new_direction = Direction.NONE

	# Left stick horizontal (axis 0)
	if event.axis == JOY_AXIS_LEFT_X:
		if event.axis_value < -0.5:
			new_direction = Direction.LEFT
		elif event.axis_value > 0.5:
			new_direction = Direction.RIGHT

	# Left stick vertical (axis 1)
	elif event.axis == JOY_AXIS_LEFT_Y:
		if event.axis_value < -0.5:
			new_direction = Direction.UP
		elif event.axis_value > 0.5:
			new_direction = Direction.DOWN

	# Update direction if changed
	if new_direction != player_directions[player_id]:
		player_directions[player_id] = new_direction
		var direction_vector = direction_to_vector(new_direction)
		print("Player ", player_id, " direction changed to: ", direction_vector)
		player_direction_changed.emit(player_id, direction_vector)

func handle_joystick_button(player_id: int, event: InputEventJoypadButton) -> void:
	# Xbox X button (button 0)
	if event.button_index == JOY_BUTTON_A and event.pressed:
		player_confirmed.emit(player_id)

func direction_to_vector(direction: Direction) -> Vector2i:
	match direction:
		Direction.UP:
			return Vector2i(0, -1)
		Direction.DOWN:
			return Vector2i(0, 1)
		Direction.LEFT:
			return Vector2i(-1, 0)
		Direction.RIGHT:
			return Vector2i(1, 0)
		_:
			return Vector2i(0, 0)

func get_player_direction_vector(player_id: int) -> Vector2i:
	return direction_to_vector(player_directions[player_id])