extends Node2D

# Lightweight Enemy Entity - delegates AI logic to AIManager
# Responsibilities: State storage, response to Manager calls, basic rendering

var grid_x: int
var grid_y: int
var enemy_id: int
var health: int = 100
var max_health: int = 100

# Resource-driven configuration - using composition, no typing
var enemy_data: Resource

# AI state managed by AIManager
var target_player_id: int = 0
var planned_move_direction: Vector2i = Vector2i.ZERO
var target_location: Vector2i = Vector2i.ZERO

# Visual components
var health_bar_bg: ColorRect
var health_bar_fg: ColorRect
var target_gizmo: Node2D
var gizmo_visible: bool = false

func _ready() -> void:
	# Add to groups for Manager batch processing
	add_to_group("enemy")
	add_to_group("damageable")

	# Initialize visual components
	create_health_bar()
	create_target_gizmo()

	# Connect to EventBus for relevant events
	EventBus.turn_phase_changed.connect(_on_turn_phase_changed)
	EventBus.enemy_spawned.emit(self)

	print("Enemy ", enemy_id, " initialized as lightweight entity")

# Public API - called by Managers
func setup(x: int, y: int, id: int, data: Resource = null) -> void:
	grid_x = x
	grid_y = y
	enemy_id = id
	enemy_data = data

	# Set position based on grid coordinates
	position = Vector2(x * 20 + 10, y * 20 + 10)

	# Apply enemy data configuration if provided
	if enemy_data:
		apply_enemy_data()

func apply_enemy_data() -> void:
	if not enemy_data:
		return

	# Apply stats from resource
	max_health = enemy_data.max_health
	health = max_health

	# Apply visual configuration
	if enemy_data.enemy_texture:
		# Apply texture to sprite if you have one
		pass

	# Apply color and scale
	modulate = enemy_data.enemy_color
	scale = enemy_data.enemy_scale

	update_health_bar()

func move_to(new_x: int, new_y: int) -> void:
	# Simple state update - no validation (handled by Managers)
	var old_pos = Vector2i(grid_x, grid_y)
	grid_x = new_x
	grid_y = new_y
	position = Vector2(new_x * 20 + 10, new_y * 20 + 10)

	# Emit movement event through EventBus
	EventBus.enemy_moved.emit(self, old_pos, Vector2i(new_x, new_y))

func take_damage(damage: int) -> void:
	# Simple damage handling - complex logic in CombatManager
	var old_health = health
	health -= damage
	health = max(0, health)

	print("Enemy ", enemy_id, " took ", damage, " damage. Health: ", health, "/", max_health)

	# Update visual health bar
	update_health_bar()

	# Emit health change event
	EventBus.entity_health_changed.emit(self, old_health, health)

	# Check for death
	if health <= 0:
		EventBus.enemy_died.emit(self)

func get_health() -> int:
	return health

func is_alive() -> bool:
	return health > 0

func get_health_percentage() -> float:
	return float(health) / float(max_health)

# AI interface functions - called by AIManager
func set_ai_decision(target_id: int, move_dir: Vector2i, target_loc: Vector2i) -> void:
	# Store AI decision from AIManager
	target_player_id = target_id
	planned_move_direction = move_dir
	target_location = target_loc

	# Show visual gizmo
	show_target_gizmo()

func get_target_player_id() -> int:
	return target_player_id

func get_planned_move() -> Vector2i:
	return planned_move_direction

func get_target_location() -> Vector2i:
	return target_location

func execute_planned_move(board_manager: Node2D = null) -> bool:
	# Execute the planned move (validation handled by AIManager)
	if planned_move_direction == Vector2i.ZERO:
		return false

	var new_x = grid_x + planned_move_direction.x
	var new_y = grid_y + planned_move_direction.y

	# Basic bounds checking
	if new_x < 0 or new_x >= 8 or new_y < 0 or new_y >= 8:
		return false

	# Execute the move
	move_to(new_x, new_y)

	# Clear planned move and hide gizmo
	planned_move_direction = Vector2i.ZERO
	hide_target_gizmo()
	return true

func clear_ai_state() -> void:
	# Clear AI-related state
	target_player_id = 0
	planned_move_direction = Vector2i.ZERO
	target_location = Vector2i.ZERO
	hide_target_gizmo()

# Visual management functions
func create_health_bar() -> void:
	# Create health bar background
	health_bar_bg = ColorRect.new()
	health_bar_bg.size = Vector2(16, 3)
	health_bar_bg.position = Vector2(-8, -12)
	health_bar_bg.color = Color.BLACK
	add_child(health_bar_bg)

	# Create health bar foreground
	health_bar_fg = ColorRect.new()
	health_bar_fg.size = Vector2(16, 3)
	health_bar_fg.position = Vector2(-8, -12)
	health_bar_fg.color = Color.GREEN
	add_child(health_bar_fg)

func update_health_bar() -> void:
	if not health_bar_fg:
		return

	var health_percentage = get_health_percentage()
	health_bar_fg.size.x = 16 * health_percentage

	# Change color based on health percentage
	if health_percentage > 0.6:
		health_bar_fg.color = Color.GREEN
	elif health_percentage > 0.3:
		health_bar_fg.color = Color.YELLOW
	else:
		health_bar_fg.color = Color.RED

func create_target_gizmo() -> void:
	target_gizmo = Node2D.new()
	target_gizmo.name = "TargetGizmo"
	add_child(target_gizmo)
	target_gizmo.visible = false

func show_target_gizmo() -> void:
	gizmo_visible = true
	queue_redraw()

func hide_target_gizmo() -> void:
	gizmo_visible = false
	queue_redraw()

func _draw() -> void:
	if not gizmo_visible:
		return

	# Calculate the world position of the target location
	var target_world_pos = Vector2(target_location.x * 20 + 10, target_location.y * 20 + 10)
	var current_world_pos = Vector2(grid_x * 20 + 10, grid_y * 20 + 10)

	# Convert to local coordinates relative to enemy position
	var target_local_pos = target_world_pos - current_world_pos

	# Draw a circle at the target location
	draw_circle(target_local_pos, 8, Color.RED, false, 2.0)

	# Draw an arrow pointing to the target
	if target_local_pos.length() > 0:
		var direction = target_local_pos.normalized()
		var arrow_start = direction * 12
		var arrow_end = target_local_pos - direction * 8

		# Draw the arrow line
		draw_line(arrow_start, arrow_end, Color.RED, 2.0)

		# Draw arrowhead
		var arrowhead_size = 4
		var arrowhead_angle = PI / 6
		var arrowhead1 = arrow_end - direction.rotated(arrowhead_angle) * arrowhead_size
		var arrowhead2 = arrow_end - direction.rotated(-arrowhead_angle) * arrowhead_size

		draw_line(arrow_end, arrowhead1, Color.RED, 2.0)
		draw_line(arrow_end, arrowhead2, Color.RED, 2.0)

	# Draw a simple circle at current position for debugging
	draw_circle(Vector2.ZERO, 3, Color.BLUE, true)

func _process(delta) -> void:
	if gizmo_visible:
		queue_redraw()

# Event handlers
func _on_turn_phase_changed(new_phase) -> void:
	# React to phase changes if needed - using int instead of enum to avoid circular dependency
	match new_phase:
		0: # ENEMY_DECISION
			# Prepare for AI decision making
			pass
		3: # ENEMY_MOVE
			# Prepare for movement execution
			pass
		_:
			pass

# Manager API functions
func get_grid_position() -> Vector2i:
	return Vector2i(grid_x, grid_y)

func get_world_position() -> Vector2:
	return position

func get_enemy_data() -> Resource:
	return enemy_data

func set_enemy_data(data: Resource) -> void:
	enemy_data = data
	apply_enemy_data()

func get_ai_threat_level() -> float:
	if enemy_data:
		return enemy_data.calculate_threat_level()
	return 50.0  # Default threat level

func can_perform_action(action: String) -> bool:
	if not enemy_data:
		return true  # Default to allowing actions

	return enemy_data.can_perform_action(action)

func get_ai_behavior_weight(behavior: String) -> float:
	if enemy_data:
		return enemy_data.get_ai_decision_weight(behavior)
	return 0.5  # Default neutral weight

# Resource management for advanced features
func get_status_resistance(status: String) -> float:
	if enemy_data and status in enemy_data.status_resistances:
		return enemy_data.status_resistances[status]
	return 0.0

func apply_status_effect(effect_name: String, duration: int) -> void:
	# Simple status effect application
	# Complex logic would be handled by a StatusEffectManager
	print("Enemy ", enemy_id, " received status effect: ", effect_name, " for ", duration, " turns")

# Cleanup function
func destroy() -> void:
	# Clean up when enemy is destroyed
	hide_target_gizmo()
	queue_free()

# Debug functions
func debug_show_gizmo() -> void:
	target_location = Vector2i(grid_x + 1, grid_y + 1)
	gizmo_visible = true
	print("Debug: Forcing gizmo visibility for enemy ", enemy_id)

func get_debug_info() -> Dictionary:
	return {
		"enemy_id": enemy_id,
		"position": Vector2i(grid_x, grid_y),
		"health": str(health) + "/" + str(max_health),
		"target_player": target_player_id,
		"planned_move": planned_move_direction,
		"target_location": target_location,
		"ai_threat": get_ai_threat_level()
	}

# Target selection method needed by board manager
func select_target_player(available_players: Array) -> void:
	# Simple target selection - closest player
	if available_players.is_empty():
		target_player_id = -1
		return

	var closest_player = null
	var closest_distance = INF

	for player in available_players:
		if not player:
			continue

		var distance = Vector2i(grid_x, grid_y).distance_to(Vector2i(player.grid_x, player.grid_y))
		if distance < closest_distance:
			closest_distance = distance
			closest_player = player

	if closest_player:
		target_player_id = closest_player.player_id
		print("Enemy ", enemy_id, " selected target: Player ", target_player_id)
	else:
		target_player_id = -1