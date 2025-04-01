extends StaticBody2D
class_name Barrel_Static

@export var carried_scene: PackedScene
@export var explosion_scene: PackedScene
@onready var sprite: Sprite2D = $Sprite2D
@onready var flame_sprite: AnimatedSprite2D = $FlameSprite

var max_health: int = Global.BARREL.HEALTH # max_health to calculate percent health left
var health: int = Global.BARREL.HEALTH # health is actual, current health
var invincible_time := Global.BARREL.DROPWAIT  # Duration in seconds
var drop_invincibility_timer := 0.0

func _ready():
	print("Barrel Static _ready() fired with health == ", health, " and max_health == ", max_health)
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

	# Invinible to enemy shots for a short time after being dropped
	drop_invincibility_timer = invincible_time

func _physics_process(delta):
	if drop_invincibility_timer > 0.0:
		drop_invincibility_timer -= delta

## What happens when the player picks up the Barrel?
func pickup(player):
	print("Barrel Static being picked up and has health == ", health, " and max_health == ", max_health)
	# Make us invisible
	visible = false
	
	# Make us not collide
	collision_layer = 0
	collision_mask = 0
	set_physics_process(false)

	# Make an instance of the Barrel_Carried
	var carried = carried_scene.instantiate()
	carried.player = player
	BarrelUtils.set_barrel_state(carried, carried.flame_sprite, health, max_health)
	print("Setup Carried Barrel to: health == ", carried.health, " max_health == ", carried.max_health)
	player.carried_barrel_instance = carried
	get_tree().current_scene.call_deferred("add_child", carried)

func reactivate(position: Vector2):
	global_position = position
	visible = true
	if flame_sprite:
		flame_sprite.play()
		BarrelUtils.update_flame(flame_sprite, health, max_health)
	collision_layer = Global.LAYER_BARREL
	collision_mask = (
		Global.LAYER_PLAYER |
		Global.LAYER_PLAYER_BULLET |
		Global.LAYER_ENEMY
	)
	# Temporarily invincible to shots
	drop_invincibility_timer = invincible_time
	set_physics_process(true)

func take_damage(amount: int):
	if drop_invincibility_timer > 0.0:
		print("Barrel is temporarily invincible after being dropped.")
		return

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
