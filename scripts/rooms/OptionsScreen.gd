extends Control

@onready var master_slider = $MainContainer/CenterContainer/SettingsList/MasterVolumeSetting/MasterSlider
@onready var music_slider = $MainContainer/CenterContainer/SettingsList/MusicVolumeSetting/MusicSlider
@onready var sfx_slider = $MainContainer/CenterContainer/SettingsList/SFXVolumeSetting/SFXSlider
@onready var voice_slider = $MainContainer/CenterContainer/SettingsList/VoiceVolumeSetting/VoiceSlider
@onready var back_button = $MainContainer/CenterContainer/SettingsList/BackButton

const SLIDER_STEP := 0.05

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
	back_button.pressed.connect(func():
		get_node("/root/Main").load_screen(preload("res://scenes/rooms/MenuScreen.tscn")))

	for control in [master_slider, music_slider, sfx_slider, voice_slider, back_button]:
		control.focus_mode = Control.FOCUS_ALL

	# Set initial focus to the Master volume slider
	master_slider.grab_focus()
	
	# Focus neighbor navigation, whatever that is
	master_slider.focus_neighbor_bottom = music_slider.get_path()
	music_slider.focus_neighbor_top = master_slider.get_path()
	music_slider.focus_neighbor_bottom = sfx_slider.get_path()
	sfx_slider.focus_neighbor_top = music_slider.get_path()
	sfx_slider.focus_neighbor_bottom = voice_slider.get_path()
	voice_slider.focus_neighbor_top = sfx_slider.get_path()
	voice_slider.focus_neighbor_bottom = back_button.get_path()
	back_button.focus_neighbor_top = voice_slider.get_path()


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

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		back_button.emit_signal("pressed")

	var focused := get_viewport().gui_get_focus_owner()
	if not focused:
		return

	if focused is HSlider:
		if event.is_action_pressed("ui_left"):
			focused.value = max(focused.min_value, focused.value - SLIDER_STEP)
		elif event.is_action_pressed("ui_right"):
			focused.value = min(focused.max_value, focused.value + SLIDER_STEP)
