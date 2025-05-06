extends "res://scripts/enemies/BaseEnemy.gd"

@onready var ghost_startled_sfx = [
	preload("res://assets/audio/sfx/ghost-startled/ghost-startled-001.ogg"),
	preload("res://assets/audio/sfx/ghost-startled/ghost-startled-002.ogg"),
	preload("res://assets/audio/sfx/ghost-startled/ghost-startled-003.ogg")
]

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
				# Play ghost startled sound
				SoundManager.play_sfx(ghost_startled_sfx.pick_random(), global_position, true)
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

# Ghost pretty much dies on 1 hit, so playing a sound for take_damage does not make sense
#func take_damage(_amount: int) -> void:
	#SoundManager.play_sfx(preload("res://assets/audio/sfx/ghost-hit/ghost-hit-001.mp3"), self.global_position, true)
	#super.take_damage(_amount)
	
func die():
	SoundManager.play_sfx(preload("res://assets/audio/sfx/ghost-die/ghost-die-002.ogg"), self.global_position, true)
	super.die()


func reset() -> void:
	super.reset()
	# No Ghost-specific timers or states to reset (yet)
