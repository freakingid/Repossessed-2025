extends Node2D

@export var zombie_scene: PackedScene  # Assign zombie.tscn in the Inspector
@export var spawn_interval: float = 3.0  # Time between spawns
@export var max_zombies: int = 15  # Maximum number of zombies at one time
@export var health: int = 3  # How much damage it can take before being destroyed
@export var score_value: int = 100  # Score awarded when destroyed

var zombies_spawned: int = 0  # Current number of zombies spawned
var player = null  # Reference to the player

func _ready():
	# Start the Timer to spawn ghosts continuously
	var spawn_timer = Timer.new()
	spawn_timer.wait_time = spawn_interval
	spawn_timer.autostart = true
	spawn_timer.timeout.connect(_spawn_zombie)
	add_child(spawn_timer)  # Attach Timer to the Spawner

func _spawn_zombie():
	if zombies_spawned < max_zombies and zombie_scene:
		var zombie = zombie_scene.instantiate()
		zombie.global_position = global_position + Vector2(randf_range(-16, 16), randf_range(-16, 16))  # Random offset
		get_parent().add_child(zombie)
		zombies_spawned += 1

		# Track when zombie is removed
		zombie.tree_exited.connect(_on_zombie_destroyed)

func _on_zombie_destroyed():
	if zombies_spawned > 0:
		zombies_spawned -= 1  # Reduce count when a zombie dies

func take_damage(amount):
	health -= amount

	if health <= 0:
		# Grant score to player upon death
		player = get_tree().get_first_node_in_group("player")
		if player:
			player.add_score(score_value)  # Or any value you want
		queue_free()  # Destroy spawner

func _on_DamageArea_area_entered(area):
	if area.is_in_group("player_projectiles"):
		take_damage(1)

		# Destroy the bullet after impact
		area.queue_free()
