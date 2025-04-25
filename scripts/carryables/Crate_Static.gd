extends StaticBody2D

@onready var sprite = $Sprite2D
@onready var collision_shape = $CollisionShape2D

func _ready():
	collision_layer = Global.LAYER_CRATE
	collision_mask = (
		Global.LAYER_PLAYER |
		Global.LAYER_PLAYER_BULLET |
		Global.LAYER_ENEMY |
		Global.LAYER_ENEMY_PROJECTILE |
		Global.LAYER_SPAWNER |
		Global.LAYER_BARREL
	)
	$Sprite2D.z_index = Global.Z_CRATES

func pickup(player: Node):
	print("📦 pickup() called on Crate_Static")
	if player.is_vaulting:
		print("Player is vaulting, so not allowed to Crate_Static.pickup() even though we tried")
		return  # 🚫 Don't allow pickup while vaulting

	# Disable this crate visually and physically
	sprite.visible = false
	collision_shape.call_deferred("set_disabled", true)
	set_physics_process(false)
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)

	# Instance and assign carried version
	player.begin_carrying_crate(self)

func reactivate(new_position: Vector2):
	print("Crate_Static: reactivate")
	global_position = new_position
	# sprite.visible = true
	sprite.visible = true
	collision_shape.call_deferred("set_disabled", false)
	set_physics_process(true)
	set_deferred("collision_layer", 128)
	# bitwise values for layers 1, 2, 4, 7, 8
	set_deferred("collision_mask", 1 | 2 | 4 | 64 | 128)
