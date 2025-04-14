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
	if pool.size() > 0:
		var reused = pool.pop_back()
		# print("[POOL] Reusing enemy from pool:", key)
		return reused
	# print("[POOL] Instantiating new enemy:", key)
	return scene.instantiate()

func recycle_enemy(enemy: Node2D, scene: PackedScene) -> void:
	if scene == null or enemy == null:
		return
	var key = scene.resource_path
	if not pools.has(key):
		pools[key] = []
	# Reset or hide the enemy as needed before recycling
	enemy.visible = false
	enemy.set_physics_process(false)
	pools[key].append(enemy)
	if enemy.get_parent():
		enemy.get_parent().remove_child(enemy)
	# print("[POOL] Recycled enemy into pool:", key)

# Optional utility to pre-fill a pool at game start
func preload_pool(scene: PackedScene, count: int):
	if scene == null:
		return
	for i in count:
		var enemy = scene.instantiate()
		recycle_enemy(enemy, scene)
