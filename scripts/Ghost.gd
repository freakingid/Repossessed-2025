extends "res://scripts/BaseEnemy.gd"  # Subclassing BaseEnemy

@export var score_value: int = 1

var hit_player_recently = false  # Prevents continuous attacks, but NOT melee damage

func _ready():
	super()  # Calls BaseEnemy.gd's _ready()

	player = get_tree().get_first_node_in_group("player")
	if player == null:
		print("Error executing Ghost.gd: No player found!")
	health = 8 # 2  # Ghosts have lower health
	base_speed = 75 # Later might be a percentage of BaseEnemy.base_speed
	damage = 1

	# Randomize ghost speed by ±20%
	speed = base_speed * randf_range(0.8, 1.2)  # Between 80% and 120% of base speed

func take_damage(amount):
	health -= amount
	
	if health <= 0:
		# Grant score to player upon death
		var player = get_tree().get_first_node_in_group("player")
		if player:
			player.add_score(score_value)  # Or any value you want
		queue_free()  # Destroy the ghost
