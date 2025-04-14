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
			player.vault_over_crate(global_position, player.last_move_direction)
			# 🛑 Immediately disable this crate so it doesn’t keep colliding
			set_physics_process(false)
			visible = false

		
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
