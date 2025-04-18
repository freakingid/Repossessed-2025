extends CharacterBody2D

var player: Node = null  # assigned on pickup

func _ready():
	collision_layer = Global.LAYER_CRATE
	collision_mask = (
		Global.LAYER_WALL |
		Global.LAYER_SPAWNER |
		Global.LAYER_CRATE |
		Global.LAYER_BARREL |
		Global.LAYER_ENEMY |
		Global.LAYER_ENEMY_PROJECTILE
	)
	$BarrelContactSensor.collision_layer = Global.LAYER_CRATE
	$BarrelContactSensor.collision_mask = Global.LAYER_BARREL
	$BarrelContactSensor.body_entered.connect(_on_barrel_sensor_body_entered)

func _on_barrel_sensor_body_entered(body):
	if body.is_in_group("barrels_static"):
		handle_collision(body, player.last_move_direction.normalized() * 100)

func _physics_process(_delta):
	if player:
		var target_pos = player.global_position + get_offset_based_on_direction(player.last_move_direction)
		var motion = target_pos - global_position

		# Optional smoothing to ease motion
		motion = motion.lerp(Vector2.ZERO, 0.2)

		if motion.length() > 1.0:
			var result = move_and_collide(motion.normalized() * min(motion.length(), 5.0), false, 0.05)

			if result:
				handle_collision(result.get_collider(), motion)
			else:
				check_fallback_barrel_contact(motion.normalized())

func handle_collision(collider, motion_vector):
	if collider and collider.is_in_group("barrels_static"):
		var rolled = preload("res://scenes/carryables/Barrel_Rolled.tscn").instantiate()
		rolled.global_position = collider.global_position
		rolled.linear_velocity = motion_vector.normalized() * 100
		get_parent().call_deferred("add_child", rolled)
		collider.call_deferred("queue_free")

func check_fallback_barrel_contact(motion_vector):
	for barrel in get_tree().get_nodes_in_group("barrels_static"):
		if global_position.distance_to(barrel.global_position) < 14.0:
			print("Fallback contact: Converting Barrel_Static to Barrel_Rolled")
			handle_collision(barrel, motion_vector)
			break

func get_offset_based_on_direction(dir: Vector2) -> Vector2:
	var spacing = 15.0
	return dir.normalized() * spacing

func update_z_index(dir: Vector2):
	if dir.y > 0:
		$Sprite2D.z_index = Global.Z_CARRIED_CRATE_IN_FRONT
	else:
		$Sprite2D.z_index = Global.Z_CARRIED_CRATE_BEHIND

func flash_blocked_feedback():
	if has_node("Sprite2D"):
		var sprite = $Sprite2D
		sprite.modulate = Color(2, 0.3, 0.3, 0.5)
		await get_tree().create_timer(0.1).timeout
		sprite.modulate = Color(1, 1, 1, 1)
