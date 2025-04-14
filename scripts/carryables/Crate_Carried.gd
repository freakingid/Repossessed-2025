extends CharacterBody2D

var player: Node = null  # assigned on pickup

func _ready():
	collision_layer = Global.LAYER_CRATE
	collision_mask = (
		Global.LAYER_ENEMY |
		Global.LAYER_SPAWNER |
		Global.LAYER_WALL |
		Global.LAYER_ENEMY_PROJECTILE |
		Global.LAYER_CRATE
	)

func _physics_process(delta):
	if player:
		var target_pos = player.position + get_offset_based_on_direction(player.last_move_direction)
		var motion = target_pos - global_position
		var collision = move_and_collide(motion)

		if collision:
			# Optional: drop the crate or block player movement
			print("Crate hit something: ", collision.get_collider())
		
		update_z_index(player.last_move_direction)

func get_offset_based_on_direction(dir: Vector2) -> Vector2:
	var spacing = 15.0
	return dir.normalized() * spacing

func update_z_index(dir: Vector2):
	# Visually layer the crate based on direction
	if dir.y > 0:
		# z_index = player.z_index + 1  # In front of player
		$Sprite2D.z_index = Global.Z_CARRIED_CRATE_IN_FRONT
	else:
		# z_index = player.z_index - 1  # Behind player
		$Sprite2D.z_index = Global.Z_CARRIED_CRATE_BEHIND
