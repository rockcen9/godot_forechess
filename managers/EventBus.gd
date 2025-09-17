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
signal turn_phase_changed(new_phase: int)
signal player_turn_started(player_id: int)
signal enemy_turn_started()
signal all_players_ready()

# Player Events
signal player_spawned(player: Node)
signal player_died(player: Node, cause: String)
signal player_moved(player: Node, from_pos: Vector2i, to_pos: Vector2i)
signal player_mode_changed(player: Node, new_mode: int)
signal player_confirmed_action(player: Node)
signal player_cancelled_action(player: Node)

# Enemy Events
signal enemy_spawned(enemy: Node)
signal enemy_died(enemy: Node)
signal enemy_moved(enemy: Node, from_pos: Vector2i, to_pos: Vector2i)
signal enemy_targeted_player(enemy: Node, target_player: Node)

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

func notify_player_action(player: Node, action: String, data: Dictionary = {}) -> void:
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
