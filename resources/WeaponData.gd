extends Resource

# WeaponData: Resource class for weapon configurations
# Used for: Weapon stats, behavior, effects, and visual properties

@export var weapon_name: String = "Basic Weapon"
@export var weapon_type: String = "projectile"  # "projectile", "melee", "area", "beam"
@export var damage_bonus: int = 0
@export var range_bonus: float = 0.0
@export var fire_rate: float = 1.0  # Attacks per turn
@export var accuracy: float = 1.0  # 0.0 to 1.0

# Visual and audio
@export var weapon_texture: Texture2D
@export var projectile_texture: Texture2D
@export var muzzle_flash_texture: Texture2D
@export var firing_sound: String = "basic_shot"
@export var impact_sound: String = "basic_impact"

# Weapon behavior
@export var projectile_speed: float = 10.0
@export var projectile_piercing: bool = false
@export var projectile_count: int = 1  # For shotgun-like weapons
@export var spread_angle: float = 0.0  # Degrees of spread
@export var recoil: float = 0.0

# Special effects
@export var status_effects: Array[String] = []  # "burn", "slow", "stun", etc.
@export var effect_durations: Array[int] = []
@export var effect_chances: Array[float] = []

# Area of effect (for area weapons)
@export var aoe_radius: float = 0.0
@export var aoe_falloff: bool = true

# Ammunition and resources
@export var ammo_per_shot: int = 1
@export var max_ammo: int = -1  # -1 for unlimited
@export var reload_time: int = 0  # Turns needed to reload

# Upgrade paths
@export var upgrade_cost: int = 100
@export var max_upgrade_level: int = 5
@export var upgrade_bonuses: Dictionary = {
	"damage": 5,
	"range": 1.0,
	"accuracy": 0.1,
	"fire_rate": 0.1
}

func get_effective_damage(base_damage: int) -> int:
	return base_damage + damage_bonus

func get_effective_range(base_range: float) -> float:
	return base_range + range_bonus

func can_fire(current_ammo: int = -1) -> bool:
	if max_ammo == -1:  # Unlimited ammo
		return true
	return current_ammo >= ammo_per_shot

func calculate_hit_chance(distance: float, target_size: float = 1.0) -> float:
	var base_chance = accuracy

	# Distance falloff
	if range_bonus > 0:
		var max_effective_range = range_bonus * 1.5
		if distance > max_effective_range:
			base_chance *= 0.5

	# Target size modifier
	base_chance *= target_size

	return clamp(base_chance, 0.0, 1.0)

func get_projectile_spread() -> Array[float]:
	var angles = []

	if projectile_count == 1:
		angles.append(0.0)
	else:
		var angle_step = spread_angle / (projectile_count - 1)
		var start_angle = -spread_angle * 0.5

		for i in projectile_count:
			angles.append(start_angle + angle_step * i)

	return angles

func apply_status_effects(target: Node) -> void:
	for i in status_effects.size():
		if i >= effect_chances.size():
			continue

		if randf() <= effect_chances[i]:
			var effect_name = status_effects[i]
			var duration = effect_durations[i] if i < effect_durations.size() else 1

			# Apply effect through EventBus or directly to target
			if target.has_method("apply_status_effect"):
				target.apply_status_effect(effect_name, duration)

func get_weapon_stats() -> Dictionary:
	return {
		"name": weapon_name,
		"type": weapon_type,
		"damage_bonus": damage_bonus,
		"range_bonus": range_bonus,
		"fire_rate": fire_rate,
		"accuracy": accuracy,
		"projectile_count": projectile_count,
		"aoe_radius": aoe_radius,
		"status_effects": status_effects.size()
	}

func create_projectile_data(start_pos: Vector2, target_pos: Vector2, angle_offset: float = 0.0) -> Dictionary:
	var direction = (target_pos - start_pos).normalized()
	if angle_offset != 0.0:
		direction = direction.rotated(deg_to_rad(angle_offset))

	return {
		"position": start_pos,
		"direction": direction,
		"speed": projectile_speed,
		"damage": damage_bonus,
		"range": range_bonus,
		"piercing": projectile_piercing,
		"texture": projectile_texture,
		"weapon_data": self
	}

func can_upgrade() -> bool:
	return max_upgrade_level > 0

func get_upgrade_preview(current_level: int) -> Dictionary:
	if current_level >= max_upgrade_level:
		return {}

	var preview = {}
	for stat in upgrade_bonuses:
		var bonus = upgrade_bonuses[stat]
		match stat:
			"damage":
				preview["damage_bonus"] = damage_bonus + bonus
			"range":
				preview["range_bonus"] = range_bonus + bonus
			"accuracy":
				preview["accuracy"] = min(1.0, accuracy + bonus)
			"fire_rate":
				preview["fire_rate"] = fire_rate + bonus

	return preview