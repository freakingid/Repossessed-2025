extends Control

@onready var master_slider = $MainContainer/CenterContainer/SettingsList/MasterVolumeSetting/MasterSlider
@onready var music_slider = $MainContainer/CenterContainer/SettingsList/MusicVolumeSetting/MusicSlider
@onready var sfx_slider = $MainContainer/CenterContainer/SettingsList/SFXVolumeSetting/SFXSlider
@onready var voice_slider = $MainContainer/CenterContainer/SettingsList/VoiceVolumeSetting/VoiceSlider
@onready var back_button = $MainContainer/CenterContainer/SettingsList/BackButton

func _ready():
	# Set sliders to saved values
	master_slider.value = AudioSettingsManager.master_volume
	music_slider.value = AudioSettingsManager.music_volume
	sfx_slider.value = AudioSettingsManager.sfx_volume
	voice_slider.value = AudioSettingsManager.voice_volume

	# Connect slider signals
	master_slider.value_changed.connect(_on_master_changed)
	music_slider.value_changed.connect(_on_music_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)
	voice_slider.value_changed.connect(_on_voice_changed)
	back_button.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/ui/MenuScreen.tscn"))

func _on_master_changed(value):
	AudioSettingsManager.master_volume = value
	AudioSettingsManager.save_settings()
	SoundManager.set_master_volume(value)

func _on_music_changed(value):
	AudioSettingsManager.music_volume = value
	AudioSettingsManager.save_settings()
	SoundManager.set_music_volume(value)

func _on_sfx_changed(value):
	AudioSettingsManager.sfx_volume = value
	AudioSettingsManager.save_settings()
	SoundManager.set_sfx_volume(value)

func _on_voice_changed(value):
	AudioSettingsManager.voice_volume = value
	AudioSettingsManager.save_settings()
	SoundManager.set_voice_volume(value)
