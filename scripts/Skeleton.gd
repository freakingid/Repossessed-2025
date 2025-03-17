extends "res://scripts/BaseEnemy.gd"  # Inherits from BaseEnemy

@export var score_value: int = 1

func _ready():
	super()  # Calls BaseEnemy.gd's _ready()
	health = 4  # Skeletons are tougher than Ghosts
	speed = 80.0  # Skeletons move slower

func _process(delta):
	move_towards_player(delta)

func move_towards_player(delta):
	if player:
		var direction = (player.global_position - global_position).normalized()
		var sep_vector = get_separation_vector()

		velocity = direction * speed + sep_vector * separation_strength  # Combine movement and separation

		# Check if a wall is in front and try to avoid it
		if raycast_forward.is_colliding():
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
