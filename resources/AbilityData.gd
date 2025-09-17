extends Resource

# AbilityData: Resource class for special abilities and skills
# Used for: Active abilities, passive skills, temporary effects

@export var ability_name: String = "Basic Ability"
@export var ability_type: String = "active"  # "active", "passive", "triggered"
@export var description: String = "A basic ability."

# Activation requirements
@export var cooldown_turns: int = 0
@export var energy_cost: int = 0
@export var health_cost: int = 0
@export var range: float = 0.0
@export var requires_target: bool = false
@export var requires_line_of_sight: bool = false

# Effects
@export var damage: int = 0
@export var healing: int = 0
@export var status_effects: Array[String] = []
@export var effect_durations: Array[int] = []

# Area of effect
@export var aoe_type: String = "none"  # "none", "circle", "line", "cone"
@export var aoe_size: float = 0.0

# Visual and audio
@export var ability_icon: Texture2D
@export var cast_animation: String = ""
@export var effect_animation: String = ""
@export var cast_sound: String = ""
@export var effect_sound: String = ""

# Passive ability modifiers
@export var stat_modifiers: Dictionary = {}  # "health": 10, "damage": 5, etc.
@export var permanent_effects: Array[String] = []

func can_be_used(user_health: int, user_energy: int, current_cooldown: int) -> bool:
	if current_cooldown > 0:
		return false
	if user_health <= health_cost:
		return false
	if user_energy < energy_cost:
		return false
	return true

func get_stat_modifier(stat_name: String) -> int:
	return stat_modifiers.get(stat_name, 0)

func has_stat_modifier(stat_name: String) -> bool:
	return stat_name in stat_modifiers

func get_ability_info() -> Dictionary:
	return {
		"name": ability_name,
		"type": ability_type,
		"cooldown": cooldown_turns,
		"cost": energy_cost,
		"range": range,
		"damage": damage,
		"healing": healing,
		"aoe": aoe_type != "none"
	}