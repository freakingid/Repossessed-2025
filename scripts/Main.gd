# Main.gd
extends Node

@export var title_screen_scene: PackedScene = preload("res://scenes/rooms/TitleScreen.tscn")
@export var menu_screen_scene: PackedScene = preload("res://scenes/rooms/MenuScreen.tscn")
@export var options_screen_scene: PackedScene = preload("res://scenes/rooms/OptionsScreen.tscn")

func _ready():
	load_screen(title_screen_scene)

func load_screen(scene: PackedScene):
	# Hide the HUD during UI screens
	$HUD.visible = false

	# Clear UI screen
	for child in $UIScreen.get_children():
		child.queue_free()

	# Clear game world, just in case
	for child in $WorldContainer.get_children():
		child.queue_free()

	var screen = scene.instantiate()
	$UIScreen.add_child(screen)
