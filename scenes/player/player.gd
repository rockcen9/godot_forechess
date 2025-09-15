extends Node2D
class_name Player

var grid_x: int
var grid_y: int

func setup(x: int, y: int) -> void:
	grid_x = x
	grid_y = y

	# Set position based on grid coordinates (following BoardTile pattern)
	position = Vector2(x * 64, y * 64)

	# Make player visible by drawing
	queue_redraw()

func _draw() -> void:
	# Draw a simple colored circle to represent the player
	var tile_size = 64
	var radius = tile_size * 0.3
	var center = Vector2(tile_size/2, tile_size/2)
	draw_circle(center, radius, Color.BLUE)