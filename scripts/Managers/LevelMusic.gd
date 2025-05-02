extends Node

@export var music_stream: AudioStream

func _ready():
	if music_stream:
		SoundManager.play_music(music_stream)
