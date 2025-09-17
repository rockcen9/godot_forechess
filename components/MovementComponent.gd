extends Node

# MovementComponent: Pure composition-based movement functionality
# No inheritance or interfaces - just movement behavior

signal position_changed(old_pos: Vector2i, new_pos: Vector2i)
signal movement_blocked(attempted_pos: Vector2i)

var grid_position: Vector2i = Vector2i.ZERO
var movement_speed: float = 1.0
var can_move: bool = true
var bounds_rect: Rect2i = Rect2i(0, 0, 8, 8)

func _ready() -> void:
	print("MovementComponent initialized")

func setup(initial_pos: Vector2i, speed: float = 1.0, movement_bounds: Rect2i = Rect2i(0, 0, 8, 8)) -> void:
	grid_position = initial_pos
	movement_speed = speed
	bounds_rect = movement_bounds

func move_to(new_position: Vector2i) -> bool:
	if not can_move:
		return false

	if not is_position_valid(new_position):
		movement_blocked.emit(new_position)
		return false

	var old_position = grid_position
	grid_position = new_position
	position_changed.emit(old_position, new_position)
	return true

func move_by_direction(direction: Vector2i) -> bool:
	var target_position = grid_position + direction
	return move_to(target_position)

func is_position_valid(pos: Vector2i) -> bool:
	return bounds_rect.has_point(pos)

func get_grid_position() -> Vector2i:
	return grid_position

func get_world_position(tile_size: int = 20) -> Vector2:
	return Vector2(grid_position.x * tile_size + tile_size/2, grid_position.y * tile_size + tile_size/2)

func set_movement_enabled(enabled: bool) -> void:
	can_move = enabled

func set_bounds(new_bounds: Rect2i) -> void:
	bounds_rect = new_bounds

func calculate_distance_to(target_pos: Vector2i) -> float:
	return grid_position.distance_to(target_pos)

func calculate_direction_to(target_pos: Vector2i) -> Vector2i:
	var diff = target_pos - grid_position
	if diff == Vector2i.ZERO:
		return Vector2i.ZERO

	# Return cardinal direction (no diagonals)
	if abs(diff.x) > abs(diff.y):
		return Vector2i(sign(diff.x), 0)
	else:
		return Vector2i(0, sign(diff.y))