extends "res://scripts/BaseEnemy.gd"  # Subclassing BaseEnemy

var hit_player_recently = false  # Prevents continuous attacks, but NOT melee damage

func _ready():
	super()  # Calls BaseEnemy.gd's _ready()

	player = get_tree().get_first_node_in_group("player")
	health = Global.GHOST.HEALTH
	speed = Global.GHOST.SPEED
	damage = Global.GHOST.DAMAGE
	score_value = Global.GHOST.SCORE
	
	# Randomize ghost speed by ±20%
	speed = speed * randf_range(0.8, 1.2)  # Between 80% and 120% of base speed
	$Sprite2D.z_index = Global.Z_BASE_ENEMIES
