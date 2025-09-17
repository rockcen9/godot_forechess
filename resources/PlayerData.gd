extends Resource

# PlayerData: Resource class for player configuration and stats
# Used for: Player attributes, equipment, abilities, and progression

@export var player_name: String = "Player"
@export var player_id: int = 1
@export var max_health: int = 100
@export var current_health: int = 100
@export var movement_speed: float = 1.0
@export var attack_damage: int = 50
@export var attack_range: float = 8.0

# Player appearance
@export var player_color: Color = Color.BLUE
@export var player_texture: Texture2D
@export var player_icon: Texture2D

# Player abilities and restrictions
@export var can_move: bool = true
@export var can_attack: bool = true
@export var can_switch_modes: bool = true
@export var requires_confirmation: bool = true

# Equipment and modifiers
@export var weapon_data: Resource
@export var armor_data: Resource
@export var special_abilities: Array[Resource] = []

# UI and input configuration
@export var keyboard_controls: Dictionary = {
	"up": KEY_W,
	"down": KEY_S,
	"left": KEY_A,
	"right": KEY_D,
	"confirm": KEY_SPACE,
	"cancel": KEY_ESCAPE,
	"mode_switch": KEY_Q
}

@export var controller_device_id: int = 0
@export var controller_enabled: bool = true

# Statistical tracking
@export var games_played: int = 0
@export var games_won: int = 0
@export var total_damage_dealt: int = 0
@export var total_moves_made: int = 0
@export var total_enemies_defeated: int = 0

func get_effective_damage() -> int:
	var base_damage = attack_damage
	if weapon_data:
		base_damage += weapon_data.damage_bonus
	return base_damage

func get_effective_health() -> int:
	var base_health = max_health
	if armor_data:
		base_health += armor_data.health_bonus
	return base_health

func get_effective_range() -> float:
	var base_range = attack_range
	if weapon_data:
		base_range += weapon_data.range_bonus
	return base_range

func can_perform_action(action: String) -> bool:
	match action:
		"move":
			return can_move
		"attack":
			return can_attack
		"mode_switch":
			return can_switch_modes
		_:
			return false

func update_statistics(stat_type: String, value: int = 1) -> void:
	match stat_type:
		"games_played":
			games_played += value
		"games_won":
			games_won += value
		"damage_dealt":
			total_damage_dealt += value
		"moves_made":
			total_moves_made += value
		"enemies_defeated":
			total_enemies_defeated += value

func get_win_rate() -> float:
	if games_played == 0:
		return 0.0
	return float(games_won) / float(games_played)

func reset_to_defaults() -> void:
	current_health = max_health
	# Don't reset statistics or permanent upgrades