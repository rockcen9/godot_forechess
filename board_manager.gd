extends Node2D

const BOARD_SIZE := 8
var board_tiles: Array[Array] = []
var tile_scene: PackedScene = preload("res://scenes/BoardTile.tscn")

func _ready() -> void:
	init_board()
	center_board()

func init_board():
	for x in BOARD_SIZE:
		board_tiles.append([])
		for y in BOARD_SIZE:
			var tile = tile_scene.instantiate()
			tile.setup(x, y, (x + y) % 2 == 0)
			add_child(tile)
			board_tiles[x].append(tile)

func center_board() -> void:
	var screen_size = get_viewport().get_visible_rect().size
	var board_pixel_size = BOARD_SIZE * 64  # 64 pixels per tile
	var center_offset = (screen_size - Vector2(board_pixel_size, board_pixel_size)) / 2
	position = center_offset
