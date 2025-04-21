extends CharacterBody2D
class_name Barrel_Carried

@export var explosion_scene: PackedScene
@onready var sprite: Sprite2D = $Sprite2D
@onready var flame_sprite: AnimatedSprite2D = $FlameSprite

var max_health: int = Global.BARREL.HEALTH
var health: int = Global.BARREL.HEALTH
var player: Node2D

func _ready():
	sprite.z_index = Global.Z_BARRELS
	if flame_sprite:
		flame_sprite.z_index = Global.Z_BARRELS_FLAME
		BarrelUtils.set_barrel_state(self, flame_sprite, health, max_health)

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
		# Player moving up, Barrel should be visually underneath
		sprite.z_index = Global.Z_CARRIED_BARREL_IN_FRONT
		if flame_sprite:
			flame_sprite.z_index = Global.Z_CARRIED_BARREL_IN_FRONT_FLAME
	else:
		# Player moving down, Barrel should be visually on top
		sprite.z_index = Global.Z_CARRIED_BARREL_BEHIND
		if flame_sprite:
			flame_sprite.z_index = Global.Z_CARRIED_BARREL_BEHIND_FLAME

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
