extends Node2D

@export var spawn_with_debug: bool = false  # ✅ Toggle this in the Inspector
@export var skeleton_shooter_scene: PackedScene  # Assign Skeleton.tscn in the Inspector
@export var spawn_interval: float = 3.0  # Time between spawns
@export var max_skeletons: int = 15  # Maximum number of skeletons at one time
@export var health: int = 3  # How much damage it can take before being destroyed
@export var score_value: int = 100  # Score awarded when destroyed

var skeletons_spawned: int = 0  # Current number of skeletons spawned
var player = null  # Reference to the player

func _ready():
	# Start the Timer to spawn skeletons continuously
	var spawn_timer = Timer.new()
	spawn_timer.wait_time = spawn_interval
	spawn_timer.autostart = true
	spawn_timer.timeout.connect(_spawn_skeleton)
	add_child(spawn_timer)  # Attach Timer to the Spawner

func _spawn_skeleton():
	if skeletons_spawned < max_skeletons and skeleton_shooter_scene:		
		var skeleton = skeleton_shooter_scene.instantiate()
		skeleton.global_position = global_position + Vector2(randf_range(-16, 16), randf_range(-16, 16))  # Random offset
		skeleton.show_debug_circles = spawn_with_debug  # ✅ Enable debug mode if needed
		get_parent().add_child(skeleton)
		skeletons_spawned += 1

		# Track when Skeleton is removed
		skeleton.tree_exited.connect(_on_skeleton_destroyed)

func _on_skeleton_destroyed():
	if skeletons_spawned > 0:
		skeletons_spawned -= 1  # Reduce count when a Skeleton dies

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
