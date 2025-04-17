# Barrel_Rolled.gd - VERIFIED
# Node Type: RigidBody2D
# Behavior: Rolls with physics, bounces, damages enemies and barrels, explodes on destruction
# NOTE: Do not modify node type; RigidBody2D needed for physics bounce behavior

extends RigidBody2D
class_name Barrel_Rolled

@export var static_barrel_scene: PackedScene
@export var explosion_scene: PackedScene
@onready var sprite: Sprite2D = $Sprite2D
@onready var flame_sprite: AnimatedSprite2D = $FlameSprite

const ROLL_STOP_THRESHOLD := 64.0  # Tune this to taste — lower = stricter; also, squared

var max_health: int = Global.BARREL.HEALTH
var health: int = Global.BARREL.HEALTH
var invincible_time := Global.BARREL.DROPWAIT  # Duration in seconds
var drop_invincibility_timer := 0.0

func _ready():
	# Set collision exception for all enemy projectiles
	for projectile in get_tree().get_nodes_in_group("enemy_projectiles"):
		add_collision_exception_with(projectile)

	sprite.z_index = Global.Z_BARRELS
	if flame_sprite:
		flame_sprite.z_index = Global.Z_BARRELS_FLAME
		BarrelUtils.set_barrel_state(self, flame_sprite, health, max_health)

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
	if linear_velocity.length_squared() < ROLL_STOP_THRESHOLD:
		convert_to_static()

func convert_to_static():
	if !is_inside_tree():
		return
	
	var static_barrel = static_barrel_scene.instantiate()
	static_barrel.global_position = global_position
	BarrelUtils.set_barrel_state(static_barrel, static_barrel.flame_sprite, health, max_health)
	get_tree().current_scene.call_deferred("add_child", static_barrel)
	queue_free()

func take_damage(amount: int):
	if drop_invincibility_timer > 0.0:
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
