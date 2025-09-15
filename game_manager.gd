extends Node

enum TurnPhase {
	PLAYER_DECISION,
	PLAYER_MOVE,
	PLAYER_ATTACK
}

signal turn_phase_changed(new_phase: TurnPhase)

var current_phase: TurnPhase = TurnPhase.PLAYER_DECISION
var player_confirmations: Dictionary = {
	1: false,
	2: false
}

var player_confirmed_directions: Dictionary = {
	1: Vector2i.ZERO,
	2: Vector2i.ZERO
}

@onready var input_manager: Node = get_node("../InputManager")
@onready var board_manager: Node2D = get_node("../BoardManager")
@onready var phase_label: Label = get_node("../UI/PhaseLabel")
@onready var status_label: Label = get_node("../UI/StatusLabel")
@onready var player_modes_label: Label = get_node("../UI/PlayerModesLabel")

var player_modes: Dictionary = {
	1: "Move",
	2: "Move"
}

func _ready() -> void:
	# Connect to input manager signals
	input_manager.player_confirmed.connect(_on_player_confirmed)
	input_manager.player_cancelled.connect(_on_player_cancelled)

	# Connect to player mode changes through board manager
	board_manager.connect_player_mode_signals(_on_player_mode_changed)

	# Initialize phase display
	update_phase_display()
	update_modes_display()

func _on_player_confirmed(player_id: int) -> void:
	if current_phase == TurnPhase.PLAYER_DECISION:
		player_confirmations[player_id] = true
		# Capture the direction at confirmation time
		player_confirmed_directions[player_id] = input_manager.get_player_direction_vector(player_id)
		print("GameManager: Player ", player_id, " confirmed their move with direction: ", player_confirmed_directions[player_id])
		print("Current confirmations: ", player_confirmations)
		update_status_display()

		check_all_players_ready()

func check_all_players_ready() -> void:
	# Check if all players have confirmed their actions (move or attack)
	var all_confirmed = true
	for pid in [1, 2]:
		var player = board_manager.get_player(pid)
		if player:
			if player.get_current_mode() == 1: # PlayerMode.ATTACK
				# For attack mode, check if shooting indicator is locked
				if not (player.shooting_indicator and player.shooting_indicator.is_indicator_locked()):
					all_confirmed = false
					break
			else: # PlayerMode.MOVE
				# For move mode, check if move is confirmed
				if not player_confirmations[pid]:
					all_confirmed = false
					break

	print("All players ready: ", all_confirmed)
	if all_confirmed:
		start_player_move_phase()

func start_player_move_phase() -> void:
	current_phase = TurnPhase.PLAYER_MOVE
	turn_phase_changed.emit(current_phase)
	update_phase_display()
	print("Entering PlayerMove phase")

	# Execute all player movements
	execute_player_movements()

	# Check if any players are in attack mode to proceed to attack phase
	await get_tree().create_timer(1.0).timeout # Brief pause to see movement

	if has_players_in_attack_mode():
		start_player_attack_phase()
	else:
		start_player_decision_phase()

func start_player_decision_phase() -> void:
	current_phase = TurnPhase.PLAYER_DECISION
	turn_phase_changed.emit(current_phase)
	update_phase_display()
	print("Entering PlayerDecision phase")

	# Reset confirmations for next turn
	player_confirmations[1] = false
	player_confirmations[2] = false

	# Reset confirmed directions
	player_confirmed_directions[1] = Vector2i.ZERO
	player_confirmed_directions[2] = Vector2i.ZERO

	# Reset player confirmation states
	reset_player_confirmations()

func update_phase_display() -> void:
	if phase_label:
		match current_phase:
			TurnPhase.PLAYER_DECISION:
				phase_label.text = "Phase: PlayerDecision"
			TurnPhase.PLAYER_MOVE:
				phase_label.text = "Phase: PlayerMove"
			TurnPhase.PLAYER_ATTACK:
				phase_label.text = "Phase: PlayerAttack"
	update_status_display()

func update_status_display() -> void:
	if status_label:
		var p1_status = "⏳"  # Waiting
		var p2_status = "⏳"  # Waiting

		if player_confirmations[1]:
			p1_status = "✅"  # Confirmed
		if player_confirmations[2]:
			p2_status = "✅"  # Confirmed

		status_label.text = "Player 1: " + p1_status + " | Player 2: " + p2_status

func reset_player_confirmations() -> void:
	# Reset confirmation state for all players
	for player_id in [1, 2]:
		var player = board_manager.get_player(player_id)
		if player:
			player.reset_confirmation_state()

func execute_player_movements() -> void:
	# Get player movement directions and execute them
	print("=== EXECUTING PLAYER MOVEMENTS ===")
	for player_id in [1, 2]:
		print("Player ", player_id, " confirmed: ", player_confirmations[player_id])
		if player_confirmations[player_id]:
			var player = board_manager.get_player(player_id)
			if player and player.get_current_mode() == 1: # PlayerMode.ATTACK
				print("Player ", player_id, " is in attack mode - skipping movement")
				continue

			var direction = player_confirmed_directions[player_id]
			print("Player ", player_id, " using confirmed direction: ", direction)
			board_manager.move_player(player_id, direction)
		else:
			print("Player ", player_id, " not confirmed, skipping movement")
	print("=== MOVEMENT EXECUTION COMPLETE ===")

func _on_player_cancelled(player_id: int) -> void:
	if current_phase == TurnPhase.PLAYER_DECISION:
		player_confirmations[player_id] = false
		print("GameManager: Player ", player_id, " cancelled confirmation")
		update_status_display()

func is_decision_phase() -> bool:
	return current_phase == TurnPhase.PLAYER_DECISION

func _on_player_mode_changed(player_id: int, new_mode) -> void:
	# Update player mode display
	match new_mode:
		0: # PlayerMode.MOVE
			player_modes[player_id] = "Move"
		1: # PlayerMode.ATTACK
			player_modes[player_id] = "Attack"
		_:
			player_modes[player_id] = "Unknown"

	update_modes_display()

func update_modes_display() -> void:
	if player_modes_label:
		player_modes_label.text = "P1 Mode: " + player_modes[1] + " | P2 Mode: " + player_modes[2]

func start_player_attack_phase() -> void:
	current_phase = TurnPhase.PLAYER_ATTACK
	turn_phase_changed.emit(current_phase)
	update_phase_display()
	print("Entering PlayerAttack phase")

	# Execute all player attacks
	execute_player_attacks()

	# Return to decision phase after attacks
	await get_tree().create_timer(1.0).timeout # Brief pause to see attack effects
	start_player_decision_phase()

func has_players_in_attack_mode() -> bool:
	# Check if any players are in attack mode and have locked shooting indicators
	for player_id in [1, 2]:
		var player = board_manager.get_player(player_id)
		if player and player.get_current_mode() == 1: # PlayerMode.ATTACK
			if player.shooting_indicator and player.shooting_indicator.is_indicator_locked():
				return true
	return false

func execute_player_attacks() -> void:
	# Execute attacks for all players in attack mode with locked indicators
	for player_id in [1, 2]:
		var player = board_manager.get_player(player_id)
		if player and player.get_current_mode() == 1: # PlayerMode.ATTACK
			if player.shooting_indicator and player.shooting_indicator.is_indicator_locked():
				perform_player_attack(player)

func perform_player_attack(player: Player) -> void:
	print("Player ", player.player_id, " performing attack")

	# Get shooting line from player position and rotation
	var start_pos = Vector2(player.grid_x, player.grid_y)
	var shooting_direction = Vector2.from_angle(player.shooting_indicator.rotation)

	# Find enemies hit by the shooting line
	var enemies_hit = find_enemies_on_line(start_pos, shooting_direction)

	# Deal damage to hit enemies
	for enemy in enemies_hit:
		damage_enemy(enemy, 50)

func find_enemies_on_line(start_pos: Vector2, direction: Vector2) -> Array:
	var hit_enemies = []
	var enemies = board_manager.get_all_enemies()

	for enemy in enemies:
		var enemy_pos = Vector2(enemy.grid_x, enemy.grid_y)

		# Check if enemy is on the shooting line
		if is_point_on_line(start_pos, direction, enemy_pos):
			hit_enemies.append(enemy)

	return hit_enemies

func is_point_on_line(line_start: Vector2, line_direction: Vector2, point: Vector2) -> bool:
	# Calculate vector from line start to point
	var to_point = point - line_start

	# Check if point is in front of the line (positive projection)
	var projection = to_point.dot(line_direction.normalized())
	if projection <= 0:
		return false

	# Calculate perpendicular distance from point to line
	var perpendicular_distance = abs(to_point.cross(line_direction.normalized()))

	# Consider hit if within 0.5 units of the line (tolerance for grid-based game)
	return perpendicular_distance < 0.5

func damage_enemy(enemy: Enemy, damage: int) -> void:
	print("Damaging enemy at (", enemy.grid_x, ", ", enemy.grid_y, ") for ", damage, " damage")
	enemy.take_damage(damage)

	# Check if enemy should be destroyed
	if enemy.get_health() <= 0:
		destroy_enemy(enemy)

func destroy_enemy(enemy: Enemy) -> void:
	print("Destroying enemy at (", enemy.grid_x, ", ", enemy.grid_y, ")")
	board_manager.remove_enemy(enemy)