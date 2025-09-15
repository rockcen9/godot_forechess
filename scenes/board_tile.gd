extends Node2D
class_name BoardTile

var grid_x: int
var grid_y: int
var is_light: bool

func setup(x: int, y: int, light: bool) -> void:
	grid_x = x
	grid_y = y
	is_light = light

	# Set position based on grid coordinates
	position = Vector2(x * 64, y * 64)  # Assuming 64x64 pixel tiles

	# You can add visual representation here
	# For now, just a simple colored rectangle
	queue_redraw()

func _draw() -> void:
	var tile_size = Vector2(64, 64)
	var color = Color.WHITE if is_light else Color.GRAY
	draw_rect(Rect2(Vector2.ZERO, tile_size), color)
