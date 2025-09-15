extends Node2D

const BOARD_SIZE := 16
var board_tiles: Array[Array] = []
var tile_scene := preload("res://scenes/BoardTile.tscn")

func init_board():
	for x in BOARD_SIZE:
		board_tiles.append([])
		for y in BOARD_SIZE:
			var tile = tile_scene.instantiate()
			tile.setup(x, y, (x + y) % 2 == 0)
			add_child(tile)
			board_tiles[x].append(tile)
