extends Node

func _ready():
	AudioSettingsManager.load_settings()
	apply_all_volumes()

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
