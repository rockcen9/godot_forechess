extends Resource

# ArmorData: Resource class for armor and defensive equipment
# Used for: Defense stats, damage reduction, special protection effects

@export var armor_name: String = "Basic Armor"
@export var armor_type: String = "light"  # "light", "medium", "heavy", "special"
@export var health_bonus: int = 0
@export var damage_reduction: int = 0  # Flat damage reduction
@export var damage_resistance: float = 0.0  # Percentage damage reduction (0.0 to 1.0)

# Special protections
@export var status_immunities: Array[String] = []  # Complete immunity to certain effects
@export var status_resistances: Dictionary = {}  # Reduced duration/chance of effects

# Movement effects
@export var movement_penalty: float = 0.0  # Reduction in movement speed
@export var stealth_penalty: float = 0.0  # Reduction in stealth capability

# Visual appearance
@export var armor_texture: Texture2D
@export var armor_color: Color = Color.WHITE

# Durability and maintenance
@export var max_durability: int = 100
@export var current_durability: int = 100
@export var repair_cost: int = 10

func get_effective_health_bonus() -> int:
	# Reduce bonus based on durability
	var durability_factor = float(current_durability) / float(max_durability)
	return int(health_bonus * durability_factor)

func get_effective_damage_reduction() -> int:
	var durability_factor = float(current_durability) / float(max_durability)
	return int(damage_reduction * durability_factor)

func get_effective_resistance() -> float:
	var durability_factor = float(current_durability) / float(max_durability)
	return damage_resistance * durability_factor

func calculate_damage_after_armor(incoming_damage: int) -> int:
	var reduced_damage = incoming_damage

	# Apply flat reduction first
	reduced_damage -= get_effective_damage_reduction()

	# Apply percentage reduction
	reduced_damage = int(reduced_damage * (1.0 - get_effective_resistance()))

	# Minimum damage of 1 (unless incoming was 0)
	if incoming_damage > 0:
		reduced_damage = max(1, reduced_damage)

	return reduced_damage

func is_immune_to_status(status_effect: String) -> bool:
	return status_effect in status_immunities

func get_status_resistance(status_effect: String) -> float:
	return status_resistances.get(status_effect, 0.0)

func take_durability_damage(damage: int) -> void:
	current_durability -= damage
	current_durability = max(0, current_durability)

func repair(amount: int) -> void:
	current_durability += amount
	current_durability = min(max_durability, current_durability)

func is_broken() -> bool:
	return current_durability <= 0

func get_armor_stats() -> Dictionary:
	return {
		"name": armor_name,
		"type": armor_type,
		"health_bonus": get_effective_health_bonus(),
		"damage_reduction": get_effective_damage_reduction(),
		"damage_resistance": get_effective_resistance(),
		"durability": str(current_durability) + "/" + str(max_durability)
	}