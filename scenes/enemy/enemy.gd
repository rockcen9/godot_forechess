extends Node2D
class_name Enemy

var grid_x: int
var grid_y: int
var enemy_id: int
var health: int = 100
var max_health: int = 100

# AI target selection
var target_player_id: int = 0  # 0 means no target selected yet
var planned_move_direction: Vector2i = Vector2i.ZERO

# Health bar display
var health_bar_bg: ColorRect
var health_bar_fg: ColorRect

func setup(x: int, y: int, id: int) -> void:
	grid_x = x
	grid_y = y
	enemy_id = id

	# Set position based on grid coordinates, centered within the tile
	position = Vector2(x * 20 + 10, y * 20 + 10)  # +10 to center in 20px tile

func _ready() -> void:
	create_health_bar()

func create_health_bar() -> void:
	# Create health bar background
	health_bar_bg = ColorRect.new()
	health_bar_bg.size = Vector2(16, 3)
	health_bar_bg.position = Vector2(-8, -12)  # Above the enemy
	health_bar_bg.color = Color.BLACK
	add_child(health_bar_bg)

	# Create health bar foreground
	health_bar_fg = ColorRect.new()
	health_bar_fg.size = Vector2(16, 3)
	health_bar_fg.position = Vector2(-8, -12)
	health_bar_fg.color = Color.GREEN
	add_child(health_bar_fg)

func move_to(new_x: int, new_y: int) -> void:
	grid_x = new_x
	grid_y = new_y
	position = Vector2(new_x * 20 + 10, new_y * 20 + 10)

func take_damage(damage: int) -> void:
	health -= damage
	health = max(0, health)  # Ensure health doesn't go below 0
	print("Enemy ", enemy_id, " took ", damage, " damage. Health: ", health, "/", max_health)
	update_health_bar()

func get_health() -> int:
	return health

func is_alive() -> bool:
	return health > 0

func get_health_percentage() -> float:
	return float(health) / float(max_health)

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

# AI Methods
func select_target_player(available_players: Array) -> void:
	# Only select target if we don't have one yet
	if target_player_id != 0:
		return

	if available_players.is_empty():
		print("Enemy ", enemy_id, " has no players to target")
		return

	# Randomly select a target player (Option A from requirements)
	var random_index = randi() % available_players.size()
	var target_player = available_players[random_index]
	target_player_id = target_player.player_id
	print("Enemy ", enemy_id, " selected target player ", target_player_id)

func make_decision(board_manager: Node2D) -> void:
	# Get the target player
	var target_player = board_manager.get_player(target_player_id)
	if not target_player:
		print("Enemy ", enemy_id, " target player ", target_player_id, " not found")
		planned_move_direction = Vector2i.ZERO
		return

	# Calculate direction to move toward target player
	var target_pos = Vector2i(target_player.grid_x, target_player.grid_y)
	var current_pos = Vector2i(grid_x, grid_y)

	planned_move_direction = calculate_move_direction(current_pos, target_pos)
	print("Enemy ", enemy_id, " planned move direction: ", planned_move_direction)

func calculate_move_direction(from: Vector2i, to: Vector2i) -> Vector2i:
	# Calculate the difference
	var diff = to - from

	# If already at target position, don't move
	if diff == Vector2i.ZERO:
		return Vector2i.ZERO

	# Move one step in the direction with the largest distance (shortest path)
	# Prioritize cardinal directions only (no diagonals)
	if abs(diff.x) > abs(diff.y):
		# Move horizontally
		return Vector2i(sign(diff.x), 0)
	else:
		# Move vertically
		return Vector2i(0, sign(diff.y))

func get_planned_move() -> Vector2i:
	return planned_move_direction

func execute_planned_move(board_manager: Node2D) -> bool:
	# Execute the planned move if valid
	if planned_move_direction == Vector2i.ZERO:
		print("Enemy ", enemy_id, " has no planned move")
		return false

	var new_x = grid_x + planned_move_direction.x
	var new_y = grid_y + planned_move_direction.y

	# Check bounds
	if new_x < 0 or new_x >= 8 or new_y < 0 or new_y >= 8:
		print("Enemy ", enemy_id, " cannot move outside board bounds")
		return false

	# TODO: Add collision detection with other enemies

	# Execute the move
	move_to(new_x, new_y)
	print("Enemy ", enemy_id, " moved to (", new_x, ", ", new_y, ")")

	# Clear planned move
	planned_move_direction = Vector2i.ZERO
	return true

func get_target_player_id() -> int:
	return target_player_id