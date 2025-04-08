extends BaseSpawner

func _ready():
	enemy_scene = preload("res://scenes/enemies/SkeletonShooter.tscn")
	spawn_interval = 3.0
	max_enemies = 2
	super._ready()
