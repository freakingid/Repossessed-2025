extends Node

# Dictionary mapping PackedScene.resource_path to reusable enemies
var pools: Dictionary = {}

func _init():
	pools.clear()

func fetch_enemy(scene: PackedScene) -> Node2D:
	if scene == null:
		return null
	var key = scene.resource_path
	if not pools.has(key):
		pools[key] = []
	var pool = pools[key]

	while pool.size() > 0:
		var reused = pool.pop_back()
		if is_instance_valid(reused):
			# print("[POOL] Reusing enemy from pool:", key)
			return reused
		else:
			print("[POOL] Warning: tried to reuse freed instance")

	# Nothing valid found, instantiate new
	# print("[POOL] Instantiating new enemy:", key)
	return scene.instantiate()


func recycle_enemy(enemy: Node2D, scene: PackedScene) -> void:
	if scene == null or enemy == null or not is_instance_valid(enemy):
		return
	
	var key = scene.resource_path
	if not pools.has(key):
		pools[key] = []

	# Make sure it's removed from scene before pooling
	if enemy.get_parent():
		enemy.get_parent().remove_child(enemy)
	
	# Reset or hide the enemy
	enemy.visible = false
	enemy.set_physics_process(false)
	
	# Add back to pool
	pools[key].append(enemy)


# Optional utility to pre-fill a pool at game start
func preload_pool(scene: PackedScene, count: int):
	if scene == null:
		return
	for i in count:
		var enemy = scene.instantiate()
		recycle_enemy(enemy, scene)
