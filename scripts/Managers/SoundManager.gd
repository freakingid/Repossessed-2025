extends Node

const MAX_SFX_PLAYERS := 20

var sfx_players: Array[AudioStreamPlayer2D] = []
var music_player: AudioStreamPlayer = null

func _ready():
	AudioSettingsManager.load_settings()
	apply_all_volumes()
	_init_players()

func apply_all_volumes():
	set_master_volume(AudioSettingsManager.master_volume)
	set_music_volume(AudioSettingsManager.music_volume)
	set_sfx_volume(AudioSettingsManager.sfx_volume)
	set_voice_volume(AudioSettingsManager.voice_volume)

func set_master_volume(percent: float):
	var db = linear_to_db(percent / 100.0)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), db)

func set_music_volume(percent: float):
	var combined = percent * AudioSettingsManager.master_volume / 10000.0
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(combined))

func set_sfx_volume(percent: float):
	var combined = percent * AudioSettingsManager.master_volume / 10000.0
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(combined))

func set_voice_volume(percent: float):
	var combined = percent * AudioSettingsManager.master_volume / 10000.0
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Voice"), linear_to_db(combined))

func _init_players():
	# Music player (non-positional)
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Music"
	add_child(music_player)

	# SFX pool (positional)
	for i in MAX_SFX_PLAYERS:
		var player := AudioStreamPlayer2D.new()
		player.bus = "SFX"
		add_child(player)
		sfx_players.append(player)

func play_music(stream: AudioStream, loop := true):
	if music_player.playing:
		music_player.stop()
	music_player.stream = stream
	music_player.volume_db = 0  # You control loudness via AudioSettingsManager
	if stream is AudioStream:
		stream.loop = loop
	music_player.play()

func stop_music():
	if music_player.playing:
		music_player.stop()

func play_sfx(stream: AudioStream, position: Vector2, random_pitch := true):
	var player := _get_available_sfx_player()
	if player:
		player.stop()
		player.stream = stream
		player.global_position = position
		player.volume_db = 0  # Again, bus controls overall loudness
		player.pitch_scale = randf_range(0.95, 1.05) if random_pitch else 1.0
		player.play()

func _get_available_sfx_player() -> AudioStreamPlayer2D:
	for player in sfx_players:
		if not player.playing:
			return player
	return null

func is_music_playing() -> bool:
	return music_player != null and music_player.playing
