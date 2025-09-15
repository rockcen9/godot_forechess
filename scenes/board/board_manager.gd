extends Node2D

const BOARD_SIZE := 8
var board_tiles: Array[Array] = []
var tile_scene: PackedScene = preload("res://scenes/board/BoardTile.tscn")
var player_scene: PackedScene = preload("res://scenes/player/Player.tscn")
var enemy_scene: PackedScene = preload("res://scenes/enemy/Enemy.tscn")
var players: Dictionary = {}
var enemies: Dictionary = {}

func _ready() -> void:
	init_board()
	center_board()
	spawn_player()
	spawn_player2()
	spawn_enemy_king()

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
	var player = player_scene.instantiate()
	player.setup(2, 6, 1)  # player_id = 1
	add_child(player)
	players[1] = player

func spawn_player2() -> void:
	var player2 = player_scene.instantiate()
	player2.setup(5, 6, 2)  # player_id = 2
	add_child(player2)
	players[2] = player2

func move_player(player_id: int, direction: Vector2i) -> void:
	if not players.has(player_id):
		return

	var player = players[player_id]
	var new_x = player.grid_x + direction.x
	var new_y = player.grid_y + direction.y

	# Check bounds
	if new_x < 0 or new_x >= BOARD_SIZE or new_y < 0 or new_y >= BOARD_SIZE:
		print("Player ", player_id, " cannot move outside board bounds")
		return

	# Move the player
	player.move_to(new_x, new_y)
	print("Player ", player_id, " moved to (", new_x, ", ", new_y, ")")

func spawn_enemy_king() -> void:
	var enemy = enemy_scene.instantiate()
	enemy.setup(3, 3, 1)  # enemy_id = 1
	add_child(enemy)
	enemies[1] = enemy

func get_player(player_id: int) -> Player:
	return players.get(player_id, null)

func get_enemy(enemy_id: int) -> Enemy:
	return enemies.get(enemy_id, null)

func connect_player_mode_signals(callback: Callable) -> void:
	# Connect player mode change signals to the provided callback
	for player_id in players.keys():
		var player = players[player_id]
		if player:
			player.player_mode_changed.connect(callback)
