extends Node

# PlayerManager: Centralized player management and coordination
# Responsible for: Player controller management, player state coordination, player action validation
# API: register_player(), get_player_controller(), are_all_players_ready()

class_name PlayerManager

signal all_players_ready()
signal player_status_changed(player_id: int, status_data: Dictionary)

# Player controllers indexed by player_id
var player_controllers: Dictionary = {}
var player_confirmations: Dictionary = {}
var player_confirmed_directions: Dictionary = {}

# Reference to board manager for position queries
var board_manager: Node

func _ready() -> void:
	print("PlayerManager initialized")

# Manager API
func initialize(board_ref: Node) -> void:
	board_manager = board_ref

	# Auto-discover and register existing players
	discover_and_register_players()

func update(delta: float) -> void:
	# Handle any continuous player management logic
	pass

# Player registration and management
func discover_and_register_players() -> void:
	if not board_manager:
		print("PlayerManager: No board manager reference")
		return

	# Get players from board manager
	for player_id in [1, 2]:
		var player = board_manager.get_player(player_id) if board_manager.has_method("get_player") else null
		if player:
			register_player(player)

func register_player(player: Node) -> void:
	var player_id = 0
	# Try property first, then method
	if "player_id" in player:
		player_id = player.player_id
	elif player.has_method("get_player_id"):
		player_id = player.get_player_id()
	else:
		print("PlayerManager: Warning - Could not get player_id from ", player)

	if player_id == 0:
		print("PlayerManager: Cannot register player with invalid ID")
		return

	# Create controller for player
	var controller = preload("res://components/PlayerController.gd").new()
	controller.name = "PlayerController" + str(player_id)
	add_child(controller)

	# Initialize controller
	controller.initialize(player)

	# Store controller reference
	player_controllers[player_id] = controller
	player_confirmations[player_id] = false
	player_confirmed_directions[player_id] = Vector2i.ZERO

	# Connect controller signals
	controller.player_state_changed.connect(_on_player_state_changed)
	controller.player_action_ready.connect(_on_player_action_ready)

	print("PlayerManager: Registered player ", player_id)

func unregister_player(player_id: int) -> void:
	if player_id not in player_controllers:
		return

	var controller = player_controllers[player_id]
	player_controllers.erase(player_id)
	player_confirmations.erase(player_id)
	player_confirmed_directions.erase(player_id)

	if is_instance_valid(controller):
		controller.queue_free()

	print("PlayerManager: Unregistered player ", player_id)

# Player state management
func reset_all_player_confirmations() -> void:
	for player_id in player_controllers.keys():
		reset_player_confirmation(player_id)

func reset_player_confirmation(player_id: int) -> void:
	var controller = get_player_controller(player_id)
	if controller:
		controller.reset_confirmation_state()

	player_confirmations[player_id] = false
	player_confirmed_directions[player_id] = Vector2i.ZERO

func set_player_confirmation(player_id: int, confirmed: bool, direction: Vector2i = Vector2i.ZERO) -> void:
	player_confirmations[player_id] = confirmed
	if confirmed:
		player_confirmed_directions[player_id] = direction

	var controller = get_player_controller(player_id)
	if controller:
		controller.set_confirmation_state(confirmed, direction)

	# Check if all players are ready
	check_all_players_ready()

# Player readiness checks
func are_all_players_ready() -> bool:
	for player_id in player_controllers.keys():
		if not is_player_ready(player_id):
			return false
	return true

func is_player_ready(player_id: int) -> bool:
	var controller = get_player_controller(player_id)
	if not controller:
		return false

	return controller.is_ready_for_action()

func check_all_players_ready() -> void:
	if are_all_players_ready():
		print("PlayerManager: All players ready")
		all_players_ready.emit()

# Player action execution
func execute_player_movements() -> void:
	print("PlayerManager: Executing player movements")

	for player_id in player_controllers.keys():
		if not player_confirmations.get(player_id, false):
			continue

		var controller = get_player_controller(player_id)
		if not controller:
			continue

		# Skip if player is in attack mode
		if controller.get_current_mode() == 1:
			print("PlayerManager: Player ", player_id, " in attack mode - skipping movement")
			continue

		var direction = player_confirmed_directions.get(player_id, Vector2i.ZERO)
		if direction != Vector2i.ZERO:
			execute_player_movement(player_id, direction)

func execute_player_movement(player_id: int, direction: Vector2i) -> bool:
	var controller = get_player_controller(player_id)
	if not controller:
		return false

	var old_pos = controller.get_position()
	var success = false

	# Try to execute movement through board manager
	if board_manager and board_manager.has_method("move_player"):
		var result = board_manager.move_player(player_id, direction)
		success = result if result != null else false
	else:
		# Fallback to controller movement
		var result = controller.execute_movement(direction)
		success = result if result != null else false

	if success:
		var new_pos = controller.get_position()
		print("PlayerManager: Player ", player_id, " moved from ", old_pos, " to ", new_pos)

		# Emit movement event
		EventBus.player_moved.emit(controller.get_entity(), old_pos, new_pos)

	return success

func get_players_in_attack_mode() -> Array[int]:
	var attack_players: Array[int] = []

	for player_id in player_controllers.keys():
		var controller = get_player_controller(player_id)
		if controller and controller.get_current_mode() == 1 and controller.is_attack_ready():
			attack_players.append(player_id)

	return attack_players

func has_players_in_attack_mode() -> bool:
	return not get_players_in_attack_mode().is_empty()

# Controller access
func get_player_controller(player_id: int) -> PlayerController:
	return player_controllers.get(player_id, null)

func get_all_player_controllers() -> Array[PlayerController]:
	var controllers: Array[PlayerController] = []
	for controller in player_controllers.values():
		if is_instance_valid(controller):
			controllers.append(controller)
	return controllers

func get_player_entity(player_id: int) -> Node:
	var controller = get_player_controller(player_id)
	return controller.get_entity() if controller else null

func get_all_player_entities() -> Array[Node]:
	var players: Array[Node] = []
	for controller in get_all_player_controllers():
		var entity = controller.get_entity()
		if entity:
			players.append(entity)
	return players

# Utility functions
func get_player_confirmation_data() -> Dictionary:
	var data = {}
	for player_id in player_controllers.keys():
		var controller = get_player_controller(player_id)
		data[player_id] = {
			"confirmed": player_confirmations.get(player_id, false),
			"direction": player_confirmed_directions.get(player_id, Vector2i.ZERO),
			"mode": controller.get_current_mode() if controller else 0,
			"ready": controller.is_ready_for_action() if controller else false
		}
	return data

func get_player_modes() -> Dictionary:
	var modes = {}
	for player_id in player_controllers.keys():
		var controller = get_player_controller(player_id)
		modes[player_id] = controller.get_current_mode() if controller else 0
	return modes

# Event handlers
func _on_player_state_changed(player_id: int, state_data: Dictionary) -> void:
	print("PlayerManager: Player ", player_id, " state changed: ", state_data)

	# Update local tracking
	player_confirmations[player_id] = state_data.get("confirmed", false)

	# Emit for other systems
	player_status_changed.emit(player_id, state_data)

	# Check readiness
	check_all_players_ready()

func _on_player_action_ready(player_id: int, action_data: Dictionary) -> void:
	print("PlayerManager: Player ", player_id, " action ready: ", action_data)

	# Update confirmation state
	player_confirmations[player_id] = true

	# Check if all players are ready
	check_all_players_ready()

# Debug and statistics
func get_player_statistics() -> Dictionary:
	return {
		"registered_players": player_controllers.size(),
		"confirmed_players": player_confirmations.values().count(true),
		"all_ready": are_all_players_ready(),
		"attack_mode_players": get_players_in_attack_mode().size()
	}
