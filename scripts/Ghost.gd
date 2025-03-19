extends "res://scripts/BaseEnemy.gd"  # Subclassing BaseEnemy

var hit_player_recently = false  # Prevents continuous attacks, but NOT melee damage

func _ready():
	super()  # Calls BaseEnemy.gd's _ready()

	player = get_tree().get_first_node_in_group("player")
	health = 2  # Ghosts have lower health
	base_speed = 35 # Later might be a percentage of BaseEnemy.base_speed
	damage = 1
	score_value = 1

	# Randomize ghost speed by ±20%
	speed = base_speed * randf_range(0.8, 1.2)  # Between 80% and 120% of base speed
