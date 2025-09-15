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

func _ready() -> void:
	# Connect to input manager signals
	input_manager.player_confirmed.connect(_on_player_confirmed)

func _on_player_confirmed(player_id: int) -> void:
	if current_phase == TurnPhase.PLAYER_DECISION:
		player_confirmations[player_id] = true
		print("Player ", player_id, " confirmed their move")

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
	print("Entering PlayerMove phase")

	# Execute all player movements
	execute_player_movements()

	# Return to decision phase after movement
	await get_tree().create_timer(1.0).timeout # Brief pause to see movement
	start_player_decision_phase()

func start_player_decision_phase() -> void:
	current_phase = TurnPhase.PLAYER_DECISION
	turn_phase_changed.emit(current_phase)
	print("Entering PlayerDecision phase")

	# Reset confirmations for next turn
	player_confirmations[1] = false
	player_confirmations[2] = false

func execute_player_movements() -> void:
	# Get player movement directions and execute them
	for player_id in [1, 2]:
		if player_confirmations[player_id]:
			var direction = input_manager.get_player_direction_vector(player_id)
			board_manager.move_player(player_id, direction)

func is_decision_phase() -> bool:
	return current_phase == TurnPhase.PLAYER_DECISION