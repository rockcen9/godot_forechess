extends Node

# GameManager: Orchestrates game execution order and coordinates managers
# Responsible for: Turn management, execution order, manager coordination, game state
# API: update(), start_game(), end_game(), change_phase()

enum TurnPhase {
	ENEMY_DECISION,
	PLAYER_DECISION,
	PLAYER_MOVE,
	ENEMY_MOVE,
	PLAYER_ATTACK
}

signal turn_phase_changed(new_phase: TurnPhase)

var current_phase: TurnPhase = TurnPhase.ENEMY_DECISION
var player_confirmations: Dictionary = {
	1: false,
	2: false
}

var player_confirmed_directions: Dictionary = {
	1: Vector2i.ZERO,
	2: Vector2i.ZERO
}

# Manager references (injected by main scene)
var input_manager: InputManager
var ai_manager: AIManager
var combat_manager: CombatManager
var board_manager: Node2D  # Reference to BoardManager in scene

# UI references
var phase_label: Label
var status_label: Label
var player_modes_label: Label

var player_modes: Dictionary = {
	1: "Move",
	2: "Move"
}

# Scene preloads
# var restart_dialog_scene: PackedScene = preload("res://ui/RestartDialog.tscn")
var pause_menu_scene: PackedScene = preload("res://ui/ui/PauseMenu.tscn")

func _ready() -> void:
	print("GameManager initialized")

	# Connect to EventBus events
	EventBus.game_started.connect(_on_game_started)
	EventBus.player_died.connect(_on_player_died)
	EventBus.player_confirmed_action.connect(_on_player_confirmed_action)

# Initialization function called by main scene
func initialize(managers: Dictionary, ui_nodes: Dictionary, scene_nodes: Dictionary) -> void:
	print("GameManager: Initializing with managers and UI")

	# Store manager references
	input_manager = managers.get("input_manager")
	ai_manager = managers.get("ai_manager")
	combat_manager = managers.get("combat_manager")
	board_manager = scene_nodes.get("board_manager")

	# Store UI references
	phase_label = ui_nodes.get("phase_label")
	status_label = ui_nodes.get("status_label")
	player_modes_label = ui_nodes.get("player_modes_label")

	# Connect to input manager signals
	if input_manager:
		input_manager.player_confirmed.connect(_on_player_confirmed)
		input_manager.player_cancelled.connect(_on_player_cancelled)

	# Connect to player mode changes through board manager
	if board_manager and board_manager.has_method("connect_player_mode_signals"):
		board_manager.connect_player_mode_signals(_on_player_mode_changed)

	# Initialize displays
	update_phase_display()
	update_modes_display()

	# Start the first turn after a brief delay
	await get_tree().create_timer(0.5).timeout
	start_game()

# Main update loop - controls execution order
func _physics_process(delta: float) -> void:
	# Execute managers in controlled order:
	# 1. InputManager -> 2. AIManager -> 3. Movement/Physics -> 4. CombatManager -> 5. Animation/FX

	if input_manager:
		input_manager.update(delta)

	# AI updates happen during specific phases
	if ai_manager and current_phase == TurnPhase.ENEMY_DECISION:
		ai_manager.update(delta)

	if combat_manager:
		combat_manager.update(delta)

# Game state management
func start_game() -> void:
	print("GameManager: Starting game")
	EventBus.game_started.emit()
	start_enemy_decision_phase()

func end_game(reason: String) -> void:
	print("GameManager: Game ended - ", reason)
	EventBus.game_over.emit(reason)

# Turn phase management
func start_enemy_decision_phase() -> void:
	current_phase = TurnPhase.ENEMY_DECISION
	turn_phase_changed.emit(current_phase)
	EventBus.turn_phase_changed.emit(current_phase)
	update_phase_display()
	print("GameManager: Entering EnemyDecision phase")

	# Execute enemy AI decisions through AIManager
	if ai_manager and board_manager:
		var enemies = board_manager.get_all_enemies()
		var players = board_manager.get_all_players()
		ai_manager.make_enemy_decisions(enemies, players)

	# Proceed to player decision phase after a brief delay
	await get_tree().create_timer(1.0).timeout
	start_player_decision_phase()

func start_player_decision_phase() -> void:
	current_phase = TurnPhase.PLAYER_DECISION
	turn_phase_changed.emit(current_phase)
	EventBus.turn_phase_changed.emit(current_phase)
	update_phase_display()
	print("GameManager: Entering PlayerDecision phase")

	# Reset confirmations for next turn
	reset_player_confirmations()

func start_player_move_phase() -> void:
	current_phase = TurnPhase.PLAYER_MOVE
	turn_phase_changed.emit(current_phase)
	EventBus.turn_phase_changed.emit(current_phase)
	update_phase_display()
	print("GameManager: Entering PlayerMove phase")

	# Execute all player movements
	execute_player_movements()

	# Move to enemy move phase after player movement
	await get_tree().create_timer(1.0).timeout
	start_enemy_move_phase()

func start_enemy_move_phase() -> void:
	current_phase = TurnPhase.ENEMY_MOVE
	turn_phase_changed.emit(current_phase)
	EventBus.turn_phase_changed.emit(current_phase)
	update_phase_display()
	print("GameManager: Entering EnemyMove phase")

	# Execute enemy movement through AIManager
	var enemy_positions = []
	if ai_manager and board_manager:
		var enemies = board_manager.get_all_enemies()
		enemy_positions = ai_manager.execute_enemy_movements(enemies)

	# Check for player death using CombatManager
	var player_died = check_player_death_collisions(enemy_positions)
	if player_died:
		show_game_over_dialog()
		return

	# Check if any players are in attack mode to proceed to attack phase
	await get_tree().create_timer(1.0).timeout

	if has_players_in_attack_mode():
		start_player_attack_phase()
	else:
		start_enemy_decision_phase()

func start_player_attack_phase() -> void:
	current_phase = TurnPhase.PLAYER_ATTACK
	turn_phase_changed.emit(current_phase)
	EventBus.turn_phase_changed.emit(current_phase)
	update_phase_display()
	print("GameManager: Entering PlayerAttack phase")

	# Execute all player attacks through CombatManager
	if combat_manager and board_manager:
		var players = board_manager.get_all_players()
		combat_manager.perform_player_attacks(players)

	# Return to enemy decision phase after attacks
	await get_tree().create_timer(1.0).timeout
	start_enemy_decision_phase()

# Player action handling
func _on_player_confirmed(player_id: int) -> void:
	if current_phase == TurnPhase.PLAYER_DECISION:
		player_confirmations[player_id] = true
		# Capture the direction at confirmation time
		if input_manager:
			player_confirmed_directions[player_id] = input_manager.get_player_direction_vector(player_id)

		print("GameManager: Player ", player_id, " confirmed with direction: ", player_confirmed_directions[player_id])
		update_status_display()
		check_all_players_ready()

func _on_player_cancelled(player_id: int) -> void:
	if current_phase == TurnPhase.PLAYER_DECISION:
		player_confirmations[player_id] = false
		print("GameManager: Player ", player_id, " cancelled confirmation")
		update_status_display()
	else:
		print("GameManager: Player ", player_id, " cancellation ignored - not in decision phase")

func check_all_players_ready() -> void:
	# Check if all players have confirmed their actions
	var all_confirmed = true
	for pid in [1, 2]:
		if not board_manager:
			continue

		var player = board_manager.get_player(pid)
		if player:
			if player.get_current_mode() == 1: # ATTACK mode
				# For attack mode, check if shooting indicator is locked
				if not (player.shooting_indicator and player.shooting_indicator.is_indicator_locked()):
					all_confirmed = false
					break
			else: # PlayerMode.MOVE
				# For move mode, check if move is confirmed
				if not player_confirmations[pid]:
					all_confirmed = false
					break

	print("GameManager: All players ready - ", all_confirmed)
	if all_confirmed:
		EventBus.all_players_ready.emit()
		start_player_move_phase()

func execute_player_movements() -> void:
	print("GameManager: Executing player movements")

	if not board_manager:
		return

	for player_id in [1, 2]:
		if player_confirmations[player_id]:
			var player = board_manager.get_player(player_id)
			if player and player.get_current_mode() == 1: # ATTACK mode
				print("Player ", player_id, " is in attack mode - skipping movement")
				continue

			var direction = player_confirmed_directions[player_id]
			board_manager.move_player(player_id, direction)

			# Emit movement event
			if player:
				EventBus.player_moved.emit(player,
					Vector2i(player.grid_x - direction.x, player.grid_y - direction.y),
					Vector2i(player.grid_x, player.grid_y))

func reset_player_confirmations() -> void:
	# Reset confirmation state for new turn
	player_confirmations[1] = false
	player_confirmations[2] = false
	player_confirmed_directions[1] = Vector2i.ZERO
	player_confirmed_directions[2] = Vector2i.ZERO

	# Reset player confirmation states through board manager
	if board_manager:
		for player_id in [1, 2]:
			var player = board_manager.get_player(player_id)
			if player and player.has_method("reset_confirmation_state"):
				player.reset_confirmation_state()

# Utility functions
func is_decision_phase() -> bool:
	return current_phase == TurnPhase.PLAYER_DECISION

func has_players_in_attack_mode() -> bool:
	if not board_manager:
		return false

	for player_id in [1, 2]:
		var player = board_manager.get_player(player_id)
		if player and player.get_current_mode() == 1: # ATTACK mode
			if player.shooting_indicator and player.shooting_indicator.is_indicator_locked():
				return true
	return false

func check_player_death_collisions(enemy_positions: Array) -> bool:
	if not board_manager:
		return false

	# Check if any enemy moved to a player's position
	for player_id in [1, 2]:
		var player = board_manager.get_player(player_id)
		if not player:
			continue

		var player_pos = Vector2i(player.grid_x, player.grid_y)
		for enemy_pos in enemy_positions:
			if enemy_pos == player_pos:
				print("GameManager: Player ", player_id, " killed by enemy collision")
				EventBus.player_died.emit(player, "enemy_collision")
				return true

	return false

# UI management
func update_phase_display() -> void:
	if not phase_label:
		return

	match current_phase:
		TurnPhase.ENEMY_DECISION:
			phase_label.text = "Phase: EnemyDecision"
		TurnPhase.PLAYER_DECISION:
			phase_label.text = "Phase: PlayerDecision"
		TurnPhase.PLAYER_MOVE:
			phase_label.text = "Phase: PlayerMove"
		TurnPhase.ENEMY_MOVE:
			phase_label.text = "Phase: EnemyMove"
		TurnPhase.PLAYER_ATTACK:
			phase_label.text = "Phase: PlayerAttack"

	update_status_display()

func update_status_display() -> void:
	if not status_label:
		return

	var p1_status = "⏳"  # Waiting
	var p2_status = "⏳"  # Waiting

	if player_confirmations[1]:
		p1_status = "✅"  # Confirmed
	if player_confirmations[2]:
		p2_status = "✅"  # Confirmed

	status_label.text = "Player 1: " + p1_status + " | Player 2: " + p2_status

func _on_player_mode_changed(player_id: int, new_mode) -> void:
	# Update player mode display
	match new_mode:
		0: # MOVE mode
			player_modes[player_id] = "Move"
		1: # ATTACK mode
			player_modes[player_id] = "Attack"
		_:
			player_modes[player_id] = "Unknown"

	update_modes_display()

func update_modes_display() -> void:
	if player_modes_label:
		player_modes_label.text = "P1 Mode: " + player_modes[1] + " | P2 Mode: " + player_modes[2]

# Input handling for pause/restart
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not get_tree().paused:
		show_pause_menu()

# Game over and pause dialogs
func show_game_over_dialog() -> void:
	print("GameManager: GAME OVER - Player died!")
	# TODO: Implement restart dialog
	# var restart_dialog = restart_dialog_scene.instantiate()
	# restart_dialog.restart_requested.connect(_on_restart_requested)
	# get_tree().current_scene.add_child(restart_dialog)
	# restart_dialog.show_dialog()

func show_pause_menu() -> void:
	print("GameManager: Showing pause menu")
	var pause_menu = pause_menu_scene.instantiate()
	pause_menu.resume_requested.connect(_on_resume_requested)
	pause_menu.restart_requested.connect(_on_restart_requested)
	get_tree().current_scene.add_child(pause_menu)
	pause_menu.show_pause_menu()

func _on_restart_requested() -> void:
	restart_game()

func _on_resume_requested() -> void:
	print("GameManager: Resuming game")
	get_tree().paused = false

func restart_game() -> void:
	print("GameManager: Restarting game")
	get_tree().paused = false
	EventBus.game_restarted.emit()
	get_tree().reload_current_scene()

# Event handlers
func _on_game_started() -> void:
	print("GameManager: Game started event received")

func _on_player_died(player: Node, cause: String) -> void:
	print("GameManager: Player died event received - ", cause)
	end_game("player_death")

func _on_player_confirmed_action(player: Node) -> void:
	if current_phase == TurnPhase.PLAYER_DECISION and player:
		var player_id = player.player_id
		if player.get_current_mode() == 1: # ATTACK mode
			player_confirmations[player_id] = true
			print("GameManager: Player ", player_id, " attack confirmed via EventBus")
			update_status_display()
			check_all_players_ready()
