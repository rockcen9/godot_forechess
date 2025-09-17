extends Node

# CombatManager: Centralized combat logic and damage system
# Responsible for: Attack resolution, damage calculation, collision detection, combat effects
# API: update(), perform_attack(), check_collision(), apply_damage()

# Combat configuration
var default_player_damage: int = 50
var damage_falloff_enabled: bool = false
var friendly_fire_enabled: bool = false

# Combat state tracking
var active_attacks: Array[Dictionary] = []
var combat_queue: Array[Dictionary] = []

func _ready() -> void:
	print("CombatManager initialized")
	# Connect to EventBus for combat-related events
	EventBus.player_confirmed_action.connect(_on_player_confirmed_action)

# Manager API - called by GameManager during update loop
func update(delta: float) -> void:
	# Process any ongoing attacks or effects
	process_active_attacks(delta)

# Core combat functions
func perform_player_attacks(players: Array) -> void:
	print("CombatManager: Processing player attacks")

	for player in players:
		if not player or player.get_current_mode() != 1: # ATTACK mode
			continue

		if not player.shooting_indicator or not player.shooting_indicator.is_indicator_locked():
			continue

		execute_player_attack(player)

	# Clear shooting indicators after all attacks
	clear_shooting_indicators(players)

func execute_player_attack(player: Node) -> void:
	print("CombatManager: Player ", player.player_id, " executing attack")

	# Get attack parameters
	var attack_data = get_attack_data(player)
	var targets = find_targets_on_line(attack_data.start_pos, attack_data.direction, attack_data.range)

	# Apply damage to all targets
	for target in targets:
		apply_damage(target, attack_data.damage, player)

	# Create attack effect
	create_attack_effect(attack_data)

	# Emit attack event
	EventBus.attack_performed.emit(player, null, attack_data.damage)

func get_attack_data(player: Node) -> Dictionary:
	var start_pos = Vector2(player.grid_x, player.grid_y)
	var direction = Vector2.from_angle(player.shooting_indicator.rotation)
	var damage = default_player_damage
	var range = 8.0  # Maximum shooting range

	return {
		"start_pos": start_pos,
		"direction": direction,
		"damage": damage,
		"range": range,
		"attacker": player
	}

func find_targets_on_line(start_pos: Vector2, direction: Vector2, max_range: float) -> Array:
	var targets = []

	# Get all possible targets (enemies and players if friendly fire enabled)
	var potential_targets = get_all_damageable_entities()

	for target in potential_targets:
		if not is_valid_target(target):
			continue

		var target_pos = Vector2(target.grid_x, target.grid_y)

		# Check if target is on the shooting line
		if is_point_on_line(start_pos, direction, target_pos, max_range):
			targets.append(target)

	return targets

func get_all_damageable_entities() -> Array:
	var entities = []

	# Get all enemies from the "enemy" group
	var enemies = get_tree().get_nodes_in_group("enemy")
	entities.append_array(enemies)

	# Get players if friendly fire is enabled
	if friendly_fire_enabled:
		var players = get_tree().get_nodes_in_group("player")
		entities.append_array(players)

	return entities

func is_valid_target(target: Node) -> bool:
	if not target or not is_instance_valid(target):
		return false

	# Check if target has required methods for damage
	if target.has_method("take_damage") and target.has_method("is_alive"):
		return target.is_alive()

	return false

func is_point_on_line(line_start: Vector2, line_direction: Vector2, point: Vector2, max_range: float) -> bool:
	# Calculate vector from line start to point
	var to_point = point - line_start

	# Check if point is in front of the line (positive projection)
	var projection = to_point.dot(line_direction.normalized())
	if projection <= 0 or projection > max_range:
		return false

	# Calculate perpendicular distance from point to line
	var perpendicular_distance = abs(to_point.cross(line_direction.normalized()))

	# Consider hit if within tolerance (0.5 units for grid-based game)
	return perpendicular_distance < 0.5

func apply_damage(target: Node, damage: int, source: Node = null) -> void:
	if not is_valid_target(target):
		return

	var old_health = target.get_health() if target.has_method("get_health") else 0

	# Apply damage
	target.take_damage(damage)

	var new_health = target.get_health() if target.has_method("get_health") else 0

	print("CombatManager: Applied ", damage, " damage to ", target.name, " (", old_health, " -> ", new_health, ")")

	# Emit damage event
	EventBus.damage_applied.emit(target, damage, source)
	EventBus.entity_health_changed.emit(target, old_health, new_health)

	# Check if target died
	if new_health <= 0:
		handle_entity_death(target, source)

func handle_entity_death(target: Node, source: Node = null) -> void:
	print("CombatManager: Entity died - ", target.name)

	# Emit death event based on entity type
	if target.has_method("get_enemy_id"):  # It's an enemy
		EventBus.enemy_died.emit(target)
	elif target.has_method("get_player_id"):  # It's a player
		EventBus.player_died.emit(target, "combat")

# Collision and movement validation
func check_movement_collision(entity: Node, target_pos: Vector2i) -> bool:
	# Check if the target position is occupied
	var occupants = get_entities_at_position(target_pos)

	# Remove the moving entity from consideration
	occupants = occupants.filter(func(e): return e != entity)

	return not occupants.is_empty()

func get_entities_at_position(pos: Vector2i) -> Array:
	var entities = []

	# Check all players
	var players = get_tree().get_nodes_in_group("player")
	for player in players:
		if Vector2i(player.grid_x, player.grid_y) == pos:
			entities.append(player)

	# Check all enemies
	var enemies = get_tree().get_nodes_in_group("enemy")
	for enemy in enemies:
		if Vector2i(enemy.grid_x, enemy.grid_y) == pos:
			entities.append(enemy)

	return entities

func check_player_enemy_collision(player_positions: Array[Vector2i], enemy_positions: Array[Vector2i]) -> Array[Vector2i]:
	var collision_positions = []

	for player_pos in player_positions:
		if player_pos in enemy_positions:
			collision_positions.append(player_pos)

	return collision_positions

# Combat effects and feedback
func create_attack_effect(attack_data: Dictionary) -> void:
	# Placeholder for visual/audio attack effects
	print("CombatManager: Creating attack effect from ", attack_data.start_pos, " in direction ", attack_data.direction)

	# Request sound effect through EventBus
	EventBus.request_audio("effect", "player_attack", attack_data.start_pos)

func clear_shooting_indicators(players: Array) -> void:
	print("CombatManager: Clearing shooting indicators")
	for player in players:
		if player and player.shooting_indicator:
			player.shooting_indicator.hide_indicator()

# Active attack processing (for future animated attacks)
func process_active_attacks(delta: float) -> void:
	# Process any ongoing attack animations or effects
	for i in range(active_attacks.size() - 1, -1, -1):
		var attack = active_attacks[i]
		attack.time_remaining -= delta

		if attack.time_remaining <= 0:
			finalize_attack(attack)
			active_attacks.remove_at(i)

func finalize_attack(attack_data: Dictionary) -> void:
	# Cleanup after attack animation/effect completes
	pass

# Configuration and utility
func set_player_damage(damage: int) -> void:
	default_player_damage = damage
	print("CombatManager: Player damage set to ", damage)

func set_friendly_fire(enabled: bool) -> void:
	friendly_fire_enabled = enabled
	print("CombatManager: Friendly fire ", "enabled" if enabled else "disabled")

func get_combat_statistics() -> Dictionary:
	return {
		"active_attacks": active_attacks.size(),
		"default_damage": default_player_damage,
		"friendly_fire": friendly_fire_enabled
	}

# Event handlers
func _on_player_confirmed_action(player: Node) -> void:
	# Handle combat-related confirmations if needed
	pass