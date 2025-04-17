# Barrel_Carried.gd - VERIFIED
# Node Type: CharacterBody2D
# Behavior: Follows player, cannot be vaulted, explodes on destruction, uses flame sprite visuals
# TODO: Ensure collision with enemies/barrels is handled consistently

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
	# Why are we having to add this??
	sprite.visible = true
	if flame_sprite:
		flame_sprite.visible = true

	if flame_sprite:
		flame_sprite.z_index = Global.Z_BARRELS_FLAME
		BarrelUtils.set_barrel_state(self, flame_sprite, health, max_health)

	collision_layer = Global.LAYER_BARREL
	collision_mask = (
		Global.LAYER_WALL |
		Global.LAYER_SPAWNER |
		Global.LAYER_CRATE |
		Global.LAYER_BARREL |
		Global.LAYER_ENEMY |
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
		sprite.z_index = Global.Z_CARRIED_CRATE_IN_FRONT
		if flame_sprite:
			flame_sprite.z_index = Global.Z_CARRIED_CRATE_IN_FRONT_FLAME
	else:
		# Player moving down, Barrel should be visually on top
		sprite.z_index = Global.Z_CARRIED_CRATE_BEHIND
		if flame_sprite:
			flame_sprite.z_index = Global.Z_CARRIED_CRATE_BEHIND_FLAME
	
	print("====================")
	print("Barrel_Carried end of _physics_process sprite.z_index == ", sprite.z_index)
	print("and global_position == ", global_position)
	print("and player.global_position == ", player.global_position)
	print("Barrel_Carried.visible == ", self.visible)

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
