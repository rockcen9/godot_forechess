extends Node2D
class_name ShootingIndicator

var player_id: int
var is_locked: bool = false
var indicator_length: float = 48.0
var line_width: float = 3.0

# Colors for the indicator
var active_color: Color = Color.RED
var locked_color: Color = Color.ORANGE

func setup(id: int) -> void:
	player_id = id
	visible = false

func _draw() -> void:
	if not visible:
		return

	# Draw the shooting line from center outward
	var end_point = Vector2(indicator_length, 0)
	var color = locked_color if is_locked else active_color

	# Draw the main line
	draw_line(Vector2.ZERO, end_point, color, line_width)

	# Draw arrowhead at the end
	var arrow_size = 8.0
	var arrow_point1 = end_point + Vector2(-arrow_size, -arrow_size/2)
	var arrow_point2 = end_point + Vector2(-arrow_size, arrow_size/2)

	draw_line(end_point, arrow_point1, color, line_width)
	draw_line(end_point, arrow_point2, color, line_width)

func show_indicator() -> void:
	visible = true
	queue_redraw()

func hide_indicator() -> void:
	visible = false
	is_locked = false
	queue_redraw()

func update_rotation_from_stick(stick_input: Vector2) -> void:
	if is_locked:
		return

	if stick_input.length() > 0.1:  # Dead zone
		var angle = stick_input.angle()
		rotation = angle
		queue_redraw()

func lock_indicator() -> void:
	is_locked = true
	queue_redraw()

func unlock_indicator() -> void:
	is_locked = false
	queue_redraw()

func is_indicator_locked() -> bool:
	return is_locked