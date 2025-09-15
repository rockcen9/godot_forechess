extends Node2D

const BOARD_SIZE := 8
var board_tiles: Array[Array] = []
var tile_scene: PackedScene = preload("res://scenes/board/BoardTile.tscn")
var player_scene: PackedScene = preload("res://scenes/player/Player.tscn")
var player

func _ready() -> void:
	init_board()
	center_board()
	spawn_player()

func init_board():
	for x in BOARD_SIZE:
		board_tiles.append([])
		for y in BOARD_SIZE:
			var tile = tile_scene.instantiate()
			tile.setup(x, y, (x + y) % 2 == 0)
			add_child(tile)
			board_tiles[x].append(tile)

func center_board() -> void:
	var board_pixel_size = BOARD_SIZE * 20 # 20 pixels per tile
	# Center the board around (0,0) which is where the camera is
	position = Vector2(-board_pixel_size / 2, -board_pixel_size / 2)

func spawn_player() -> void:
	player = player_scene.instantiate()
	player.setup(2, 6)
	add_child(player)
