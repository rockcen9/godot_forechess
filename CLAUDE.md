# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Godot 4.4 chess game project called "forechess" built with GDScript. The project uses the GL Compatibility rendering backend for broad device support. The architecture follows a composition-over-inheritance pattern with a manager-based design for coordinating different game systems.

## Development Commands

### Running the Project
- `godot` - Launch Godot editor and run the project
- The main scene is `res://main/main.tscn` which auto-loads when running the project

## Project Structure

### Core Architecture
```
forechess/
├── main/                   # Entry point and main scene
│   ├── Main.gd            # Manager initialization and dependency injection
│   └── main.tscn          # Root scene with manager nodes
├── managers/              # Core system managers (no inheritance)
│   ├── GameManager.gd     # Turn phases, game state orchestration
│   ├── InputManager.gd    # Player input handling and validation
│   ├── AIManager.gd       # AI decision making and behavior
│   ├── CombatManager.gd   # Combat resolution and damage calculation
│   ├── AudioManager.gd    # Sound effects and music management
│   └── EventBus.gd        # Global event system singleton
├── entities/              # Game objects with composition-based design
│   ├── Player.gd          # Player entities with component composition
│   ├── Enemy.gd           # Enemy entities with AI behavior
│   ├── board/             # Board tiles and grid management
│   └── pieces/            # Chess piece entities
├── components/            # Reusable behavior components
│   ├── HealthComponent.gd # Health tracking and damage handling
│   └── MovementComponent.gd # Movement validation and execution
├── resources/             # Data-only resource classes
│   ├── PlayerData.gd      # Player configuration and stats
│   ├── EnemyData.gd       # Enemy types and behavior data
│   ├── WeaponData.gd      # Weapon properties and effects
│   ├── ArmorData.gd       # Armor stats and modifiers
│   └── AbilityData.gd     # Special abilities and skills
├── scenes/                # Scene files for instantiation
├── ui/                    # User interface scenes and scripts
├── states/                # State machine implementations
└── assets/                # Game assets organized by type
```

### Assets Organization
Assets must be organized by type and purpose following this structure:

```
assets/
├── audio/
│   ├── effects/        # Gameplay sounds (piece moves, captures, game events)
│   ├── ui/            # Interface sounds (button clicks, menu navigation)
│   └── music/         # Background music and ambient tracks
├── textures/
│   ├── ui/            # User interface graphics
│   ├── board/         # Board backgrounds and tile graphics
│   ├── pieces/        # Chess piece sprites (player/enemy subdirs)
│   └── effects/       # Visual effects and particles
└── themes/            # UI themes and stylesheets
```

**Audio Classification Rules:**
- **effects/**: Gameplay mechanics (piece moves, captures, game events)
- **ui/**: Interface interactions (button clicks, menu sounds, dialog open/close)
- **music/**: Background tracks and ambient audio

**Texture Classification Rules:**
- **pieces/**: Organized by ownership (player/, enemy/) containing all piece sprites
- **board/**: Board backgrounds, tile variations, position indicators
- **ui/**: Menus, buttons, dialogs, HUD elements
- **effects/**: Particle textures, visual feedback graphics

## Architecture Principles

### No Inheritance Design
The project follows a **composition-over-inheritance** pattern:
- All managers extend `Node` directly (no custom base classes)
- Entities use component composition instead of inheritance hierarchies
- Shared functionality implemented through components, not parent classes
- Data separated into resource classes for reusability

### Manager Pattern
**Centralized Coordination**: Managers coordinate specific game systems without interdependencies:
- `GameManager` - Orchestrates turn phases and execution order
- `InputManager` - Handles player input validation and routing
- `AIManager` - Manages AI decision making and behavior
- `CombatManager` - Resolves combat interactions and damage
- `AudioManager` - Controls sound effects and music playback
- `EventBus` - Provides decoupled communication via global signals

**Dependency Injection**: The `Main.gd` script initializes all managers and injects dependencies:
- Managers receive references to other managers they need
- No global singletons except EventBus for cross-cutting concerns
- Clear dependency graph managed at initialization

### Component System
**Composition-Based Entities**: Game objects use components for behavior:
- `HealthComponent` - Health tracking, damage handling, death states
- `MovementComponent` - Movement validation, position tracking, pathfinding
- Components can be mixed and matched on different entity types
- Entities coordinate their components without inheriting behavior

### Data Resources
**Pure Data Classes**: Resource classes contain only data, no behavior:
- `PlayerData` - Player stats, abilities, equipment configurations
- `EnemyData` - Enemy types, AI behavior parameters, spawn data
- `WeaponData` - Weapon stats, damage types, special effects
- `ArmorData` - Defense values, damage reduction, special properties
- Resources can be shared across multiple entity instances

## Code Organization Standards

### Naming Conventions
- **Scene files**: PascalCase (e.g., `Main.tscn`, `BoardTile.tscn`)
- **Script files**: snake_case (e.g., `game_manager.gd`, `health_component.gd`)
- **Manager APIs**: Consistent method naming patterns across managers
- **Event naming**: Descriptive signal names with context (e.g., `player_moved`, `turn_phase_changed`)

### File Structure Rules
- One primary class per file
- Manager scripts in `/managers/` directory
- Component scripts in `/components/` directory
- Entity scripts in `/entities/` with appropriate subdirectories
- Resource scripts in `/resources/` directory
- Scene files co-located with their primary scripts when applicable

### Communication Patterns
- **Direct references**: For frequent, performance-critical communication
- **Signals**: For event-driven communication between loosely coupled systems
- **EventBus**: Only for cross-cutting global events that span multiple systems
- **Component interfaces**: Well-defined APIs for component interaction

## Manager Architecture Guidelines

### Core Principle: Avoid God Objects

* Use **composition only** — no inheritance, no interfaces.
* Managers must **stay small, focused, and modular**.
* Avoid creating a single **God Object** that knows or does everything.

### Manager Design Rules

#### 1. Single Responsibility
* Each Manager must handle **one major concern only**.
* Example:
  * `InputManager` → input collection
  * `CombatManager` → damage resolution
  * `AIManager` → AI scheduling / tools
  * `AudioManager` → sound / music

#### 2. Keep Managers Slim
* If a Manager grows beyond ~500 lines, split it into sub-services.
* Example:
  * Instead of a bloated `AIManager`:
    * `AIManager` (dispatcher)
    * `PathfindingService`
    * `DecisionService`

#### 3. Prefer Composition Over Switches
* Avoid giant `if/else` or `match` inside Managers.
* Use **controllers and behaviors**:
  * `AIController` holds an array of `AIBehavior` resources.
  * Example: `ChaseBehavior`, `PatrolBehavior`, `FleeBehavior`.
* Managers should **call controllers**, not encode all behaviors.

#### 4. Event-Driven Decoupling
* Use an **EventBus** (global signals) to broadcast results.
* Example:
  * `CombatManager` → `EventBus.emit("player_damaged", amount)`
  * `UIManager` subscribes and updates health bar.
* This keeps Managers from hard-coding dependencies.

#### 5. Data-Driven Logic
* Managers should read config from **Resources (.gd + .tres)**.
* Avoid writing type checks like `if enemy.type == "chaser"`.
* Example:
  * `EnemyData.tres` specifies behaviors: `[ChaseBehavior, PatrolBehavior]`.
  * AIController loads these and executes.

#### 6. Entities Stay Lightweight
* Entities (Player, Enemy, NPC) should:
  * Store state (`health`, `speed`).
  * Delegate control to a **Controller** (`InputController`, `AIController`, `NetworkController`).
  * Respond to Manager calls (`take_damage()`).

#### 7. Execution Order Controlled Centrally
* `GameManager` decides update order in `_physics_process`:
  ```
  InputManager → AIManager → Movement → CombatManager → Animation/FX
  ```
* Other Managers **must not** assume their own order; they are called centrally.

#### 8. Explicit APIs
* Each Manager must expose **clear public methods**.
* Example:
  * `CombatManager.deal_damage(attacker, target, amount)`
  * `AIManager.get_direction_for(entity, ai_type)`
* No hidden dependencies.

#### 9. Avoid Cross-Manager Coupling
* Managers must **not** directly call each other unless necessary.
* Prefer EventBus or GameManager coordination.
* Example:
  * `CombatManager` should not directly call `AudioManager`.
  * Instead: `EventBus.emit("attack_hit")`, AudioManager reacts.

#### 10. Testability
* Managers should be replaceable with dummy versions in tests.
* Example: `DummyCombatManager` that logs damage instead of applying it.
* This prevents single bugs from crashing the entire project.

### Anti-Patterns (Do Not Do)
* One giant `GameManager` that handles input, AI, combat, audio, UI all in one.
* Hard-coded type checks like `if enemy.type == "boss"`.
* Managers that directly update UI or play sounds (delegate via EventBus).
* Entity scripts that bypass Managers and handle their own logic.

### Example: Good vs Bad

**Bad (God Object AIManager):**
```gdscript
func update(delta):
    for enemy in enemies:
        if enemy.type == "chaser":
            chase_player(enemy)
        elif enemy.type == "ranger":
            shoot_arrow(enemy)
        elif enemy.type == "boss":
            boss_phase(enemy)
```

**Good (Composition with Behaviors):**
```gdscript
# AIManager.gd
func update(delta):
    for enemy in get_tree().get_nodes_in_group("enemy"):
        enemy.controller.update(enemy, delta)

# AIController.gd
@export var behaviors: Array[Resource]
func update(owner, delta):
    for b in behaviors:
        owner.velocity += b.get_direction(owner, delta)
```

### Summary
* Managers = global services, but must stay **focused**.
* Use **composition (controllers + behaviors)**, not inheritance.
* Drive logic with **Resources + EventBus**.
* Keep Entities thin, Managers modular, and GameManager as the orchestrator.

## Development Notes

- The project implements a turn-based chess variant with tactical combat elements
- Architecture designed for extensibility and clear separation of concerns
- No inheritance hierarchies - favor composition and dependency injection
- All managers are peers that coordinate through well-defined interfaces
- Focus on readable, maintainable code with clear responsibilities