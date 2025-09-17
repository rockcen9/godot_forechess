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

## Development Notes

- The project implements a turn-based chess variant with tactical combat elements
- Architecture designed for extensibility and clear separation of concerns
- No inheritance hierarchies - favor composition and dependency injection
- All managers are peers that coordinate through well-defined interfaces
- Focus on readable, maintainable code with clear responsibilities