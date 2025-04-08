extends BaseSpawner

func _ready():
	enemy_scene = preload("res://scenes/enemies/Bat.tscn")
	spawn_interval = 4.0
	max_enemies = 0
	super._ready()
