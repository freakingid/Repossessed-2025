extends RigidBody2D

@export var max_health: int = 10
@export var static_barrel_scene: PackedScene
var health: int
@export var explosion_scene: PackedScene
@onready var sprite = $Sprite2D
@onready var flame_sprite = $FlameSprite  # Optional
var alive_timer: float = 0.0
const MIN_ROLL_TIME = 0.75  # Seconds before it can convert


func _ready():
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
	add_to_group("barrels_rolled")
	$Sprite2D.z_index = Global.Z_PLAYER_AND_CRATES
	$FlameSprite.z_index = Global.Z_PLAYER_AND_CRATES_FLAME
	update_flame()

func _physics_process(delta):
	alive_timer += delta

	if alive_timer >= MIN_ROLL_TIME:
		if linear_velocity.length_squared() < 25.0: # have we slowed enough to become static?
			convert_to_static()

func convert_to_static():
	# Avoid double conversion
	if !is_inside_tree():
		return

	var static_barrel = static_barrel_scene.instantiate()
	static_barrel.global_position = global_position

	# ✅ Transfer health and update flame on new static barrel
	static_barrel.health = health  # ✅ Preserve health
	static_barrel.max_health = max_health
	static_barrel.update_flame()  # ✅ Sync flame size/color

	get_tree().current_scene.call_deferred("add_child", static_barrel)
	queue_free()

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

func _on_body_entered(body):
	if body.is_in_group("player_projectiles"):
		take_damage(body.damage) # damage self (barrel)
		body.take_damage(1)  # optional projectile reaction

	# For heavier things like enemies/crates, apply bounce or logic here if needed

func explode():
	print("Barrel Rolled Exploded")
	if explosion_scene:
		var explosion = explosion_scene.instantiate()
		explosion.global_position = global_position
		get_tree().current_scene.call_deferred("add_child", explosion)

	queue_free()
