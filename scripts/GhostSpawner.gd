extends BaseSpawner

func _ready():
	enemy_scene = preload("res://scenes/Ghost.tscn")
	spawn_interval = 3.0
	max_enemies = 10
	super._ready()
