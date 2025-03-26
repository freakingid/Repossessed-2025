extends BaseSpawner

func _ready():
	enemy_scene = preload("res://scenes/Bat.tscn")
	spawn_interval = 4.0
	max_enemies = 10
	super._ready()
