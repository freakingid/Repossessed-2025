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
		var target_pos = player.global_position + get_offset_based_on_direction(player.last_move_direction)
		var motion = target_pos - global_position
		var collision = move_and_collide(motion)

		if collision and collision.get_collider().is_in_group("walls") and not player.is_vaulting:
			var vault_started = player.vault_over_crate(global_position, player.last_move_direction)
			if vault_started:
				set_physics_process(false)
				visible = false
			else:
				flash_blocked_feedback()
		
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

func flash_blocked_feedback():
	if has_node("Sprite2D"):  # or AnimatedSprite2D if you're using that
		var sprite = $Sprite2D
		sprite.modulate = Color(2, 0.3, 0.3)  # reddish flash
		await get_tree().create_timer(0.1).timeout
		sprite.modulate = Color(1, 1, 1)  # reset
