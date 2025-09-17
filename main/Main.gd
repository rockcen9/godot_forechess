extends Node2D

# Main: Entry point that coordinates manager initialization and scene setup
# Responsible for: Manager injection, scene coordination, initial setup

# Manager instances - using composition pattern with Node references
var game_manager: Node
var input_manager: Node
var ai_manager: Node
var combat_manager: Node
var audio_manager: Node

# Scene nodes
@onready var board_manager: Node2D = $BoardManager
@onready var ui_container: Control = $UI

# UI nodes
@onready var phase_label: Label = $UI/PhaseLabel
@onready var status_label: Label = $UI/StatusLabel
@onready var player_modes_label: Label = $UI/PlayerModesLabel

func _ready() -> void:
	print("Main: Initializing Manager/Service architecture")

	# Initialize all managers
	initialize_managers()

	# Setup manager references and dependencies
	setup_manager_dependencies()

	# Initialize game manager with all references
	initialize_game_manager()

	# Connect input manager to entities
	connect_input_to_entities()

	print("Main: Manager architecture initialized successfully")

func initialize_managers() -> void:
	print("Main: Creating manager instances")

	# Load manager scripts and create instances using composition
	var GameManagerScript = load("res://managers/GameManager.gd")
	var InputManagerScript = load("res://managers/InputManager.gd")
	var AIManagerScript = load("res://managers/AIManager.gd")
	var CombatManagerScript = load("res://managers/CombatManager.gd")
	var AudioManagerScript = load("res://managers/AudioManager.gd")

	# Create manager instances
	game_manager = GameManagerScript.new()
	game_manager.name = "GameManager"
	add_child(game_manager)

	input_manager = InputManagerScript.new()
	input_manager.name = "InputManager"
	add_child(input_manager)

	ai_manager = AIManagerScript.new()
	ai_manager.name = "AIManager"
	add_child(ai_manager)

	combat_manager = CombatManagerScript.new()
	combat_manager.name = "CombatManager"
	add_child(combat_manager)

	audio_manager = AudioManagerScript.new()
	audio_manager.name = "AudioManager"
	add_child(audio_manager)

func setup_manager_dependencies() -> void:
	print("Main: Setting up manager dependencies")

	# Managers don't directly reference each other
	# They communicate through EventBus or through GameManager coordination

func initialize_game_manager() -> void:
	print("Main: Initializing GameManager with references")

	# Prepare manager references
	var managers = {
		"input_manager": input_manager,
		"ai_manager": ai_manager,
		"combat_manager": combat_manager,
		"audio_manager": audio_manager
	}

	# Prepare UI references
	var ui_nodes = {
		"phase_label": phase_label,
		"status_label": status_label,
		"player_modes_label": player_modes_label
	}

	# Prepare scene references
	var scene_nodes = {
		"board_manager": board_manager
	}

	# Initialize GameManager with all dependencies
	game_manager.initialize(managers, ui_nodes, scene_nodes)

func connect_input_to_entities() -> void:
	print("Main: Connecting input manager to entities")

	if not input_manager:
		return

	# Connect input signals to all players
	var players = get_tree().get_nodes_in_group("player")
	for player in players:
		if player.has_method("on_direction_input"):
			input_manager.player_direction_changed.connect(
				func(player_id: int, direction: Vector2i):
					if player.player_id == player_id:
						player.on_direction_input(direction)
			)

		if player.has_method("on_stick_input"):
			input_manager.player_stick_input.connect(
				func(player_id: int, stick_vector: Vector2):
					if player.player_id == player_id:
						player.on_stick_input(stick_vector)
			)

		if player.has_method("on_confirm_input"):
			input_manager.player_confirmed.connect(
				func(player_id: int):
					if player.player_id == player_id:
						player.on_confirm_input()
			)

		if player.has_method("on_cancel_input"):
			input_manager.player_cancelled.connect(
				func(player_id: int):
					if player.player_id == player_id:
						player.on_cancel_input()
			)

		if player.has_method("on_mode_switch_input"):
			input_manager.player_mode_switched.connect(
				func(player_id: int):
					if player.player_id == player_id:
						player.on_mode_switch_input()
			)

# Example of how to handle dynamic entity creation
func _on_entity_spawned(entity: Node) -> void:
	print("Main: New entity spawned - ", entity.name)

	# If it's a player, connect input
	if entity.is_in_group("player"):
		connect_player_input(entity)

	# Notify managers of new entity
	if entity.is_in_group("enemy"):
		EventBus.enemy_spawned.emit(entity)
	elif entity.is_in_group("player"):
		EventBus.player_spawned.emit(entity)

func connect_player_input(player: Node) -> void:
	# Connect input for dynamically spawned players
	# Same logic as connect_input_to_entities but for single player
	pass

# Debug and testing functions
func _input(event: InputEvent) -> void:
	# Handle global debug input
	if event.is_action_pressed("ui_debug"):
		print_manager_debug_info()

func print_manager_debug_info() -> void:
	print("=== MANAGER DEBUG INFO ===")

	if game_manager:
		print("GameManager: Current phase - ", game_manager.current_phase)

	if input_manager:
		print("InputManager: Input enabled - ", input_manager.input_enabled)

	if ai_manager:
		var ai_stats = ai_manager.get_ai_statistics()
		print("AIManager: ", ai_stats)

	if combat_manager:
		var combat_stats = combat_manager.get_combat_statistics()
		print("CombatManager: ", combat_stats)

	if audio_manager:
		var audio_stats = audio_manager.get_audio_statistics()
		print("AudioManager: ", audio_stats)

	print("=== END DEBUG INFO ===")

# Cleanup and shutdown
func _exit_tree() -> void:
	print("Main: Shutting down Manager architecture")

	# Cleanup managers if needed
	if audio_manager:
		audio_manager.stop_all_audio()

	if game_manager:
		game_manager.end_game("shutdown")

# Example of manager API usage from external scripts
func get_manager(manager_name: String) -> Node:
	match manager_name:
		"game":
			return game_manager
		"input":
			return input_manager
		"ai":
			return ai_manager
		"combat":
			return combat_manager
		"audio":
			return audio_manager
		_:
			return null

func is_manager_ready(manager_name: String) -> bool:
	var manager = get_manager(manager_name)
	return manager != null and is_instance_valid(manager)