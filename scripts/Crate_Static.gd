extends StaticBody2D

@onready var sprite = $Sprite2D
@onready var collision_shape = $CollisionShape2D

func pickup(player: Node):
	print("Crate_Static: pickup")
	# Disable this crate visually and physically
	sprite.visible = false
	collision_shape.disabled = true
	set_physics_process(false)
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)

	# Instance and assign carried version
	var carried_crate = preload("res://scenes/Crate_Carried.tscn").instantiate()
	carried_crate.player = player
	get_tree().current_scene.add_child(carried_crate)

func reactivate(new_position: Vector2):
	global_position = new_position
	sprite.visible = true
	collision_shape.disabled = false
	set_physics_process(true)
	set_deferred("collision_layer", 8)
	set_deferred("collision_mask", 1)  # adjust if needed
	set_deferred("collision_mask", 2)  # adjust if needed
	set_deferred("collision_mask", 3)  # adjust if needed
	set_deferred("collision_mask", 7)  # adjust if needed
	set_deferred("collision_mask", 8)  # adjust if needed
