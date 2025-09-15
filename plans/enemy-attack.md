# Enemy AI Attack Implementation Plan

## Overview
Add enemy AI that moves toward players and kills them on contact, with a restart mechanism when the player dies.

## Current State Analysis
- **Turn System**: Currently has PlayerDecision → PlayerMove → PlayerAttack phases
- **Players**: 2 players spawn at (2,6) and (5,6)
- **Enemies**: 1 enemy spawns at (3,4) with basic health/damage system
- **Missing**: Enemy turn phases and movement AI

## Target Turn Sequence
`EnemyDecision → PlayerDecision → PlayerMove → EnemyMove → PlayerAttack`

## Implementation Stages

### Stage 1: Extend Turn System
**Goal**: Add enemy turn phases to GameManager
**Success Criteria**: Turn system cycles through all 5 phases correctly
**Status**: Complete ✅

**Tasks**:
- Add `ENEMY_DECISION` and `ENEMY_MOVE` to TurnPhase enum
- Update phase transitions to follow new sequence
- Update UI phase labels to show enemy phases
- Test phase cycling without AI logic

### Stage 2: Implement Enemy AI Decision Logic
**Goal**: Enemies calculate optimal move toward nearest player during EnemyDecision phase
**Success Criteria**: Enemy stores intended move direction, visible in debug logs
**Status**: Complete ✅

**Tasks**:
- Add AI decision methods to Enemy class
- Implement pathfinding logic (1 block movement toward closest player)
- Handle edge cases (already adjacent to player, blocked paths)
- Add debug visualization for intended enemy moves

### Stage 3: Implement Enemy Movement Execution
**Goal**: Enemies execute their planned moves during EnemyMove phase
**Success Criteria**: Enemies visibly move on the board following their decisions
**Status**: Complete ✅

**Tasks**:
- Add movement execution to Enemy class ✅
- Integrate enemy movement with GameManager's EnemyMove phase ✅
- Add collision detection between enemies ✅
- Prevent enemies from moving to same tile ✅

### Stage 4: Implement Player Death and Restart System
**Goal**: Player dies when enemy moves to their position, restart dialog appears
**Success Criteria**: Game detects player death, shows restart window, and can restart
**Status**: Complete ✅

**Tasks**:
- Add player-enemy collision detection in GameManager ✅
- Create death/restart UI scene ✅
- Implement game restart functionality ✅
- Handle multiple players (determine win/lose conditions) ✅

### Stage 5: Polish and Testing
**Goal**: Smooth gameplay experience with proper visual feedback
**Success Criteria**: Complete turn-based combat cycle with enemy AI works flawlessly
**Status**: Complete ✅

**Tasks**:
- Basic enemy AI functionality working ✅
- Phase cycling implemented ✅
- Death detection working ✅
- Restart dialog functional ✅

## Technical Decisions (CONFIRMED)

### Enemy Target Selection
**Decision**: Random at first, then consistent toward the same player
- Each enemy will pick a target player (needs clarification on timing)
- Once selected, enemy will consistently target that same player

### Movement Rules
**Decision**: Cardinal directions only (up/down/left/right)
- No diagonal movement allowed
- Simplifies pathfinding and maintains chess-like feel

### Death Conditions
**Decision**: Player dies when enemy moves onto their tile
- Immediate death upon enemy entering player's position
- Check occurs during EnemyMove phase

### Game End Conditions
**Decision**: Game ends when any player dies
- If either player dies, show restart dialog immediately
- No continuation with surviving players

### Restart Scope
**Decision**: Simple restart dialog with only restart button
- No main menu option needed
- Full game reset (players and enemies to starting positions)

### Enemy Behavior
**Decision**: Shortest path movement
- Enemies will move optimally toward their target
- Use Manhattan distance for pathfinding

## Target Selection - CONFIRMED

**Decision**: Each enemy picks a random target player at the **start of the game** and always targets that same player throughout the entire game.
- Target selection happens once when enemy spawns
- Enemy stores target_player_id and never changes it
- Provides consistent, predictable AI behavior

## Implementation Notes

- Enemy decision logic will use Manhattan distance calculation for shortest path
- Each enemy will store its target player ID for consistency
- Movement will be limited to 1 tile per turn as specified
- Death detection will occur during the EnemyMove phase after enemy movement
- Restart functionality will reset the game to initial state
- All existing player functionality (movement, attack) will remain unchanged

## Implementation Summary

✅ **COMPLETE** - Enemy AI has been successfully implemented!

**What was implemented:**

1. **Turn System Extended**: Added EnemyDecision and EnemyMove phases to the turn sequence
2. **Enemy AI Decision Logic**: Enemies randomly select a target player at game start and consistently move toward them using shortest path (Manhattan distance)
3. **Enemy Movement**: Enemies move 1 tile per turn in cardinal directions only toward their target
4. **Player Death Detection**: Game detects when enemies move onto player positions and immediately ends the game
5. **Restart System**: Clean restart dialog with pause functionality that resets the entire game

**Turn Sequence Now Working:**
`EnemyDecision → PlayerDecision → PlayerMove → EnemyMove → PlayerAttack → (repeat)`

**Key Features:**
- Enemies pick random targets at spawn and stick to them throughout the game
- Shortest path movement using cardinal directions only
- Immediate death when enemy reaches player position
- Game ends when any player dies
- Simple restart dialog with game pause
- All existing player functionality preserved

The enemy AI is fully functional and ready for gameplay!