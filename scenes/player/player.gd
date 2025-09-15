extends Node2D
class_name Player

enum PlayerMode {
	MOVE,
	ATTACK
}

signal player_mode_changed(player_id: int, new_mode: PlayerMode)

var grid_x: int
var grid_y: int
var player_id: int
var current_mode: PlayerMode = PlayerMode.MOVE

# Preview sprites
@onready var next_position_sprite: Sprite2D
@onready var confirmed_sprite: Sprite2D

var preview_visible: bool = false
var preview_confirmed: bool = false
var preview_x: int = 0
var preview_y: int = 0

func setup(x: int, y: int, id: int) -> void:
	grid_x = x
	grid_y = y
	player_id = id

	# Set position based on grid coordinates, centered within the tile
	position = Vector2(x * 20 + 10, y * 20 + 10)  # +10 to center in 20px tile

func _ready() -> void:
	# Create preview sprites
	next_position_sprite = Sprite2D.new()
	next_position_sprite.texture = load("res://assets/indicators/next_position.png")
	next_position_sprite.visible = false
	get_parent().add_child(next_position_sprite)

	confirmed_sprite = Sprite2D.new()
	confirmed_sprite.texture = load("res://assets/indicators/confirmed.png")
	confirmed_sprite.visible = false
	get_parent().add_child(confirmed_sprite)

	# Connect to input manager signals
	var input_manager = get_node("../../InputManager")
	if input_manager:
		input_manager.player_direction_changed.connect(_on_direction_changed)
		input_manager.player_confirmed.connect(_on_player_confirmed)
		input_manager.player_cancelled.connect(_on_player_cancelled)
		input_manager.player_mode_switched.connect(_on_mode_switched)

func _on_direction_changed(player_id_signal: int, direction: Vector2i) -> void:
	if player_id_signal != player_id:
		return

	# Don't respond to input if already confirmed
	if preview_confirmed:
		return

	# Only show preview during decision phase
	var game_manager = get_node("../../GameManager")
	if not game_manager or not game_manager.is_decision_phase():
		return

	if direction == Vector2i(0, 0):
		# No direction selected, hide preview (only if not confirmed)
		if not preview_confirmed:
			hide_preview()
	else:
		# Calculate target position
		var target_x = grid_x + direction.x
		var target_y = grid_y + direction.y

		# Check if target is valid (within bounds)
		if target_x >= 0 and target_x < 8 and target_y >= 0 and target_y < 8:
			show_preview(target_x, target_y)
		else:
			hide_preview()

func _on_player_confirmed(player_id_signal: int) -> void:
	if player_id_signal != player_id:
		return

	# Don't allow multiple confirmations
	if preview_confirmed:
		print("Player ", player_id, " already confirmed - ignoring")
		return

	print("Player ", player_id, " received confirmation signal")

	# Only confirm during decision phase
	var game_manager = get_node("../../GameManager")
	if not game_manager or not game_manager.is_decision_phase():
		print("Player ", player_id, " confirmation rejected - not in decision phase")
		return

	# Confirm the preview if it's visible
	if preview_visible:
		print("Player ", player_id, " confirming preview - locking input")
		confirm_preview()
	else:
		print("Player ", player_id, " confirmation rejected - no preview visible")

func show_preview(target_x: int, target_y: int) -> void:
	preview_visible = true
	preview_confirmed = false
	preview_x = target_x
	preview_y = target_y

	# Position and show next position sprite
	next_position_sprite.position = Vector2(target_x * 20 + 10, target_y * 20 + 10)
	next_position_sprite.visible = true
	confirmed_sprite.visible = false

func confirm_preview() -> void:
	if not preview_visible:
		return

	preview_confirmed = true

	# Switch to confirmed sprite
	confirmed_sprite.position = Vector2(preview_x * 20 + 10, preview_y * 20 + 10)
	next_position_sprite.visible = false
	confirmed_sprite.visible = true

func hide_preview() -> void:
	preview_visible = false
	preview_confirmed = false

	next_position_sprite.visible = false
	confirmed_sprite.visible = false

func move_to(new_x: int, new_y: int) -> void:
	grid_x = new_x
	grid_y = new_y
	position = Vector2(new_x * 20 + 10, new_y * 20 + 10)

	# Hide preview after movement
	hide_preview()

func _on_player_cancelled(player_id_signal: int) -> void:
	if player_id_signal != player_id:
		return

	# Only allow cancel if confirmed
	if not preview_confirmed:
		print("Player ", player_id, " cancel ignored - not confirmed")
		return

	print("Player ", player_id, " cancelled confirmation - input re-enabled")

	# Reset confirmation state
	preview_confirmed = false

	# Hide confirmed sprite and show preview again at current stick position
	confirmed_sprite.visible = false

	# Get current stick direction and show preview if valid
	var input_manager = get_node("../../InputManager")
	if input_manager:
		var current_direction = input_manager.get_player_direction_vector(player_id)
		if current_direction != Vector2i.ZERO:
			var target_x = grid_x + current_direction.x
			var target_y = grid_y + current_direction.y
			if target_x >= 0 and target_x < 8 and target_y >= 0 and target_y < 8:
				show_preview(target_x, target_y)
			else:
				hide_preview()
		else:
			hide_preview()

func reset_confirmation_state() -> void:
	# Reset confirmation state for new turn
	preview_confirmed = false
	hide_preview()
	print("Player ", player_id, " confirmation state reset - input enabled")

func _on_mode_switched(player_id_signal: int) -> void:
	if player_id_signal != player_id:
		return

	# Switch between MOVE and ATTACK modes
	if current_mode == PlayerMode.MOVE:
		current_mode = PlayerMode.ATTACK
		# Clear confirmed state when switching to attack mode
		if preview_confirmed:
			preview_confirmed = false
			hide_preview()
			print("Player ", player_id, " switched to Attack mode - cleared confirmed state")
	else:
		current_mode = PlayerMode.MOVE

	print("Player ", player_id, " switched to mode: ", PlayerMode.keys()[current_mode])
	player_mode_changed.emit(player_id, current_mode)

func get_current_mode() -> PlayerMode:
	return current_mode

func get_mode_name() -> String:
	match current_mode:
		PlayerMode.MOVE:
			return "Move"
		PlayerMode.ATTACK:
			return "Attack"
		_:
			return "Unknown"