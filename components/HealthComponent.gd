extends Node

# HealthComponent: Pure composition-based health management
# No inheritance or interfaces - just functionality composition

signal health_changed(old_health: int, new_health: int)
signal died()

var max_health: int = 100
var current_health: int = 100
var health_data: Resource # Can be any health-related resource

func _ready() -> void:
	print("HealthComponent initialized")

func setup(initial_health: int, health_resource: Resource = null) -> void:
	max_health = initial_health
	current_health = initial_health
	health_data = health_resource

func take_damage(damage: int) -> void:
	var old_health = current_health
	current_health -= damage
	current_health = max(0, current_health)

	health_changed.emit(old_health, current_health)

	if current_health <= 0:
		died.emit()

func heal(amount: int) -> void:
	var old_health = current_health
	current_health += amount
	current_health = min(max_health, current_health)

	health_changed.emit(old_health, current_health)

func get_health() -> int:
	return current_health

func get_max_health() -> int:
	return max_health

func get_health_percentage() -> float:
	return float(current_health) / float(max_health)

func is_alive() -> bool:
	return current_health > 0

func set_max_health(new_max: int) -> void:
	max_health = new_max
	current_health = min(current_health, max_health)

func reset_to_full() -> void:
	current_health = max_health