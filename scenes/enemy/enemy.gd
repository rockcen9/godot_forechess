extends Node2D
class_name Enemy

var grid_x: int
var grid_y: int
var enemy_id: int

func setup(x: int, y: int, id: int) -> void:
	grid_x = x
	grid_y = y
	enemy_id = id

	# Set position based on grid coordinates, centered within the tile
	position = Vector2(x * 20 + 10, y * 20 + 10)  # +10 to center in 20px tile

func move_to(new_x: int, new_y: int) -> void:
	grid_x = new_x
	grid_y = new_y
	position = Vector2(new_x * 20 + 10, new_y * 20 + 10)