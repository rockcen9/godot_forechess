extends Node

enum TurnPhase {
	PLAYER_DECISION,
	PLAYER_MOVE
}

signal turn_phase_changed(new_phase: TurnPhase)

var current_phase: TurnPhase = TurnPhase.PLAYER_DECISION
var player_confirmations: Dictionary = {
	1: false,
	2: false
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
		print("Player ", player_id, " confirmed their move")
		update_status_display()

		# Check if all players have confirmed
		var all_confirmed = true
		for confirmed in player_confirmations.values():
			if not confirmed:
				all_confirmed = false
				break

		if all_confirmed:
			start_player_move_phase()

func start_player_move_phase() -> void:
	current_phase = TurnPhase.PLAYER_MOVE
	turn_phase_changed.emit(current_phase)
	update_phase_display()
	print("Entering PlayerMove phase")

	# Execute all player movements
	execute_player_movements()

	# Return to decision phase after movement
	await get_tree().create_timer(1.0).timeout # Brief pause to see movement
	start_player_decision_phase()

func start_player_decision_phase() -> void:
	current_phase = TurnPhase.PLAYER_DECISION
	turn_phase_changed.emit(current_phase)
	update_phase_display()
	print("Entering PlayerDecision phase")

	# Reset confirmations for next turn
	player_confirmations[1] = false
	player_confirmations[2] = false

	# Reset player confirmation states
	reset_player_confirmations()

func update_phase_display() -> void:
	if phase_label:
		match current_phase:
			TurnPhase.PLAYER_DECISION:
				phase_label.text = "Phase: PlayerDecision"
			TurnPhase.PLAYER_MOVE:
				phase_label.text = "Phase: PlayerMove"
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
	for player_id in [1, 2]:
		if player_confirmations[player_id]:
			var direction = input_manager.get_player_direction_vector(player_id)
			board_manager.move_player(player_id, direction)

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