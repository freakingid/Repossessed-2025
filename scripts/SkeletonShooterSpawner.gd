extends BaseSpawner

func _ready():
	enemy_scene = preload("res://scenes/SkeletonShooter.tscn")
	spawn_interval = 3.0
	max_enemies = 15
	super._ready()
