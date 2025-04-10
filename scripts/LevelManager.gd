extends Node

@export var preload_count_default: int = 20
@export var custom_preload_amounts := {
	"res://scenes/enemies/Ghost.tscn": 50,
	"res://scenes/enemies/Zombie.tscn": 60
}

func _ready():
	preload_used_enemy_types()

func preload_used_enemy_types():
	var seen_paths := {}
	var spawners := get_tree().get_nodes_in_group(Global.GROUPS.SPAWNERS)

	for spawner in spawners:
		if spawner.enemy_scene != null:
			var scene_path: String = spawner.enemy_scene.resource_path
			if not seen_paths.has(scene_path):
				seen_paths[scene_path] = true

				var count = preload_count_default
				if custom_preload_amounts.has(scene_path):
					count = custom_preload_amounts[scene_path]

				EnemyPool.preload_pool(spawner.enemy_scene, count)
				print("Preloading %d of %s" % [count, scene_path])
