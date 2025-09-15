extends Node2D
class_name Enemy

var grid_x: int
var grid_y: int
var enemy_id: int
var health: int = 100
var max_health: int = 100

# Health bar display
var health_bar_bg: ColorRect
var health_bar_fg: ColorRect

func setup(x: int, y: int, id: int) -> void:
	grid_x = x
	grid_y = y
	enemy_id = id

	# Set position based on grid coordinates, centered within the tile
	position = Vector2(x * 20 + 10, y * 20 + 10)  # +10 to center in 20px tile

func _ready() -> void:
	create_health_bar()

func create_health_bar() -> void:
	# Create health bar background
	health_bar_bg = ColorRect.new()
	health_bar_bg.size = Vector2(16, 3)
	health_bar_bg.position = Vector2(-8, -12)  # Above the enemy
	health_bar_bg.color = Color.BLACK
	add_child(health_bar_bg)

	# Create health bar foreground
	health_bar_fg = ColorRect.new()
	health_bar_fg.size = Vector2(16, 3)
	health_bar_fg.position = Vector2(-8, -12)
	health_bar_fg.color = Color.GREEN
	add_child(health_bar_fg)

func move_to(new_x: int, new_y: int) -> void:
	grid_x = new_x
	grid_y = new_y
	position = Vector2(new_x * 20 + 10, new_y * 20 + 10)

func take_damage(damage: int) -> void:
	health -= damage
	health = max(0, health)  # Ensure health doesn't go below 0
	print("Enemy ", enemy_id, " took ", damage, " damage. Health: ", health, "/", max_health)
	update_health_bar()

func get_health() -> int:
	return health

func is_alive() -> bool:
	return health > 0

func get_health_percentage() -> float:
	return float(health) / float(max_health)

func update_health_bar() -> void:
	if not health_bar_fg:
		return

	var health_percentage = get_health_percentage()
	health_bar_fg.size.x = 16 * health_percentage

	# Change color based on health percentage
	if health_percentage > 0.6:
		health_bar_fg.color = Color.GREEN
	elif health_percentage > 0.3:
		health_bar_fg.color = Color.YELLOW
	else:
		health_bar_fg.color = Color.RED