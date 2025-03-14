extends "res://scripts/BaseEnemy.gd"  # Inherits from BaseEnemy

@onready var raycast_left = $RaycastLeft  # Detects walls to the left
@onready var raycast_right = $RaycastRight  # Detects walls to the right
@onready var raycast_forward = $RaycastForward  # Checks directly ahead

var avoiding_wall = false  # Tracks if we're actively avoiding a wall

func _ready():
	health = 5  # Skeletons are tougher than Ghosts
	speed = 80.0  # Skeletons move slower

func _process(delta):
	if avoiding_wall:
		avoid_wall_movement()
	else:
		move_towards_player(delta)

func move_towards_player(delta):
	if player:
		var direction = (player.global_position - global_position).normalized()

		# Check if a wall is in front
		if raycast_forward.is_colliding():
			print("Skeleton detected wall ahead!")
			avoid_wall()  # Try to navigate around the wall
		else:
			velocity = direction * speed
			move_and_slide()

func avoid_wall():
	avoiding_wall = true

	# Check if we can go left or right
	var can_go_left = not raycast_left.is_colliding()
	var can_go_right = not raycast_right.is_colliding()

	if can_go_left and can_go_right:
		velocity = Vector2.RIGHT.rotated(randf_range(0, TAU)) * speed  # Random direction
	elif can_go_left:
		velocity = Vector2.LEFT * speed
	elif can_go_right:
		velocity = Vector2.RIGHT * speed
	else:
		velocity = -velocity  # Reverse direction if no path

	move_and_slide()

func avoid_wall_movement():
	# Keep moving in the new direction for a short time before trying again
	move_and_slide()
	await get_tree().create_timer(0.5).timeout
	avoiding_wall = false  # Resume normal movement
