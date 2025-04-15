extends CanvasLayer

@onready var fade_rect: ColorRect = $FadeRect
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var audio: AudioStreamPlayer = $AudioStreamPlayer

var input_enabled := false
var transition_in_progress := false

func _ready():
	anim_player.play("fade_in")
	await anim_player.animation_finished
	input_enabled = true
	play_title_music()

func _unhandled_input(event):
	if not input_enabled or transition_in_progress:
		return

	if event is InputEventMouseButton or event.is_action_pressed("ui_accept"):
		start_game_transition()

func play_title_music():
	# 🔈 TODO: Replace with actual title music file
	print("Stub: playing title music")
	# audio.stream = preload("res://audio/title_theme.ogg")
	# audio.play()

func start_game_transition():
	transition_in_progress = true
	anim_player.play("fade_out")
	await anim_player.animation_finished
	get_tree().change_scene_to_file("res://scenes/Main.tscn")  # Replace with your actual level path
