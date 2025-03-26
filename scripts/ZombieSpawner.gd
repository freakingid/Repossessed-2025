extends BaseSpawner

func _ready():
	enemy_scene = preload("res://scenes/Zombie.tscn")
	spawn_interval = 3.0
	max_enemies = 10
	health = 3
	score_value = 150
	super._ready()
