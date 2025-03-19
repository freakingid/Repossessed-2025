extends Node2D

@export var bat_scene: PackedScene  # Assign Bat.tscn in the Inspector
@export var spawn_interval: float = 4.0  # Time between spawns
@export var max_bats: int = 10  # Maximum number of bats allowed in the scene
@export var health: int = 3  # How much damage it can take before being destroyed
@export var score_value: int = 150  # Score awarded when destroyed

var bats_spawned: int = 0  # Current number of bats spawned
var player = null  # Reference to the player

func _ready():
	# Timer to control spawning
	var spawn_timer = Timer.new()
	spawn_timer.wait_time = spawn_interval
	spawn_timer.autostart = true
	spawn_timer.timeout.connect(_spawn_bat)
	add_child(spawn_timer)

func _spawn_bat():
	if bats_spawned < max_bats and bat_scene:
		var bat = bat_scene.instantiate()
		bat.global_position = global_position + Vector2(randf_range(-16, 16), randf_range(-16, 16))  # Slight random offset
		get_parent().add_child(bat)
		bats_spawned += 1

		# Reduce bat count when a bat dies
		bat.tree_exited.connect(_on_bat_destroyed)

func _on_bat_destroyed():
	if bats_spawned > 0:
		bats_spawned -= 1

func take_damage(amount):
	health -= amount
	if health <= 0:
		player = get_tree().get_first_node_in_group("player")
		if player:
			player.add_score(score_value)
		queue_free()  # Destroy spawner

func _on_DamageArea_area_entered(area):
	if area.is_in_group("player_projectiles"):
		take_damage(1)
		area.queue_free()  # Remove bullet after impact
