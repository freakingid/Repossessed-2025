extends "res://scripts/BaseEnemy.gd"  # Inherits from BaseEnemy

func _ready():
	health = 5  # Skeletons are tougher than Ghosts
	speed = 80.0  # Skeletons move slower
