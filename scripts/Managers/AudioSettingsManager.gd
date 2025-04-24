extends Node

const CONFIG_PATH := "user://audio_settings.cfg"

var master_volume := 100
var music_volume := 100
var sfx_volume := 100
var voice_volume := 100

func load_settings():
	var config = ConfigFile.new()
	var err = config.load(CONFIG_PATH)
	if err != OK:
		print("No saved settings found, using defaults")
		return

	master_volume = config.get_value("audio", "master_volume", 100)
	music_volume = config.get_value("audio", "music_volume", 100)
	sfx_volume = config.get_value("audio", "sfx_volume", 100)
	voice_volume = config.get_value("audio", "voice_volume", 100)

func save_settings():
	var config = ConfigFile.new()
	config.set_value("audio", "master_volume", master_volume)
	config.set_value("audio", "music_volume", music_volume)
	config.set_value("audio", "sfx_volume", sfx_volume)
	config.set_value("audio", "voice_volume", voice_volume)
	config.save(CONFIG_PATH)
