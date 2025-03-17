extends "res://scripts/BaseEnemy.gd"  # Inherits from BaseEnemy

@onready var raycast_forward = $RaycastForward
@onready var raycast_left = $RaycastLeft
@onready var raycast_right = $RaycastRight

var movement_attempts = [0, 30, 60, 90, 120, 150, 180, 210, 240, 270, 300, 330]  # Sequence of angles to try when blocked
var current_attempt = 0  # Which movement attempt we're on
var side_step_timer = 0.0  # How long to commit to the side-step
var side_step_duration = 3.00  # How many seconds to side-step before retrying forward movement

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

		# ✅ If we're currently side-stepping, continue in that adjusted direction
		if side_step_timer > 0:
			side_step_timer -= delta
			direction = direction.rotated(deg_to_rad(movement_attempts[current_attempt]))
		else:
			# ✅ Try moving toward the player normally
			if raycast_forward.is_colliding():
				# ✅ If blocked, start the side-step process
				current_attempt = (current_attempt + 1) % movement_attempts.size()
				side_step_timer = side_step_duration  # Reset the timer
				direction = direction.rotated(deg_to_rad(movement_attempts[current_attempt]))
			else:
				# ✅ If no collision, reset the movement pattern
				current_attempt = 0  # Go back to direct movement
				side_step_timer = 0

		velocity = direction * speed
		move_and_slide()
