extends Resource

# PlayerModeData: Data-driven player mode configuration
# Responsible for: Mode behavior definitions, validation rules, UI display
# API: can_execute_action(), get_mode_name(), requires_confirmation()

class_name PlayerModeData

enum PlayerMode {
	MOVE = 0,
	ATTACK = 1
}

@export var mode_id: PlayerMode
@export var mode_name: String
@export var requires_direction_input: bool = true
@export var requires_target_lock: bool = false
@export var can_move: bool = true
@export var can_attack: bool = false
@export var confirmation_method: String = "button" # "button", "auto", "lock"

# Validation rules
@export var allow_zero_direction: bool = false
@export var requires_line_of_sight: bool = false
@export var max_range: float = 0.0

# UI configuration
@export var display_indicator: bool = false
@export var indicator_type: String = "none" # "arrow", "circle", "line"
@export var ui_color: Color = Color.WHITE

func _init(id: PlayerMode = PlayerMode.MOVE) -> void:
	mode_id = id
	setup_defaults()

func setup_defaults() -> void:
	match mode_id:
		PlayerMode.MOVE:
			mode_name = "Move"
			requires_direction_input = true
			requires_target_lock = false
			can_move = true
			can_attack = false
			confirmation_method = "button"
			allow_zero_direction = false
			display_indicator = false
			ui_color = Color.GREEN

		PlayerMode.ATTACK:
			mode_name = "Attack"
			requires_direction_input = false
			requires_target_lock = true
			can_move = false
			can_attack = true
			confirmation_method = "lock"
			requires_line_of_sight = true
			max_range = 8.0
			display_indicator = true
			indicator_type = "line"
			ui_color = Color.RED

# Behavior validation
func can_execute_action(player_state: Dictionary) -> bool:
	# Check if player can execute action in this mode
	match confirmation_method:
		"button":
			return player_state.get("confirmed", false)
		"auto":
			return validate_auto_conditions(player_state)
		"lock":
			return player_state.get("target_locked", false)
		_:
			return false

func validate_auto_conditions(player_state: Dictionary) -> bool:
	# For auto-confirmation modes
	if requires_direction_input and not allow_zero_direction:
		var direction = player_state.get("direction", Vector2i.ZERO)
		return direction != Vector2i.ZERO

	return true

func get_required_inputs() -> Array[String]:
	var inputs: Array[String] = []

	if requires_direction_input:
		inputs.append("direction")

	if requires_target_lock:
		inputs.append("target_lock")

	match confirmation_method:
		"button":
			inputs.append("confirm_button")
		"lock":
			inputs.append("target_locked")

	return inputs

func get_validation_requirements() -> Dictionary:
	return {
		"requires_direction": requires_direction_input,
		"requires_target": requires_target_lock,
		"allow_zero_direction": allow_zero_direction,
		"requires_los": requires_line_of_sight,
		"max_range": max_range,
		"confirmation_method": confirmation_method
	}

# UI helpers
func get_display_info() -> Dictionary:
	return {
		"name": mode_name,
		"color": ui_color,
		"show_indicator": display_indicator,
		"indicator_type": indicator_type
	}

# Mode comparison helpers
func is_move_mode() -> bool:
	return mode_id == PlayerMode.MOVE

func is_attack_mode() -> bool:
	return mode_id == PlayerMode.ATTACK

func allows_movement() -> bool:
	return can_move

func allows_attack() -> bool:
	return can_attack

# Factory methods for common configurations
static func create_move_mode() -> PlayerModeData:
	return PlayerModeData.new(PlayerMode.MOVE)

static func create_attack_mode() -> PlayerModeData:
	return PlayerModeData.new(PlayerMode.ATTACK)

# Debug info
func get_debug_info() -> Dictionary:
	return {
		"mode_id": mode_id,
		"mode_name": mode_name,
		"can_move": can_move,
		"can_attack": can_attack,
		"requires_direction": requires_direction_input,
		"requires_target": requires_target_lock,
		"confirmation": confirmation_method
	}