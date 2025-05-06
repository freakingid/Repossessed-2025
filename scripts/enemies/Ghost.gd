extends "res://scripts/enemies/BaseEnemy.gd"

#func update_navigation_OLD(_delta: float) -> void:
	#if target_node:
		#var direction = target_node.global_position - global_position
		#if direction.length() > 1:
			#var offset = Vector2(randf() - 0.5, randf() - 0.5) * 10
			#velocity = (direction + offset).normalized() * speed
			#move_and_slide()

func update_navigation(delta: float) -> void:
	if motion_type == MotionType.AUTO_SWITCH:
		if active_motion_mode == MotionType.MOVE_TO_PLAYER:
			chase_timer -= delta
			if chase_timer <= 0.0 and not (can_hear_player() or can_see_player()):
				active_motion_mode = MotionType.CLOCKWISE_PATROL
				# Remove sprite tint
				if sprite:
					sprite.modulate = Color(1, 1, 1)  # normal
		else:
			if can_hear_player() and can_see_player():
				active_motion_mode = MotionType.MOVE_TO_PLAYER
				chase_timer = chase_cooldown
				# Tint the enemy sprite red
				if sprite:
					sprite.modulate = Color(1.0, 0.5, 0.5)  # light red tint

	else:
		active_motion_mode = motion_type

	match active_motion_mode:
		MotionType.MOVE_TO_PLAYER:
			if target_node:
				var direction = target_node.global_position - global_position
				if direction.length() > 1:
					var offset = Vector2(randf() - 0.5, randf() - 0.5) * 10
					velocity = (direction + offset).normalized() * speed * 1.25 # move faster than normal when pursuing
					move_and_slide()
		MotionType.CLOCKWISE_PATROL:
			update_patrol_motion(delta)


func reset() -> void:
	super.reset()
	# No Ghost-specific timers or states to reset (yet)
