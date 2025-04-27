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

func deactivate() -> void:
	print("Crate_Static: deactivate")

	# Hide sprite
	if has_node("Sprite2D"):
		$Sprite2D.visible = false
	
	# Disable collision shape
	if has_node("CollisionShape2D"):
		$CollisionShape2D.set_deferred("disabled", true)

	# Disable physics process
	set_physics_process(false)
	
	# Remove collision layers and masks so nothing interacts
	collision_layer = 0
	collision_mask = 0


func reactivate(new_position: Vector2) -> void:
	print("Crate_Static: reactivate")
	
	global_position = new_position
	print("Crate global_position: ", global_position)
	
	# Restore sprite visibility
	if has_node("Sprite2D"):
		$Sprite2D.visible = true
		$Sprite2D.z_index = Global.Z_CRATES  # Reset z-index properly (optional but safe)

	# Restore collision shape
	if has_node("CollisionShape2D"):
		$CollisionShape2D.set_deferred("disabled", false)
	
	# Restore physics process
	set_physics_process(true)
	
	# Restore collision layer and mask (matches what crates need)
	collision_layer = Global.LAYER_CRATE
	collision_mask = (
		Global.LAYER_PLAYER |
		Global.LAYER_PLAYER_BULLET |
		Global.LAYER_ENEMY |
		Global.LAYER_ENEMY_PROJECTILE |
		Global.LAYER_SPAWNER |
		Global.LAYER_BARREL
	)
