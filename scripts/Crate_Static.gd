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
		Global.LAYER_SPAWNER
	)
	add_to_group("crates_static")
	$Sprite2D.z_index = Global.Z_PLAYER_AND_CRATES

func pickup(player: Node):
	print("Crate_Static: pickup")
	# Disable this crate visually and physically
	sprite.visible = false
	collision_shape.call_deferred("set_disabled", true)
	set_physics_process(false)
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)

	# Instance and assign carried version
	var carried_crate = preload("res://scenes/Crate_Carried.tscn").instantiate()
	carried_crate.player = player
	player.carried_crate_instance = carried_crate  # 🔗 Save reference
	get_tree().current_scene.call_deferred("add_child", carried_crate)

func reactivate(new_position: Vector2):
	global_position = new_position
	sprite.visible = true
	collision_shape.call_deferred("set_disabled", false)
	set_physics_process(true)
	set_deferred("collision_layer", 128)
	# bitwise values for layers 1, 2, 4, 7, 8
	set_deferred("collision_mask", 1 | 2 | 4 | 64 | 128)
