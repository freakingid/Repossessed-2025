extends Node

var gem_scene: PackedScene = preload("res://scenes/Gem.tscn")  # Adjust path if needed

func spawn_gem(position: Vector2, value: int) -> void:
	if not gem_scene:
		push_warning("Gem scene not assigned in GemSpawnManager")
		return

	var gem = gem_scene.instantiate()
	gem.global_position = position
	gem.gem_power = value
	call_deferred("add_child", gem)  # ✅ Safe to call during physics step

func _on_enemy_died(global_position: Vector2, score_value: int) -> void:
	spawn_gem(global_position, score_value)
