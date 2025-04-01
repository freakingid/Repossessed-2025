extends RigidBody2D
class_name Barrel_Rolled

@export var static_barrel_scene: PackedScene
@export var explosion_scene: PackedScene
@onready var sprite: Sprite2D = $Sprite2D
@onready var flame_sprite: AnimatedSprite2D = $FlameSprite

var max_health: int = Global.BARREL.HEALTH
var health: int = Global.BARREL.HEALTH
var alive_timer: float = 0.0
const MIN_ROLL_TIME = 0.75  # Seconds before it can convert
var invincible_time := Global.BARREL.DROPWAIT  # Duration in seconds
var drop_invincibility_timer := 0.0

func _ready():
	print("Barrel Rolled _ready() fires with health == ", health, " and max_health == ", max_health)
	add_to_group("barrels_rolled")
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
		Global.LAYER_SPAWNER |
		Global.LAYER_CRATE |
		Global.LAYER_WALL
	)

	# Invinible to enemy shots for a short time after being dropped
	drop_invincibility_timer = invincible_time

func _physics_process(delta):
	# After first kicked, barrel ignores damage for a time
	if drop_invincibility_timer > 0.0:
		drop_invincibility_timer -= delta

	# Manage how long we roll until we stop and turn into Barrel_Static
	alive_timer += delta
	if alive_timer >= MIN_ROLL_TIME:
		if linear_velocity.length_squared() < 25.0:
			convert_to_static()

func convert_to_static():
	print("Barrel Rolled converting to static and has health == ", health, " and max_health == ", max_health)
	if !is_inside_tree():
		return
	
	var static_barrel = static_barrel_scene.instantiate()
	static_barrel.global_position = global_position
	BarrelUtils.set_barrel_state(static_barrel, static_barrel.flame_sprite, health, max_health)
	print("Barrel Static just created and set with health == ", static_barrel.health, " and max_health == ", static_barrel.max_health)
	get_tree().current_scene.call_deferred("add_child", static_barrel)
	queue_free()

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

func _on_body_entered(body):
	if body.is_in_group("player_projectiles"):
		take_damage(body.damage)
		body.take_damage(1)

func explode():
	if explosion_scene:
		var explosion = explosion_scene.instantiate()
		explosion.global_position = global_position
		get_tree().current_scene.call_deferred("add_child", explosion)
	queue_free()
