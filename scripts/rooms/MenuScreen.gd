extends Control

@onready var new_game_button = $MainContainer/CenterContainer/MenuButtons/NewGameButton
@onready var options_button = $MainContainer/CenterContainer/MenuButtons/OptionsButton
@onready var back_to_title_button = $MainContainer/CenterContainer/MenuButtons/BackToTitleButton
@onready var quit_button = $MainContainer/CenterContainer/MenuButtons/QuitButton
@onready var quit_confirm = $QuitConfirm

func _ready():
	new_game_button.pressed.connect(_on_new_game_pressed)
	options_button.pressed.connect(_on_options_pressed)
	back_to_title_button.pressed.connect(_on_back_to_title_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	quit_confirm.confirmed.connect(_on_quit_confirmed)

func _on_new_game_pressed():
	get_tree().change_scene_to_file("res://scenes/rooms/Main.tscn")

func _on_options_pressed():
	get_tree().change_scene_to_file("res://scenes/rooms/OptionsScreen.tscn")

func _on_back_to_title_pressed():
	get_tree().change_scene_to_file("res://scenes/rooms/TitleScreen.tscn")

func _on_quit_pressed():
	quit_confirm.popup_centered()

func _on_quit_confirmed():
	get_tree().quit()

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		_on_back_to_title_pressed()
