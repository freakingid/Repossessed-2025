extends Node

@export var player_scene: PackedScene = preload("res://scenes/Player.tscn")

var player_instance: Node = null
var last_spawn_point: String = "PlayerStart"
var current_level_scene: Node = null
var hud: Node = null
var level_manager: Node = null
var level_music: Node = null


func _ready():
	# You can optionally preload the player here if the first level is loaded immediately.
	hud = get_node_or_null("/root/Main/HUD")
	level_manager = get_node_or_null("/root/Main/LevelManager")
	level_music = get_node_or_null("/root/Main/LevelMusic")


func start_new_game(initial_scene_path: String):
	# Called from Main.tscn or TitleScreen to start the game
	if not player_instance:
		player_instance = player_scene.instantiate()
	transition_to_scene(initial_scene_path)


func transition_to_scene(scene_path: String, spawn_point_name: String = "PlayerStart") -> void:
	last_spawn_point = spawn_point_name

	await get_tree().create_timer(0.1).timeout

	var new_level = load(scene_path).instantiate()
	var world_node = get_node("/root/Main/WorldContainer")

	# Clear previous level
	for child in world_node.get_children():
		child.queue_free()

	world_node.add_child(new_level)
	current_level_scene = new_level

	await new_level.ready
	
	# Enable HUD for gameplay
	get_node("/root/Main/HUD").visible = true

	var spawn_point = new_level.get_node_or_null(spawn_point_name)
	if spawn_point and player_instance:
		world_node.add_child(player_instance)
		player_instance.global_position = spawn_point.global_position
