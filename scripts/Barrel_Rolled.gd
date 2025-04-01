extends RigidBody2D
class_name Barrel_Rolled

@export var static_barrel_scene: PackedScene
@export var explosion_scene: PackedScene
@onready var sprite: Sprite2D = $Sprite2D
@onready var flame_sprite: AnimatedSprite2D = $FlameSprite

var health: int = 10
var max_health: int = 10
var alive_timer: float = 0.0
const MIN_ROLL_TIME = 0.75  # Seconds before it can convert

func _ready():
	add_to_group("barrels_rolled")
	sprite.z_index = Global.Z_PLAYER_AND_CRATES
	if flame_sprite:
		flame_sprite.z_index = Global.Z_PLAYER_AND_CRATES + 1
		flame_sprite.play()

	health = max_health
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

func _physics_process(delta):
	alive_timer += delta
	if alive_timer >= MIN_ROLL_TIME:
		if linear_velocity.length_squared() < 25.0:
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
