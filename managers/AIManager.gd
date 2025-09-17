extends Node

# AIManager: Centralized AI logic for enemy decision-making
# Responsible for: Enemy targeting, movement decisions, AI state management
# API: update(), make_enemy_decisions(), execute_enemy_actions()

# AI decision cache to avoid recalculation
var enemy_decisions: Dictionary = {}
var targeting_cache: Dictionary = {}

func _ready() -> void:
	print("AIManager initialized")
	# Connect to EventBus for enemy-related events
	EventBus.enemy_spawned.connect(_on_enemy_spawned)
	EventBus.enemy_died.connect(_on_enemy_died)

# Manager API - called by GameManager during update loop
func update(delta: float) -> void:
	# AI can run continuous logic here if needed
	# Currently AI is turn-based, so most logic happens in decision phase
	pass

# Core AI decision making
func make_enemy_decisions(enemies: Array, players: Array) -> void:
	print("AIManager: Making enemy decisions")
	enemy_decisions.clear()

	for enemy in enemies:
		if not enemy or not enemy.is_alive():
			continue

		var decision = make_individual_decision(enemy, players)
		enemy_decisions[enemy.enemy_id] = decision

		# Apply the decision to the enemy
		apply_decision_to_enemy(enemy, decision)

	print("AIManager: Decisions made for ", enemy_decisions.size(), " enemies")

func make_individual_decision(enemy: Node, players: Array) -> Dictionary:
	var decision = {
		"target_player_id": 0,
		"move_direction": Vector2i.ZERO,
		"target_location": Vector2i(enemy.grid_x, enemy.grid_y),
		"action_type": "move" # "move", "attack", "wait"
	}

	# Step 1: Target selection
	var target_player = select_target_for_enemy(enemy, players)
	if target_player:
		decision.target_player_id = target_player.player_id

		# Step 2: Movement decision
		var move_info = calculate_movement(enemy, target_player)
		decision.move_direction = move_info.direction
		decision.target_location = move_info.target_location
		decision.action_type = move_info.action_type

	return decision

func select_target_for_enemy(enemy: Node, players: Array) -> Node:
	# Check if enemy already has a valid target
	var current_target = get_enemy_current_target(enemy, players)
	if current_target:
		return current_target

	# Select new target using different strategies
	return select_target_by_strategy(enemy, players, "closest")

func get_enemy_current_target(enemy: Node, players: Array) -> Node:
	var current_target_id = enemy.get_target_player_id()
	if current_target_id == 0:
		return null

	# Find the target player
	for player in players:
		if player.player_id == current_target_id and is_valid_target(player):
			return player

	return null

func select_target_by_strategy(enemy: Node, players: Array, strategy: String) -> Node:
	var valid_players = players.filter(is_valid_target)
	if valid_players.is_empty():
		return null

	match strategy:
		"closest":
			return find_closest_player(enemy, valid_players)
		"random":
			return valid_players[randi() % valid_players.size()]
		"weakest":
			return find_weakest_player(valid_players)
		_:
			return valid_players[0]

func is_valid_target(player: Node) -> bool:
	return player != null and is_instance_valid(player)

func find_closest_player(enemy: Node, players: Array) -> Node:
	var closest_player = null
	var closest_distance = INF
	var enemy_pos = Vector2i(enemy.grid_x, enemy.grid_y)

	for player in players:
		var player_pos = Vector2i(player.grid_x, player.grid_y)
		var distance = enemy_pos.distance_to(player_pos)

		if distance < closest_distance:
			closest_distance = distance
			closest_player = player

	return closest_player

func find_weakest_player(players: Array) -> Node:
	# Since players don't have health in this game, use random selection
	# This can be extended if players get health/weakness attributes
	return players[randi() % players.size()]

func calculate_movement(enemy: Node, target_player: Node) -> Dictionary:
	var current_pos = Vector2i(enemy.grid_x, enemy.grid_y)
	var target_pos = Vector2i(target_player.grid_x, target_player.grid_y)

	var move_direction = calculate_move_direction(current_pos, target_pos)
	var target_location = current_pos + move_direction

	# Ensure target location is within bounds
	target_location.x = clamp(target_location.x, 0, 7)
	target_location.y = clamp(target_location.y, 0, 7)

	var action_type = "move"

	# Check if enemy would reach player position (attack scenario)
	if target_location == target_pos:
		action_type = "attack"

	return {
		"direction": move_direction,
		"target_location": target_location,
		"action_type": action_type
	}

func calculate_move_direction(from: Vector2i, to: Vector2i) -> Vector2i:
	var diff = to - from

	# If already at target position, don't move
	if diff == Vector2i.ZERO:
		return Vector2i.ZERO

	# Move one step in the direction with the largest distance (shortest path)
	# Prioritize cardinal directions only (no diagonals)
	if abs(diff.x) > abs(diff.y):
		return Vector2i(sign(diff.x), 0)
	else:
		return Vector2i(0, sign(diff.y))

func apply_decision_to_enemy(enemy: Node, decision: Dictionary) -> void:
	# Apply the AI decision to the enemy entity
	if enemy.has_method("set_ai_decision"):
		enemy.set_ai_decision(
			decision.target_player_id,
			decision.move_direction,
			decision.target_location
		)
	else:
		# Fallback for existing enemy scripts
		enemy.target_player_id = decision.target_player_id
		enemy.planned_move_direction = decision.move_direction
		enemy.target_location = decision.target_location

# Execute enemy movements based on decisions
func execute_enemy_movements(enemies: Array) -> Array[Vector2i]:
	print("AIManager: Executing enemy movements")
	var enemy_positions = []

	for enemy in enemies:
		if not enemy or not enemy.is_alive():
			continue

		var moved = execute_individual_movement(enemy)
		if moved:
			enemy_positions.append(Vector2i(enemy.grid_x, enemy.grid_y))

			# Emit movement event
			EventBus.enemy_moved.emit(enemy,
				Vector2i(enemy.grid_x - enemy.planned_move_direction.x, enemy.grid_y - enemy.planned_move_direction.y),
				Vector2i(enemy.grid_x, enemy.grid_y))

	print("AIManager: Moved ", enemy_positions.size(), " enemies")
	return enemy_positions

func execute_individual_movement(enemy: Node) -> bool:
	# Delegate to enemy's execution method but add validation
	var planned_direction = enemy.get_planned_move()
	if planned_direction == Vector2i.ZERO:
		return false

	# Add collision detection with other enemies here if needed
	# For now, use the enemy's built-in execution
	return enemy.execute_planned_move(null) # BoardManager reference not needed for basic movement

# Event handlers
func _on_enemy_spawned(enemy: Node) -> void:
	print("AIManager: Registered new enemy ", enemy.enemy_id)
	# Initialize AI state for new enemy
	targeting_cache[enemy.enemy_id] = {}

func _on_enemy_died(enemy: Node) -> void:
	print("AIManager: Unregistered enemy ", enemy.enemy_id)
	# Clean up AI state
	enemy_decisions.erase(enemy.enemy_id)
	targeting_cache.erase(enemy.enemy_id)

# Utility functions
func get_enemy_decision(enemy_id: int) -> Dictionary:
	return enemy_decisions.get(enemy_id, {})

func has_enemy_decision(enemy_id: int) -> bool:
	return enemy_id in enemy_decisions

func clear_all_decisions() -> void:
	enemy_decisions.clear()
	targeting_cache.clear()
	print("AIManager: Cleared all enemy decisions")

# Advanced AI functions for future extension
func set_ai_difficulty(difficulty: String) -> void:
	match difficulty:
		"easy":
			# Random targeting, slower decisions
			pass
		"medium":
			# Closest player targeting
			pass
		"hard":
			# Strategic targeting, optimal pathfinding
			pass

func get_ai_statistics() -> Dictionary:
	return {
		"active_enemies": enemy_decisions.size(),
		"targeting_cache_size": targeting_cache.size(),
		"last_decision_count": enemy_decisions.size()
	}
