extends BaseSpawner

func _ready():
	enemy_scene = preload("res://scenes/Zombie.tscn")
	spawn_interval = 3.0
	max_enemies = 0
	super._ready()
