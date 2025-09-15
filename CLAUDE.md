# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Godot 4.4 chess game project called "forechess" built with GDScript. The project uses the GL Compatibility rendering backend for broad device support.

## Development Commands

### Running the Project
- `godot` - Launch Godot editor and run the project
- The main scene is `res://Main.tscn` which auto-loads when running the project

### Project Structure
- `project.godot` - Godot project configuration file
- `main.tscn` - Root scene containing the main game structure
- `scenes/board/` - Board-related scenes and scripts
  - `BoardManager.tscn/.gd` - Manages the 8x8 chess board
  - `BoardTile.tscn/.gd` - Individual board tile component

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
- **effects/**: Gameplay mechanics (fast_drop.wav, move_piece.wav, game_over.wav, line_clear.wav)
- **ui/**: Interface interactions (button clicks, menu sounds, dialog open/close)
- **music/**: Background tracks and ambient audio

**Texture Classification Rules:**
- **pieces/**: Organized by ownership (player/, enemy/) containing all piece sprites
- **board/**: Board backgrounds, tile variations, position indicators
- **ui/**: Menus, buttons, dialogs, HUD elements
- **effects/**: Particle textures, visual feedback graphics

## Architecture

### Scene Hierarchy
The main scene (`Main.tscn`) contains three primary managers:
- `BoardManager` - Handles board creation and tile positioning
- `GameManager` - (Currently empty, intended for game logic)
- `InputManager` - (Currently empty, intended for input handling)

### Board System
- Board is 8x8 grid (defined by `BOARD_SIZE` constant in `board_manager.gd`)
- Each tile is 64x64 pixels
- Board is automatically centered on screen
- Tiles alternate between light (white) and dark (gray) colors
- Uses scene instancing pattern: `BoardManager` instantiates `BoardTile` scenes

### Code Organization
- Scripts use standard Godot naming: scene files are PascalCase, script files are snake_case
- Board coordinates use (x, y) grid system starting from (0, 0)
- Visual representation handled through `_draw()` method in `BoardTile`

### Key Classes
- `BoardTile` - Custom class with grid position tracking and visual rendering
- Grid positions stored as `grid_x`, `grid_y` integers
- Tile appearance determined by `is_light` boolean flag

## Development Notes

- The project is currently in early development with basic board rendering
- No piece logic or game mechanics implemented yet
- Uses Godot's scene instancing pattern for scalable component architecture
- Designed for 2D chess gameplay with potential for future enhancements