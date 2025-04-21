# HitEffectUtils.gd
extends Node

## This script is autoloaded as a singleton
## It spawns visual and audio feedback when enemies are hit

@onready var hit_fx_scene = preload("res://scenes/fx/EnemyHitEffect.tscn")  # Adjust path if needed

func spawn_enemy_hit_effect(at_position: Vector2) -> void:
	var fx = hit_fx_scene.instantiate()
	fx.global_position = at_position
	get_tree().current_scene.add_child(fx)

	# TODO: Play sound effect here
	# Example: SoundManager.play("enemy_hit") — or you can extend this later
