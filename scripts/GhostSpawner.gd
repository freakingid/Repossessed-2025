extends Node2D

@export var ghost_scene: PackedScene  # Assign Ghost.tscn in the Inspector
@export var spawn_interval: float = 3.0  # Time between spawns
@export var max_ghosts: int = 15  # Maximum number of ghosts at one time
@export var health: int = 3  # How much damage it can take before being destroyed
@export var score_value: int = 100  # Score awarded when destroyed

var ghosts_spawned: int = 0  # Current number of ghosts spawned
var player = null  # Reference to the player

func _ready():
	$DamageArea.collision_layer = Global.LAYER_SPAWNER
	$DamageArea.collision_mask = (
		Global.LAYER_PLAYER |
		Global.LAYER_PLAYER_BULLET
	)
	$DamageArea.monitoring = true

	# Start the Timer to spawn ghosts continuously
	var spawn_timer = Timer.new()
	spawn_timer.wait_time = spawn_interval
	spawn_timer.autostart = true
	spawn_timer.timeout.connect(_spawn_ghost)
	add_child(spawn_timer)  # Attach Timer to the Spawner

func _spawn_ghost():
	if ghosts_spawned < max_ghosts and ghost_scene:
		var ghost = ghost_scene.instantiate()
		ghost.global_position = global_position + Vector2(randf_range(-16, 16), randf_range(-16, 16))  # Random offset
		get_parent().add_child(ghost)
		ghosts_spawned += 1

		# Track when Ghost is removed
		ghost.tree_exited.connect(_on_ghost_destroyed)

func _on_ghost_destroyed():
	if ghosts_spawned > 0:
		ghosts_spawned -= 1  # Reduce count when a Ghost dies

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
