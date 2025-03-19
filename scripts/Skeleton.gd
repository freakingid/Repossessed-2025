extends "res://scripts/BaseEnemy.gd"  # Inherits from BaseEnemy

@onready var raycast_forward = $RaycastForward
@onready var raycast_left = $RaycastLeft
@onready var raycast_right = $RaycastRight

var movement_attempts = [0, 30, 60, 90, 120, 150, 180, 210, 240, 270, 300, 330]  # Sequence of angles to try when blocked
var current_attempt = 0  # Which movement attempt we're on
var side_step_timer = 0.0  # How long to commit to the side-step
var side_step_duration = 1.00  # How many seconds to side-step before retrying forward movement
var new_direction: Vector2 = Vector2.ZERO  # ✅ Default direction to prevent `nil` errors

func _ready():
	super()  # Calls BaseEnemy.gd's _ready()
	health = 4  # Skeletons are tougher than Ghosts
	speed = 80.0  # Skeletons move slower
	score_value = 2
	damage = 2

func _process(delta):
	move_towards_player(delta)

func move_towards_player(delta):
	if player:
		var direction = (player.global_position - global_position).normalized()

		# ✅ Step 1: Check if the player is in sight using the raycast
		raycast_forward.target_position = to_local(player.global_position)  # Point raycast at the player
		raycast_forward.force_raycast_update()  # Ensure it's checking instantly
		var can_see_player = raycast_forward.is_colliding() and raycast_forward.get_collider() == player

		if can_see_player:
			# ✅ If we see the player, move directly toward them
			current_attempt = 0
			side_step_timer = 0
			new_direction = direction
		else:
			# ✅ If we can't see the player OR we're already side-stepping
			if side_step_timer > 0:
				side_step_timer -= delta
				direction = new_direction  # Continue with the last decided direction
			else:
				# ✅ Start a new side-step attempt if the player is lost
				current_attempt = (current_attempt + 1) % movement_attempts.size()
				side_step_timer = randf_range(1.0, 5.0)  # Random side-step duration between 1 and 5 seconds
				new_direction = direction.rotated(deg_to_rad(movement_attempts[current_attempt]))

		velocity = direction * speed
		move_and_slide()
