extends "res://scripts/enemies/BaseEnemy.gd"

func update_navigation(delta: float) -> void:
	if target_node:
		var direction = target_node.global_position - global_position
		if direction.length() > 1:
			var offset = Vector2(randf() - 0.5, randf() - 0.5) * 10
			velocity = (direction + offset).normalized() * speed
			move_and_slide()

func reset() -> void:
	super.reset()
	# No Ghost-specific timers or states to reset (yet)
