extends "res://scripts/BaseEnemy.gd"  # Subclassing BaseEnemy

@export var score_value: int = 1
var hit_player_recently = false  # Prevents continuous attacks, but NOT melee damage

func _ready():
	super()  # Calls BaseEnemy.gd's _ready()
	player = get_tree().get_first_node_in_group("player")
	if player == null:
		print("Error executing Zombie.gd: No player found!")
	health = 8  # Zombies have higher health
	base_speed = 30.0  # Zombies are slower
	damage = 3  # Zombies deal high melee damage
	
	# Randomize zombie speed by ±20%
	speed = base_speed * randf_range(0.8, 1.2)  # Between 80% and 120% of base speed

func take_damage(amount):
	health -= amount
	
	if health <= 0:
		# Grant score to player upon death
		var player = get_tree().get_first_node_in_group("player")
		if player:
			player.add_score(score_value)  # Or any value you want
		queue_free()  # Destroy the zombie
