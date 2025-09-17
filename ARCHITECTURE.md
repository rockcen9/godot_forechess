# Manager/Service Architecture - Pure Composition Design

## Overview

This project has been successfully refactored into a **pure composition-based Manager/Service architecture** with no inheritance or interfaces. All functionality is achieved through composition, dependency injection, and event-driven communication.

## Architecture Principles

### ✅ Pure Composition
- **No class_name declarations** - All scripts use basic `extends Node` or `extends Resource`
- **No interfaces** - Duck typing with consistent method signatures
- **No inheritance hierarchies** - Functionality through composition only
- **Component-based design** - Small, focused, reusable components

### ✅ Manager/Service Pattern
- **Single responsibility** - Each manager handles one domain
- **Centralized logic** - Business logic in managers, not entities
- **Clear API boundaries** - Well-defined public interfaces
- **Dependency injection** - Managers injected at startup

### ✅ Event-Driven Communication
- **EventBus singleton** - Global signal coordination
- **Loose coupling** - Components don't directly reference each other
- **Reactive design** - Systems respond to events, not polling

## Folder Structure

```
forechess/
├── managers/           # Core business logic managers (autoloaded)
│   ├── EventBus.gd    # Global signal coordination
│   ├── GameManager.gd # Turn orchestration and game state
│   ├── InputManager.gd # Centralized input handling
│   ├── AIManager.gd   # Enemy decision-making and AI
│   ├── CombatManager.gd # Attack resolution and damage
│   └── AudioManager.gd # Sound effects and music
├── entities/          # Lightweight entity containers
│   ├── Player.gd      # Player state and visualization
│   ├── Enemy.gd       # Enemy state and visualization
│   └── board/         # Board management entities
├── components/        # Reusable behavior components
│   ├── HealthComponent.gd # Health management
│   └── MovementComponent.gd # Movement behavior
├── resources/         # Data-driven configuration
│   ├── PlayerData.gd  # Player configuration
│   ├── EnemyData.gd   # Enemy configuration
│   ├── WeaponData.gd  # Weapon properties
│   └── ArmorData.gd   # Armor properties
├── ui/               # User interface components
└── main/             # Entry point and initialization
```

## Manager Responsibilities

### EventBus
- **Purpose**: Global signal coordination
- **API**:
  - `player_spawned(player: Node)`
  - `enemy_died(enemy: Node)`
  - `damage_applied(target: Node, damage: int, source: Node)`
  - `turn_phase_changed(new_phase: int)`

### GameManager
- **Purpose**: Turn orchestration and game state
- **API**:
  - `start_game()`
  - `end_game(reason: String)`
  - `start_player_decision_phase()`
  - `start_enemy_move_phase()`
- **Execution Order**: Controls `InputManager → AIManager → Movement → CombatManager`

### InputManager
- **Purpose**: Centralized input handling
- **API**:
  - `update(delta: float)`
  - `enable_input()` / `disable_input()`
  - `block_player_input(player_id: int)`
  - `get_player_direction_vector(player_id: int) -> Vector2i`

### AIManager
- **Purpose**: Enemy decision-making and AI
- **API**:
  - `make_enemy_decisions(enemies: Array, players: Array)`
  - `execute_enemy_movements(enemies: Array) -> Array[Vector2i]`
  - `set_ai_difficulty(difficulty: String)`

### CombatManager
- **Purpose**: Attack resolution and damage
- **API**:
  - `perform_player_attacks(players: Array)`
  - `apply_damage(target: Node, damage: int, source: Node)`
  - `check_movement_collision(entity: Node, target_pos: Vector2i) -> bool`

### AudioManager
- **Purpose**: Sound effects and music
- **API**:
  - `play_sound_effect(sound_name: String, position: Vector2)`
  - `play_music(track_name: String, fade_in: bool)`
  - `set_master_volume(volume: float)`

## Entity Design

### Lightweight Entities
Entities are **state containers** that delegate all logic to managers:

```gdscript
# Player entity - no complex logic, just state and visualization
extends Node2D

var grid_x: int
var grid_y: int
var player_id: int
var player_data: Resource  # Configuration resource

func take_damage(damage: int) -> void:
    # Simple state update - complex logic in CombatManager
    if player_data:
        player_data.current_health -= damage
```

### Component Composition
Entities can compose functionality through components:

```gdscript
# Add health component
var health_component = preload("res://components/HealthComponent.gd").new()
health_component.setup(100)  # 100 max health
add_child(health_component)

# Add movement component
var movement_component = preload("res://components/MovementComponent.gd").new()
movement_component.setup(Vector2i(2, 6), 1.0, Rect2i(0, 0, 8, 8))
add_child(movement_component)
```

## Resource-Driven Configuration

### Data Classes
All configuration stored in resources, not hardcoded:

```gdscript
# PlayerData.gd
extends Resource
@export var max_health: int = 100
@export var attack_damage: int = 50
@export var weapon_data: Resource
@export var armor_data: Resource
```

### Usage Example
```gdscript
# Load player configuration
var player_config = load("res://resources/player_configs/warrior.tres")
player.setup(2, 6, 1, player_config)
```

## Communication Patterns

### Event-Driven Flow
```
User Input → InputManager → EventBus.player_confirmed_action →
GameManager.check_all_players_ready() → GameManager.start_player_move_phase() →
BoardManager.execute_player_movements() → EventBus.player_moved →
AudioManager.play_sound_effect("move")
```

### Manager Coordination
```
GameManager._physics_process():
  1. InputManager.update(delta)
  2. AIManager.update(delta)
  3. CombatManager.update(delta)
  4. AudioManager.update(delta)
```

## Combat Example

### Player Attack Flow
```
1. InputManager detects attack input
2. InputManager.player_confirmed.emit(player_id)
3. GameManager._on_player_confirmed(player_id)
4. GameManager.start_player_attack_phase()
5. CombatManager.perform_player_attacks(players)
6. CombatManager.execute_player_attack(player)
7. CombatManager.find_targets_on_line(start_pos, direction)
8. CombatManager.apply_damage(target, damage, player)
9. EventBus.damage_applied.emit(target, damage, player)
10. target.take_damage(damage) → EventBus.entity_health_changed.emit()
11. AudioManager plays attack sound effect
```

## Benefits Achieved

### ✅ Maintainability
- **Single responsibility** - Each manager handles one concern
- **Clear boundaries** - Well-defined APIs between systems
- **Easy debugging** - Logic centralized in predictable locations

### ✅ Testability
- **Isolated systems** - Managers can be tested independently
- **Dependency injection** - Easy to mock dependencies
- **Event verification** - Can test by checking emitted events

### ✅ Extensibility
- **Plugin architecture** - Add new managers without breaking existing code
- **Component system** - Mix and match behaviors on entities
- **Resource-driven** - Add new configurations without code changes

### ✅ Performance
- **Batch processing** - Managers operate on groups of entities
- **Controlled execution** - Predictable update order
- **Event-driven** - No unnecessary polling or checking

## Usage Examples

### Adding a New Enemy Type
```gdscript
# 1. Create enemy data resource
var goblin_data = preload("res://resources/EnemyData.gd").new()
goblin_data.enemy_name = "Goblin"
goblin_data.max_health = 50
goblin_data.ai_type = "aggressive"

# 2. Spawn enemy with data
var enemy = enemy_scene.instantiate()
enemy.setup(3, 4, 1, goblin_data)
add_child(enemy)

# 3. AIManager automatically handles the new enemy type
```

### Adding a New Manager
```gdscript
# 1. Create new manager script
extends Node
func update(delta: float) -> void:
    # Manager logic here

# 2. Add to autoload in project.godot
# 3. Reference in Main.gd initialization
# 4. No changes needed to existing systems
```

This architecture provides a solid foundation for complex game development while maintaining code clarity and extensibility through pure composition patterns.