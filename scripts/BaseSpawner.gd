extends Node2D
class_name BaseSpawner

var enemy_scene: PackedScene
var spawn_interval: float = 3.0
var max_enemies: int = 15
var health: int = 5
var score_value: int = 100

var enemies_spawned: int = 0
var player = null

func _ready():
	$DamageArea.collision_layer = Global.LAYER_SPAWNER
	$DamageArea.collision_mask = Global.LAYER_PLAYER | Global.LAYER_PLAYER_BULLET
	$DamageArea.monitoring = true

	# Connect signal safely
	if not $DamageArea.body_entered.is_connected(_on_DamageArea_body_entered):
		$DamageArea.body_entered.connect(_on_DamageArea_body_entered)

	var spawn_timer = Timer.new()
	spawn_timer.wait_time = spawn_interval
	spawn_timer.autostart = true
	spawn_timer.timeout.connect(_spawn_enemy)
	add_child(spawn_timer)

func _spawn_enemy():
	if enemies_spawned < max_enemies and enemy_scene:
		var enemy = enemy_scene.instantiate()
		enemy.global_position = global_position + Vector2(randf_range(-16, 16), randf_range(-16, 16))
		get_parent().add_child(enemy)
		enemies_spawned += 1
		enemy.tree_exited.connect(_on_enemy_destroyed)

func _on_enemy_destroyed():
	enemies_spawned = max(0, enemies_spawned - 1)

func take_damage(amount):
	health -= amount
	if health <= 0:
		player = get_tree().get_first_node_in_group("player")
		if player:
			player.add_score(score_value)
		queue_free()

func _on_DamageArea_body_entered(body):
	if body.is_in_group("player_projectiles"):
		take_damage(body.damage)
		body.queue_free()
