extends Node

## Attach this script to a node in the scene...
## and it should randomly place powerups throughout the gameplay
## The spawn_area, I am uncertain how that works off hand

@export var powerup_scenes: Array[PackedScene]  # Array of different powerup scenes
@export var max_powerups: int = 5  # Limit active powerups
@export var spawn_area: Node2D  # Reference to an area for spawning

@onready var spawn_timer = $SpawnTimer

func _ready():
	spawn_timer.start()

func _on_SpawnTimer_timeout():
	# Check if we've reached the max number of powerups
	if get_tree().get_nodes_in_group("powerups").size() >= max_powerups:
		return  # Don't spawn more

	# Choose a random powerup
	var powerup_scene = powerup_scenes.pick_random()
	var powerup = powerup_scene.instantiate()
	
	# Random spawn position
	var spawn_position = spawn_area.get_children().pick_random().global_position
	powerup.global_position = spawn_position
	
	# Add to scene
	powerup.add_to_group("powerups")
	get_tree().current_scene.add_child(powerup)
