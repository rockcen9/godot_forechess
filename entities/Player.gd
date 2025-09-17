extends Node2D

# Lightweight Player Entity - delegates logic to Managers
# Responsibilities: State storage, response to Manager calls, basic rendering

enum PlayerMode {
	MOVE,
	ATTACK
}

signal player_mode_changed(player_id: int, new_mode: PlayerMode)

# Core state - kept in entity
var grid_x: int
var grid_y: int
var player_id: int
var current_mode: PlayerMode = PlayerMode.MOVE

# Resource-driven configuration - using composition, no typing
var player_data: Resource

# Visual components
@onready var next_position_sprite: Sprite2D
@onready var confirmed_sprite: Sprite2D
var shooting_indicator: ShootingIndicator
var mode_icon: Node2D

# Lightweight state tracking (no complex logic)
var preview_visible: bool = false
var preview_confirmed: bool = false
var preview_x: int = 0
var preview_y: int = 0

func _ready() -> void:
	# Add to groups for Manager batch processing
	add_to_group("player")
	add_to_group("damageable")

	# Initialize visual components
	setup_visual_components()

	# Connect to EventBus for relevant events
	EventBus.turn_phase_changed.connect(_on_turn_phase_changed)

	print("Player ", player_id, " initialized as lightweight entity")

# Public API - called by Managers
func setup(x: int, y: int, id: int, data: Resource = null) -> void:
	grid_x = x
	grid_y = y
	player_id = id
	player_data = data

	# Set position based on grid coordinates
	position = Vector2(x * 20 + 10, y * 20 + 10)

	# Apply player data configuration if provided
	if player_data:
		apply_player_data()

func apply_player_data() -> void:
	if not player_data:
		return

	# Apply visual configuration
	if player_data.player_texture:
		# Apply texture to sprite if you have one
		pass

	# Apply color
	modulate = player_data.player_color

func move_to(new_x: int, new_y: int) -> void:
	# Simple state update - no validation (handled by Managers)
	grid_x = new_x
	grid_y = new_y
	position = Vector2(new_x * 20 + 10, new_y * 20 + 10)

	# Update shooting indicator position
	if shooting_indicator:
		shooting_indicator.position = position

	# Hide preview after movement
	hide_preview()

	# Emit movement event through EventBus
	EventBus.player_moved.emit(self, Vector2i(grid_x, grid_y), Vector2i(new_x, new_y))

func take_damage(damage: int) -> void:
	# Simple damage handling - complex logic in CombatManager
	if not player_data:
		return

	player_data.current_health -= damage
	player_data.current_health = max(0, player_data.current_health)

	print("Player ", player_id, " took ", damage, " damage. Health: ", player_data.current_health)

	# Update visual health indicators if you have them
	update_health_display()

func get_health() -> int:
	if player_data:
		return player_data.current_health
	return 100  # Default fallback

func is_alive() -> bool:
	return get_health() > 0

func get_current_mode() -> PlayerMode:
	return current_mode

func set_mode(new_mode: PlayerMode) -> void:
	# Simple mode switching - complex logic handled by Managers
	if current_mode == new_mode:
		return

	current_mode = new_mode
	player_mode_changed.emit(player_id, current_mode)

	# Update visual indicators
	update_mode_visuals()

	print("Player ", player_id, " mode changed to: ", PlayerMode.keys()[current_mode])

# Input response functions - called by InputManager through signals
func on_direction_input(direction: Vector2i) -> void:
	# Lightweight response - complex logic in InputManager
	if preview_confirmed or current_mode == PlayerMode.ATTACK:
		return

	if direction == Vector2i.ZERO:
		hide_preview()
	else:
		var target_x = grid_x + direction.x
		var target_y = grid_y + direction.y

		# Basic bounds checking
		if target_x >= 0 and target_x < 8 and target_y >= 0 and target_y < 8:
			show_preview(target_x, target_y)
		else:
			hide_preview()

func on_stick_input(stick_vector: Vector2) -> void:
	# Handle continuous input for attack mode
	if current_mode == PlayerMode.ATTACK and shooting_indicator:
		shooting_indicator.update_rotation_from_stick(stick_vector)

func on_confirm_input() -> void:
	# Simple confirmation handling
	if current_mode == PlayerMode.ATTACK:
		if shooting_indicator and shooting_indicator.visible and not shooting_indicator.is_indicator_locked():
			shooting_indicator.lock_indicator()
			EventBus.player_confirmed_action.emit(self)
	elif current_mode == PlayerMode.MOVE:
		if preview_visible and not preview_confirmed:
			confirm_preview()
			EventBus.player_confirmed_action.emit(self)

func on_cancel_input() -> void:
	# Simple cancellation handling
	if current_mode == PlayerMode.ATTACK:
		if shooting_indicator and shooting_indicator.is_indicator_locked():
			shooting_indicator.unlock_indicator()
	elif current_mode == PlayerMode.MOVE:
		if preview_confirmed:
			cancel_preview()

func on_mode_switch_input() -> void:
	# Toggle between modes
	if current_mode == PlayerMode.MOVE:
		set_mode(PlayerMode.ATTACK)
		show_shooting_indicator()
	else:
		set_mode(PlayerMode.MOVE)
		hide_shooting_indicator()

# Visual management functions
func setup_visual_components() -> void:
	# Create preview sprites
	next_position_sprite = Sprite2D.new()
	next_position_sprite.texture = load("res://assets/textures/indicators/next_position.png")
	next_position_sprite.visible = false
	get_parent().add_child(next_position_sprite)

	confirmed_sprite = Sprite2D.new()
	confirmed_sprite.texture = load("res://assets/textures/indicators/confirmed.png")
	confirmed_sprite.visible = false
	get_parent().add_child(confirmed_sprite)

	# Create shooting indicator
	shooting_indicator = ShootingIndicator.new()
	shooting_indicator.setup(player_id)
	shooting_indicator.position = position
	get_parent().add_child(shooting_indicator)

	# Create mode icon
	create_mode_icon()

func show_preview(target_x: int, target_y: int) -> void:
	preview_visible = true
	preview_confirmed = false
	preview_x = target_x
	preview_y = target_y

	next_position_sprite.position = Vector2(target_x * 20 + 10, target_y * 20 + 10)
	next_position_sprite.visible = true
	confirmed_sprite.visible = false

func confirm_preview() -> void:
	if not preview_visible:
		return

	preview_confirmed = true
	confirmed_sprite.position = Vector2(preview_x * 20 + 10, preview_y * 20 + 10)
	next_position_sprite.visible = false
	confirmed_sprite.visible = true

func cancel_preview() -> void:
	preview_confirmed = false
	confirmed_sprite.visible = false

	# Show preview again if input is still active
	if InputManager and InputManager.get_player_direction_vector(player_id) != Vector2i.ZERO:
		var direction = InputManager.get_player_direction_vector(player_id)
		on_direction_input(direction)

func hide_preview() -> void:
	preview_visible = false
	preview_confirmed = false
	next_position_sprite.visible = false
	confirmed_sprite.visible = false

func show_shooting_indicator() -> void:
	if shooting_indicator:
		shooting_indicator.show_indicator()
		shooting_indicator.position = position

func hide_shooting_indicator() -> void:
	if shooting_indicator:
		shooting_indicator.hide_indicator()

func reset_confirmation_state() -> void:
	# Reset for new turn
	preview_confirmed = false
	hide_preview()

func update_mode_visuals() -> void:
	if current_mode == PlayerMode.ATTACK:
		hide_preview()
	else:
		hide_shooting_indicator()

	update_mode_icon()

func create_mode_icon() -> void:
	mode_icon = Node2D.new()
	mode_icon.position = Vector2(0, 12)
	add_child(mode_icon)
	update_mode_icon()

func update_mode_icon() -> void:
	if not mode_icon:
		return

	# Clear existing children
	for child in mode_icon.get_children():
		child.queue_free()

	match current_mode:
		PlayerMode.MOVE:
			create_shoe_icon()
		PlayerMode.ATTACK:
			create_gun_icon()

func create_shoe_icon() -> void:
	var shoe_bg = ColorRect.new()
	shoe_bg.size = Vector2(8, 4)
	shoe_bg.position = Vector2(-4, -2)
	shoe_bg.color = Color.GREEN
	mode_icon.add_child(shoe_bg)

	var shoe_sole = ColorRect.new()
	shoe_sole.size = Vector2(10, 2)
	shoe_sole.position = Vector2(-5, 0)
	shoe_sole.color = Color.DARK_GREEN
	mode_icon.add_child(shoe_sole)

func create_gun_icon() -> void:
	var gun_barrel = ColorRect.new()
	gun_barrel.size = Vector2(6, 2)
	gun_barrel.position = Vector2(-3, -1)
	gun_barrel.color = Color.RED
	mode_icon.add_child(gun_barrel)

	var gun_grip = ColorRect.new()
	gun_grip.size = Vector2(3, 4)
	gun_grip.position = Vector2(-5, -1)
	gun_grip.color = Color.DARK_RED
	mode_icon.add_child(gun_grip)

func update_health_display() -> void:
	# Update any health UI elements
	# This could be handled by a UI manager instead
	pass

# Event handlers
func _on_turn_phase_changed(new_phase) -> void:
	# React to phase changes if needed - using int instead of enum to avoid circular dependency
	match new_phase:
		1: # PLAYER_DECISION
			# Enable input response
			pass
		2: # PLAYER_MOVE
			# Prepare for movement
			pass
		_:
			# Other phases - might disable certain inputs
			pass

# Utility functions for Managers
func get_grid_position() -> Vector2i:
	return Vector2i(grid_x, grid_y)

func get_world_position() -> Vector2:
	return position

func get_player_data() -> Resource:
	return player_data

func set_player_data(data: Resource) -> void:
	player_data = data
	apply_player_data()

# Manager API for AI/Combat systems
func can_perform_action(action: String) -> bool:
	if not player_data:
		return true  # Default to allowing actions

	return player_data.can_perform_action(action)

func get_effective_damage() -> int:
	if player_data:
		return player_data.get_effective_damage()
	return 50  # Default

func get_effective_range() -> float:
	if player_data:
		return player_data.get_effective_range()
	return 8.0  # Default