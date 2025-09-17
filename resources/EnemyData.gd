extends Resource

# EnemyData: Resource class for enemy configuration and AI behavior
# Used for: Enemy stats, AI settings, behavior patterns, and loot

@export var enemy_name: String = "Enemy"
@export var enemy_type: String = "basic"
@export var max_health: int = 100
@export var movement_speed: float = 1.0
@export var attack_damage: int = 25
@export var attack_range: float = 1.0

# Visual appearance
@export var enemy_color: Color = Color.RED
@export var enemy_texture: Texture2D
@export var enemy_scale: Vector2 = Vector2.ONE

# AI Behavior configuration
@export var ai_type: String = "aggressive"  # "aggressive", "defensive", "patrol", "random"
@export var detection_range: float = 6.0
@export var chase_range: float = 8.0
@export var preferred_distance: float = 1.0  # Distance AI tries to maintain from target

# AI Decision weights (0.0 to 1.0)
@export var aggression: float = 0.8  # Likelihood to attack vs. retreat
@export var persistence: float = 0.7  # How long to chase a target
@export var intelligence: float = 0.5  # Planning ahead vs. reactive
@export var cooperation: float = 0.3  # Working with other enemies

# Movement patterns
@export var movement_pattern: String = "direct"  # "direct", "flanking", "cautious", "erratic"
@export var can_move_diagonally: bool = false
@export var movement_frequency: float = 1.0  # Moves per turn (fraction for slower enemies)

# Special abilities
@export var special_abilities: Array[String] = []
@export var ability_cooldowns: Dictionary = {}

# Spawning configuration
@export var spawn_cost: int = 1
@export var spawn_weight: float = 1.0  # Relative probability of spawning this enemy type
@export var min_spawn_turn: int = 1
@export var max_simultaneous: int = 5

# Loot and rewards (for future use)
@export var experience_reward: int = 10
@export var possible_drops: Array[Resource] = []
@export var drop_chances: Array[float] = []

# Status effects resistance
@export var status_resistances: Dictionary = {
	"stun": 0.0,
	"slow": 0.0,
	"poison": 0.0,
	"confusion": 0.0
}

func get_ai_decision_weight(decision_type: String) -> float:
	match decision_type:
		"attack":
			return aggression
		"chase":
			return persistence
		"retreat":
			return 1.0 - aggression
		"flank":
			return intelligence
		"cooperate":
			return cooperation
		_:
			return 0.5

func should_use_ability(ability_name: String, context: Dictionary = {}) -> bool:
	if ability_name not in special_abilities:
		return false

	# Check cooldown
	if ability_name in ability_cooldowns:
		if ability_cooldowns[ability_name] > 0:
			return false

	# Context-specific ability usage logic
	match ability_name:
		"charge":
			return context.get("distance_to_target", 999) > 2
		"heal":
			return context.get("health_percentage", 1.0) < 0.3
		"summon":
			return context.get("ally_count", 0) < 2
		_:
			return randf() < intelligence

func get_preferred_target_distance() -> float:
	return preferred_distance

func get_movement_strategy(target_position: Vector2i, current_position: Vector2i) -> String:
	var distance = current_position.distance_to(target_position)

	match movement_pattern:
		"direct":
			return "move_toward"
		"flanking":
			return "flank_target" if distance > 2 else "move_toward"
		"cautious":
			return "maintain_distance" if distance < preferred_distance else "move_toward"
		"erratic":
			return ["move_toward", "move_random", "wait"].pick_random()
		_:
			return "move_toward"

func can_perform_action(action: String) -> bool:
	match action:
		"move":
			return true
		"attack":
			return attack_damage > 0
		"special_ability":
			return not special_abilities.is_empty()
		_:
			return false

func calculate_threat_level() -> float:
	# Calculate overall threat level for balancing
	var threat = 0.0
	threat += max_health * 0.01
	threat += attack_damage * 0.02
	threat += movement_speed * 10.0
	threat += aggression * 20.0
	threat += intelligence * 15.0
	threat += special_abilities.size() * 10.0
	return threat

func create_ai_state() -> Dictionary:
	return {
		"target_player_id": 0,
		"last_known_target_position": Vector2i.ZERO,
		"turns_since_target_seen": 0,
		"current_ability_cooldowns": ability_cooldowns.duplicate(),
		"behavior_state": "searching",  # "searching", "chasing", "attacking", "retreating"
		"movement_queue": [],
		"cooperation_targets": []
	}

func reset_cooldowns(ai_state: Dictionary) -> void:
	ai_state.current_ability_cooldowns.clear()

func update_cooldowns(ai_state: Dictionary) -> void:
	for ability in ai_state.current_ability_cooldowns:
		ai_state.current_ability_cooldowns[ability] = max(0, ai_state.current_ability_cooldowns[ability] - 1)