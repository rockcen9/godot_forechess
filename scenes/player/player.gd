extends Node2D
class_name Player

var grid_x: int
var grid_y: int

func setup(x: int, y: int) -> void:
	grid_x = x
	grid_y = y

	# Set position based on grid coordinates (following BoardTile pattern)
	position = Vector2(x * 64, y * 64)