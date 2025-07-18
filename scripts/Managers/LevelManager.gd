extends Node

@export var preload_count_default: int = 20
@export var custom_preload_amounts := {
	"res://scenes/enemies/Ghost.tscn": 50,
	"res://scenes/enemies/Skeleton.tscn": 10,
	"res://scenes/enemies/SkeletonShooter.tscn": 10,
	"res://scenes/enemies/Bat.tscn": 10,
	"res://scenes/enemies/Zombie.tscn": 60
}

func _ready():
	preload_used_enemy_types()

func preload_used_enemy_types():
	var seen_paths := {}
	var spawners := get_tree().get_nodes_in_group(Global.GROUPS.SPAWNERS)

	for spawner in spawners:
		if spawner.enemy_scene:
			var path: String = spawner.enemy_scene.resource_path
			if not seen_paths.has(path):
				seen_paths[path] = true
				var preload_count = Global.get_max_capacity_for_scene(path)
				EnemyPool.preload_pool(spawner.enemy_scene, preload_count)
				# print("Preloading %d of %s" % [preload_count, path])
