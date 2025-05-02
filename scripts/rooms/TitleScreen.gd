extends CanvasLayer

@onready var fade_rect: ColorRect = $FadeRect
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var title_music = preload("res://assets/audio/music/repossessed-title-song.mp3")

var input_enabled := false
var transition_in_progress := false

func _ready():
	anim_player.play("fade_in")
	await anim_player.animation_finished
	input_enabled = true
	SoundManager.play_music(title_music)

func _unhandled_input(event):
	if not input_enabled or transition_in_progress:
		return

	if event is InputEventMouseButton or event.is_action_pressed("ui_accept"):
		start_game_transition()

func start_game_transition():
	transition_in_progress = true
	anim_player.play("fade_out")
	await anim_player.animation_finished
	get_tree().change_scene_to_file("res://scenes/rooms/MenuScreen.tscn")  # Replace with your actual level path
