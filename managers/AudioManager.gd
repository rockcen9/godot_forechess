extends Node

# AudioManager: Centralized audio system for music and sound effects
# Responsible for: Playing sounds, managing audio levels, audio state management
# API: play_sound(), play_music(), stop_all(), set_volume()

# Audio players
var music_player: AudioStreamPlayer
var effect_players: Array[AudioStreamPlayer] = []
var max_effect_players: int = 8

# Audio state
var master_volume: float = 1.0
var music_volume: float = 0.7
var effects_volume: float = 0.8
var music_enabled: bool = true
var effects_enabled: bool = true

# Current audio state
var current_music_track: String = ""
var current_music_player: AudioStreamPlayer

func _ready() -> void:
	print("AudioManager initialized")

	# Create music player
	music_player = AudioStreamPlayer.new()
	music_player.name = "MusicPlayer"
	add_child(music_player)

	# Create pool of effect players
	for i in max_effect_players:
		var effect_player = AudioStreamPlayer.new()
		effect_player.name = "EffectPlayer" + str(i)
		add_child(effect_player)
		effect_players.append(effect_player)

	# Connect to EventBus audio events
	EventBus.play_sound_effect.connect(_on_play_sound_effect)
	EventBus.play_music.connect(_on_play_music)
	EventBus.stop_music.connect(_on_stop_music)

# Manager API - called by GameManager during update loop
func update(delta: float) -> void:
	# Handle any time-based audio logic
	pass

# Sound effect functions
func play_sound_effect(sound_name: String, position: Vector2 = Vector2.ZERO) -> void:
	if not effects_enabled:
		return

	var sound_path = get_sound_effect_path(sound_name)
	var audio_stream = load_audio_resource(sound_path)

	if not audio_stream:
		print("AudioManager: Sound effect not found - ", sound_name)
		return

	var player = get_available_effect_player()
	if not player:
		print("AudioManager: No available effect players for - ", sound_name)
		return

	player.stream = audio_stream
	player.volume_db = linear_to_db(effects_volume * master_volume)
	player.play()

	print("AudioManager: Playing sound effect - ", sound_name)

func get_sound_effect_path(sound_name: String) -> String:
	# Map sound names to file paths based on asset organization
	var sound_paths = {
		"player_attack": "res://assets/audio/effects/player_attack.ogg",
		"enemy_move": "res://assets/audio/effects/enemy_move.ogg",
		"player_move": "res://assets/audio/effects/player_move.ogg",
		"game_over": "res://assets/audio/effects/game_over.ogg",
		"button_click": "res://assets/audio/ui/button_click.ogg",
		"confirm": "res://assets/audio/ui/confirm.ogg",
		"cancel": "res://assets/audio/ui/cancel.ogg",
		"mode_switch": "res://assets/audio/ui/mode_switch.ogg"
	}

	return sound_paths.get(sound_name, "")

func get_available_effect_player() -> AudioStreamPlayer:
	# Find an available (not playing) effect player
	for player in effect_players:
		if not player.playing:
			return player

	# If all players are busy, use the first one (interrupts current sound)
	return effect_players[0] if effect_players.size() > 0 else null

# Music functions
func play_music(track_name: String, fade_in: bool = false) -> void:
	if not music_enabled:
		return

	if current_music_track == track_name and music_player.playing:
		print("AudioManager: Music track already playing - ", track_name)
		return

	var music_path = get_music_track_path(track_name)
	var audio_stream = load_audio_resource(music_path)

	if not audio_stream:
		print("AudioManager: Music track not found - ", track_name)
		return

	# Stop current music
	if music_player.playing:
		music_player.stop()

	music_player.stream = audio_stream
	music_player.volume_db = linear_to_db(music_volume * master_volume)
	music_player.play()

	current_music_track = track_name
	print("AudioManager: Playing music track - ", track_name)

	if fade_in:
		# Implement fade in logic
		fade_in_music()

func get_music_track_path(track_name: String) -> String:
	# Map music names to file paths
	var music_paths = {
		"menu_theme": "res://assets/audio/music/menu_theme.ogg",
		"game_theme": "res://assets/audio/music/game_theme.ogg",
		"victory_theme": "res://assets/audio/music/victory_theme.ogg",
		"ambient": "res://assets/audio/music/ambient.ogg"
	}

	return music_paths.get(track_name, "")

func stop_music(fade_out: bool = false) -> void:
	if not music_player.playing:
		return

	if fade_out:
		fade_out_music()
	else:
		music_player.stop()
		current_music_track = ""
		print("AudioManager: Music stopped")

func fade_in_music(duration: float = 2.0) -> void:
	var tween = create_tween()
	music_player.volume_db = linear_to_db(0.01)  # Start very quiet
	tween.tween_method(set_music_volume_tween, 0.01, music_volume * master_volume, duration)

func fade_out_music(duration: float = 2.0) -> void:
	var tween = create_tween()
	var current_volume = db_to_linear(music_player.volume_db)
	tween.tween_method(set_music_volume_tween, current_volume, 0.01, duration)
	tween.tween_callback(music_player.stop)
	tween.tween_callback(func(): current_music_track = "")

func set_music_volume_tween(volume: float) -> void:
	music_player.volume_db = linear_to_db(volume)

# Audio resource loading
func load_audio_resource(path: String) -> AudioStream:
	if path.is_empty():
		return null

	if not ResourceLoader.exists(path):
		print("AudioManager: Audio file does not exist - ", path)
		return null

	var resource = load(path)
	if resource is AudioStream:
		return resource
	else:
		print("AudioManager: Invalid audio resource - ", path)
		return null

# Volume and settings management
func set_master_volume(volume: float) -> void:
	master_volume = clamp(volume, 0.0, 1.0)
	update_all_volumes()
	print("AudioManager: Master volume set to ", master_volume)

func set_music_volume(volume: float) -> void:
	music_volume = clamp(volume, 0.0, 1.0)
	update_music_volume()
	print("AudioManager: Music volume set to ", music_volume)

func set_effects_volume(volume: float) -> void:
	effects_volume = clamp(volume, 0.0, 1.0)
	print("AudioManager: Effects volume set to ", effects_volume)

func update_all_volumes() -> void:
	update_music_volume()
	# Effect volumes are updated when they're played

func update_music_volume() -> void:
	if music_player:
		music_player.volume_db = linear_to_db(music_volume * master_volume)

func toggle_music() -> void:
	music_enabled = not music_enabled
	if not music_enabled and music_player.playing:
		music_player.stop()
	print("AudioManager: Music ", "enabled" if music_enabled else "disabled")

func toggle_effects() -> void:
	effects_enabled = not effects_enabled
	if not effects_enabled:
		stop_all_effects()
	print("AudioManager: Effects ", "enabled" if effects_enabled else "disabled")

func stop_all_effects() -> void:
	for player in effect_players:
		if player.playing:
			player.stop()

func stop_all_audio() -> void:
	stop_music()
	stop_all_effects()
	print("AudioManager: All audio stopped")

# Event handlers
func _on_play_sound_effect(sound_name: String, position: Vector2 = Vector2.ZERO) -> void:
	play_sound_effect(sound_name, position)

func _on_play_music(track_name: String, fade_in: bool = false) -> void:
	play_music(track_name, fade_in)

func _on_stop_music(fade_out: bool = false) -> void:
	stop_music(fade_out)

# Utility functions
func is_music_playing() -> bool:
	return music_player.playing

func get_current_music_track() -> String:
	return current_music_track

func get_audio_statistics() -> Dictionary:
	return {
		"music_playing": is_music_playing(),
		"current_track": current_music_track,
		"active_effects": effect_players.filter(func(p): return p.playing).size(),
		"master_volume": master_volume,
		"music_volume": music_volume,
		"effects_volume": effects_volume
	}
