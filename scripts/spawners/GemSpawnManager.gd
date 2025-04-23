extends Node

var gem_scene: PackedScene = preload("res://scenes/Gem.tscn")  # Adjust path if needed

func spawn_gem(position: Vector2, value: int) -> void:
	if not gem_scene:
		push_warning("Gem scene not assigned in GemSpawnManager")
		return

	var gem = gem_scene.instantiate()
	gem.global_position = position
	gem.gem_power = value
	add_child(gem)  # Assumes GemSpawnManager is added to the scene tree
