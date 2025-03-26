extends BaseSpawner

func _ready():
	enemy_scene = preload("res://scenes/Ghost.tscn")
	spawn_interval = 3.0
	max_enemies = 15
	health = 3
	score_value = 100
	super._ready()
