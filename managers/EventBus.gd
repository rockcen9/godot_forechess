extends Node

# EventBus: Global signals for decoupled communication between systems
# This singleton provides a central location for all cross-cutting global events
# Use sparingly - only for events that need to cross multiple system boundaries

# Game State Events
signal game_started()
signal game_over(reason: String)
signal game_paused()
signal game_resumed()
signal game_restarted()

# Turn System Events
signal turn_phase_changed(new_phase: GameManager.TurnPhase)
signal player_turn_started(player_id: int)
signal enemy_turn_started()
signal all_players_ready()

# Player Events
signal player_spawned(player: Player)
signal player_died(player: Player, cause: String)
signal player_moved(player: Player, from_pos: Vector2i, to_pos: Vector2i)
signal player_mode_changed(player: Player, new_mode: Player.PlayerMode)
signal player_confirmed_action(player: Player)
signal player_cancelled_action(player: Player)

# Enemy Events
signal enemy_spawned(enemy: Enemy)
signal enemy_died(enemy: Enemy)
signal enemy_moved(enemy: Enemy, from_pos: Vector2i, to_pos: Vector2i)
signal enemy_targeted_player(enemy: Enemy, target_player: Player)

# Combat Events
signal damage_applied(target: Node, damage: int, source: Node)
signal entity_health_changed(entity: Node, old_health: int, new_health: int)
signal attack_performed(attacker: Node, target: Node, damage: int)
signal attack_missed(attacker: Node, target_pos: Vector2i)

# Audio Events (for AudioManager to listen to)
signal play_sound_effect(sound_name: String, position: Vector2)
signal play_music(track_name: String, fade_in: bool)
signal stop_music(fade_out: bool)

# UI Events
signal ui_state_changed(new_state: String)
signal notification_requested(message: String, duration: float)

func _ready() -> void:
	print("EventBus initialized - ready for global event coordination")

# Helper functions for common event patterns

func notify_player_action(player: Player, action: String, data: Dictionary = {}) -> void:
	print("EventBus: Player ", player.player_id, " performed action: ", action)
	# Can be extended for more specific player action events

func notify_combat_event(attacker: Node, target: Node, event_type: String, data: Dictionary = {}) -> void:
	print("EventBus: Combat event - ", event_type, " from ", attacker.name, " to ", target.name)
	# Can be extended for detailed combat logging

func request_audio(sound_type: String, sound_name: String, position: Vector2) -> void:
	match sound_type:
		"effect":
			play_sound_effect.emit(sound_name, position)
		"music":
			play_music.emit(sound_name, false)
		_:
			print("EventBus Warning: Unknown audio type: ", sound_type)