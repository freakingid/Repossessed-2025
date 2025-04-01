extends StaticBody2D

@export var carried_scene: PackedScene
@export var max_health: int = 10
var health: int
@export var explosion_scene: PackedScene
@onready var sprite: Sprite2D = $Sprite2D
@onready var flame_sprite = $FlameSprite  # Optional


func _ready():
	health = max_health
	collision_layer = Global.LAYER_BARREL
	collision_mask = (
		Global.LAYER_PLAYER |
		Global.LAYER_PLAYER_BULLET |
		Global.LAYER_ENEMY |
		Global.LAYER_ENEMY_PROJECTILE |
		Global.LAYER_SPAWNER
	)
	add_to_group("barrels_static")
	$Sprite2D.z_index = Global.Z_PLAYER_AND_CRATES
	$FlameSprite.z_index = Global.Z_PLAYER_AND_CRATES_FLAME
	update_flame()

func pickup(player):
	visible = false
	collision_layer = 0
	collision_mask = 0
	set_physics_process(false)

	var carried = carried_scene.instantiate()
	carried.player = player

	# ✅ Transfer health and update flame on carried barrel
	carried.health = health  # ✅ Transfer health to carried version
	carried.max_health = max_health  # Optional, but safe to be explicit
	carried.update_flame()
	
	player.carried_barrel_instance = carried
	get_tree().current_scene.call_deferred("add_child", carried)

func reactivate(position: Vector2):
	global_position = position
	visible = true
	collision_layer = Global.LAYER_BARREL
	collision_mask = Global.LAYER_PLAYER | Global.LAYER_PLAYER_BULLET | Global.LAYER_ENEMY
	set_physics_process(true)
	health = max_health

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
	print("Barrel Static Exploded")
	if explosion_scene:
		var explosion = explosion_scene.instantiate()
		explosion.global_position = global_position
		get_tree().current_scene.call_deferred("add_child", explosion)

	queue_free()
