extends CharacterBody2D

@export var max_health: int = 10
var health: int
@export var explosion_scene: PackedScene

var player: Node2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var flame_sprite = $FlameSprite  # Optional

func _ready():
	collision_layer = Global.LAYER_BARREL
	collision_mask = (
		Global.LAYER_PLAYER |
		Global.LAYER_WALL |
		Global.LAYER_ENEMY |
		Global.LAYER_SPAWNER |
		Global.LAYER_PLAYER_BULLET |
		Global.LAYER_ENEMY_PROJECTILE
	)
	add_to_group("barrels_carried")
	sprite.z_index = Global.Z_PLAYER_AND_CRATES
	$FlameSprite.z_index = Global.Z_PLAYER_AND_CRATES_FLAME
	update_flame()

func _physics_process(_delta):
	if not player:
		return

	var offset = player.last_move_direction.normalized() * 10
	global_position = player.global_position + offset

	# Adjust z_index to appear in front or behind player
	if player.last_move_direction.y > 0:
		sprite.z_index = Global.Z_PLAYER_AND_CRATES + 1
	else:
		sprite.z_index = Global.Z_PLAYER_AND_CRATES - 1

#func _on_body_entered(body):
	#if body.is_in_group("player_projectiles") or body.is_in_group("enemy_projectiles"):
		#take_damage(body.damage)
		#body.take_damage(1)  # Bullet takes damage from barrel

func take_damage(amount: int):
	health -= amount
	update_flame()

	if health <= 0:
		explode()

func update_flame():
	if not flame_sprite:
		return

	flame_sprite.play("flame")

	var ratio = float(health) / float(max_health)

	if ratio > 0.9:
		flame_sprite.visible = false
	elif ratio > 0.7:
		flame_sprite.visible = true
		flame_sprite.scale = Vector2.ONE * 1.0
		flame_sprite.modulate = Color(1, 0, 0)  # 🔥 Red
	elif ratio > 0.5:
		flame_sprite.visible = true
		flame_sprite.scale = Vector2.ONE * 1.3
		flame_sprite.modulate = Color(1, 0, 0)  # 🔥 Red
	elif ratio > 0.3:
		flame_sprite.visible = true
		flame_sprite.scale = Vector2.ONE * 1.7
		flame_sprite.modulate = Color(1, 1, 0)  # 🔥 Yellow
	else:
		flame_sprite.visible = true
		flame_sprite.scale = Vector2.ONE * 2.0
		flame_sprite.modulate = Color(1, 1, 0.9)  # 🔥 White-yellow

func explode():
	print("Barrel Carried Exploded")
	if explosion_scene:
		var explosion = explosion_scene.instantiate()
		explosion.global_position = global_position
		get_tree().current_scene.call_deferred("add_child", explosion)

	# Detach from player so logic doesn't try to drop it again
	if player:
		player.carried_barrel_instance = null
		player.is_carrying_barrel = false

	queue_free()
