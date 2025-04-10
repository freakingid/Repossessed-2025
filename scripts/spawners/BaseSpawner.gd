extends Node2D

@export var enemy_scene: PackedScene
@export var spawn_interval: float = -1.0
@export var max_enemies: int = -1

var enemies_spawned: int = 0
var health: int = -1

signal enemy_spawned(enemy: Node2D)
signal spawner_destroyed(spawner: Node2D)

func _ready():
	# Use Global defaults if no values were set in Inspector
	if spawn_interval <= 0.0:
		spawn_interval = Global.DEFAULT_SPAWN_INTERVAL
	if max_enemies < 0:
		max_enemies = Global.DEFAULT_MAX_ENEMIES
	if health < 0:
		health = Global.DEFAULT_SPAWNER_HEALTH
	_spawn_loop()

func _spawn_loop() -> void:
	spawn_timer()

func spawn_timer() -> void:
	await get_tree().create_timer(spawn_interval).timeout
	if enemies_spawned < max_enemies and enemy_scene:
		_spawn_enemy()
	_spawn_loop()

func _spawn_enemy() -> void:
	var enemy = enemy_scene.instantiate()
	enemy.global_position = global_position + Vector2(randf_range(-16, 16), randf_range(-16, 16))
	get_parent().add_child(enemy)
	enemies_spawned += 1
	enemy.tree_exited.connect(_on_enemy_destroyed)
	emit_signal("enemy_spawned", enemy)

func _on_enemy_destroyed() -> void:
	enemies_spawned = max(enemies_spawned - 1, 0)

func apply_damage(amount: int) -> void:
	health -= amount
	if health <= 0:
		destroy_spawner()

func destroy_spawner():
	emit_signal("spawner_destroyed", self)
	queue_free()
