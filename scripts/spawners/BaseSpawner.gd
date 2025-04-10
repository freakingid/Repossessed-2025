extends Node2D

@export var enemy_scene: PackedScene
@export var spawn_interval: float = -1.0
@export var max_enemies: int = -1
@export var delay_before_start: float = 0.0
@export var is_active: bool = true

var enemies_spawned: int = 0
var health: int = -1
var flash_timer: float = 0.1
var original_modulate: Color

signal enemy_spawned(enemy: Node2D)
signal spawner_destroyed(spawner: Node2D)

func _ready():
	if spawn_interval <= 0.0:
		spawn_interval = Global.DEFAULT_SPAWN_INTERVAL
	if max_enemies < 0:
		max_enemies = Global.DEFAULT_MAX_ENEMIES
	if health < 0:
		health = Global.DEFAULT_SPAWNER_HEALTH
	original_modulate = get_node("Sprite2D").modulate
	_start_spawning()

func _start_spawning() -> void:
	if delay_before_start > 0.0:
		await get_tree().create_timer(delay_before_start).timeout
	_spawn_loop()

func _spawn_loop() -> void:
	if not is_active:
		await get_tree().process_frame
		return _spawn_loop()
	spawn_timer()

func spawn_timer() -> void:
	await get_tree().create_timer(spawn_interval).timeout
	if is_active and enemies_spawned < max_enemies and enemy_scene:
		_spawn_enemy()
	_spawn_loop()

func _spawn_enemy() -> void:
	var enemy = EnemyPool.fetch_enemy(enemy_scene)
	if enemy:
		enemy.global_position = global_position + Vector2(randf_range(-16, 16), randf_range(-16, 16))
		get_parent().add_child(enemy)
		enemies_spawned += 1
		enemy.tree_exited.connect(_on_enemy_destroyed)
		emit_signal("enemy_spawned", enemy)

func _on_enemy_destroyed() -> void:
	enemies_spawned = max(enemies_spawned - 1, 0)

func apply_damage(amount: int) -> void:
	health -= amount
	_flash_damage()
	if health <= 0:
		destroy_spawner()

func _flash_damage() -> void:
	var sprite = get_node("Sprite2D")
	sprite.modulate = Color(1, 0.2, 0.2) # Red flash
	await get_tree().create_timer(flash_timer).timeout
	sprite.modulate = original_modulate

func destroy_spawner():
	emit_signal("spawner_destroyed", self)
	queue_free()

func activate():
	is_active = true

func deactivate():
	is_active = false
