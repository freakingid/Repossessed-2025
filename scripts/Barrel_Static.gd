extends StaticBody2D
class_name Barrel_Static

@export var carried_scene: PackedScene
@export var explosion_scene: PackedScene
@onready var sprite: Sprite2D = $Sprite2D
@onready var flame_sprite: AnimatedSprite2D = $FlameSprite

var health: int = 10
var max_health: int = 10

func _ready():
	add_to_group("barrels_static")
	sprite.z_index = Global.Z_PLAYER_AND_CRATES
	if flame_sprite:
		flame_sprite.z_index = Global.Z_PLAYER_AND_CRATES + 1
		flame_sprite.play()

	collision_layer = Global.LAYER_BARREL
	collision_mask = (
		Global.LAYER_PLAYER |
		Global.LAYER_PLAYER_BULLET |
		Global.LAYER_ENEMY |
		Global.LAYER_ENEMY_PROJECTILE |
		Global.LAYER_SPAWNER
	)

func pickup(player):
	visible = false
	collision_layer = 0
	collision_mask = 0
	set_physics_process(false)

	var carried = carried_scene.instantiate()
	carried.player = player
	BarrelUtils.set_barrel_state(carried, carried.flame_sprite, health, max_health)
	player.carried_barrel_instance = carried
	get_tree().current_scene.call_deferred("add_child", carried)

func reactivate(position: Vector2):
	global_position = position
	visible = true
	health = max_health
	if flame_sprite:
		flame_sprite.play()
		BarrelUtils.update_flame(flame_sprite, health, max_health)
	collision_layer = Global.LAYER_BARREL
	collision_mask = (
		Global.LAYER_PLAYER |
		Global.LAYER_PLAYER_BULLET |
		Global.LAYER_ENEMY
	)
	set_physics_process(true)

func take_damage(amount: int):
	health -= amount
	if flame_sprite:
		flame_sprite.play()
		BarrelUtils.update_flame(flame_sprite, health, max_health)
	if health <= 0:
		explode()

func explode():
	if explosion_scene:
		var explosion = explosion_scene.instantiate()
		explosion.global_position = global_position
		get_tree().current_scene.call_deferred("add_child", explosion)
	queue_free()
