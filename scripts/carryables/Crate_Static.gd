extends CharacterBody2D

@onready var sprite = $Sprite2D
@onready var collision_shape = $CollisionShape2D
var drop_motion: Vector2 = Vector2.ZERO

func _ready():
	# Only called once, but leave this in for safety, related to drop motion
	if has_meta("drop_motion"):
		drop_motion = get_meta("drop_motion")

	collision_layer = Global.LAYER_CRATE
	collision_mask = (
		Global.LAYER_PLAYER |
		Global.LAYER_PLAYER_BULLET |
		Global.LAYER_ENEMY |
		Global.LAYER_ENEMY_PROJECTILE |
		Global.LAYER_SPAWNER
	)
	$Sprite2D.z_index = Global.Z_CRATES

func _physics_process(delta):
	if drop_motion.length() > 0.5:
		var collision = move_and_collide(drop_motion * delta)
		if collision:
			drop_motion = Vector2.ZERO
		else:
			drop_motion = drop_motion.move_toward(Vector2.ZERO, 300 * delta)


func pickup(player: Node):
	if player.is_vaulting:
		print("Player is vaulting, so not allowed to Crate_Static.pickup() even though we tried")
		return  # 🚫 Don't allow pickup while vaulting
		
	print("Crate_Static: pickup")
	# Disable this crate visually and physically
	sprite.visible = false
	collision_shape.call_deferred("set_disabled", true)
	set_physics_process(false)
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)

	# Instance and assign carried version
	var carried_crate = preload("res://scenes/carryables/Crate_Carried.tscn").instantiate()
	carried_crate.player = player
	# Set initial position based on player + offset
	var offset = carried_crate.get_offset_based_on_direction(player.last_move_direction)
	carried_crate.global_position = player.global_position + offset

	# Assign and add to scene
	player.carried_crate_instance = carried_crate
	get_tree().current_scene.call_deferred("add_child", carried_crate)

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
	initialize_drop_motion()


# Helps with dropping crate
func initialize_drop_motion():
	if has_meta("drop_motion"):
		drop_motion = get_meta("drop_motion")
		set_meta("drop_motion", null)  # clear it after reading
