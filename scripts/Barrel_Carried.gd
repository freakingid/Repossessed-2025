extends CharacterBody2D
class_name Barrel_Carried

@export var explosion_scene: PackedScene
@onready var sprite: Sprite2D = $Sprite2D
@onready var flame_sprite: AnimatedSprite2D = $FlameSprite

var health: int = 10
var max_health: int = 10
var player: Node2D

func _ready():
	add_to_group("barrels_carried")
	sprite.z_index = Global.Z_PLAYER_AND_CRATES
	if flame_sprite:
		flame_sprite.z_index = Global.Z_PLAYER_AND_CRATES + 1
		flame_sprite.play()

	collision_layer = Global.LAYER_BARREL
	collision_mask = (
		Global.LAYER_PLAYER |
		Global.LAYER_WALL |
		Global.LAYER_ENEMY |
		Global.LAYER_SPAWNER |
		Global.LAYER_PLAYER_BULLET |
		Global.LAYER_ENEMY_PROJECTILE
	)

func _physics_process(_delta):
	if not player:
		return

	# Position barrel slightly in front of the player
	var offset = player.last_move_direction.normalized() * 10
	global_position = player.global_position + offset

	# Adjust z_index to appear in front or behind player
	if player.last_move_direction.y > 0:
		sprite.z_index = Global.Z_PLAYER_AND_CRATES + 1
		if flame_sprite:
			flame_sprite.z_index = Global.Z_PLAYER_AND_CRATES + 2
	else:
		sprite.z_index = Global.Z_PLAYER_AND_CRATES - 1
		if flame_sprite:
			flame_sprite.z_index = Global.Z_PLAYER_AND_CRATES

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

	# Detach from player so logic doesn't try to drop it again
	if player:
		player.carried_barrel_instance = null
		player.is_carrying_barrel = false

	queue_free()
