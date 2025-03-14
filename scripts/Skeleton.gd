extends "res://scripts/BaseEnemy.gd"  # Inherits from BaseEnemy

func _ready():
	health = 5  # Skeletons are tougher than Ghosts
	speed = 80.0  # Skeletons move slower

func _process(delta):
	var sep_vector = get_separation_vector()
	
	# Print separation vector only when needed (for debugging)
	if sep_vector.length() > 0:
		print(name, " Separation Vector:", sep_vector)

	move_towards_player(delta)

func move_towards_player(delta):
	if player:
		var direction = (player.global_position - global_position).normalized()
		var sep_vector = get_separation_vector()

		velocity = direction * speed + sep_vector * separation_strength  # Combine movement and separation

		# Check if a wall is in front and try to avoid it
		if raycast_forward.is_colliding():
			print(name, " is in wall avoidance mode!")  # Debugging
			avoid_wall()  # Try to navigate around the wall

		move_and_slide()

func avoid_wall():
	# Check if we can go left or right
	var can_go_left = not raycast_left.is_colliding()
	var can_go_right = not raycast_right.is_colliding()

	var separation_force = get_separation_vector() * separation_strength  # Apply separation

	if can_go_left and can_go_right:
		velocity = Vector2.RIGHT.rotated(randf_range(0, TAU)) * speed + separation_force  # Random left/right
	elif can_go_left:
		velocity = Vector2.LEFT * speed + separation_force
	elif can_go_right:
		velocity = Vector2.RIGHT * speed + separation_force
	else:
		velocity = -velocity + separation_force  # Reverse direction if stuck

	move_and_slide()
