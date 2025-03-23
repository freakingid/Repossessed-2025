extends StaticBody2D

@onready var sprite = $Sprite2D
@onready var collision_shape = $CollisionShape2D

func pickup(player: Node):
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
