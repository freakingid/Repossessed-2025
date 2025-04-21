# KinematicMover.gd
extends CharacterBody2D

## Purpose:
# - Handles velocity-based movement
# - Supports optional bounce behavior
# - Applies linear friction
# - Can be used as a base class for Bullet, Barrel_Rolled, etc.

class_name KinematicMover

# Use a unique name to avoid conflict with built-in CharacterBody2D.velocity
var motion_velocity: Vector2 = Vector2.ZERO

# Friction multiplier (0.0 = no friction, 1.0 = stop instantly)
@export var friction: float = 0.0

# Minimum speed to snap to zero
@export var velocity_snap_threshold: float = 5.0

func _physics_process(delta: float) -> void:
	move_with_velocity(delta)

func move_with_velocity(delta: float) -> void:
	# Apply friction
	if friction > 0.0 and motion_velocity.length() > 0.0:
		var friction_force = motion_velocity.normalized() * friction * delta * 100
		motion_velocity -= friction_force
		if motion_velocity.length() < velocity_snap_threshold:
			motion_velocity = Vector2.ZERO

	# Move and check collision
	var collision = move_and_collide(motion_velocity * delta)
	if collision:
		var collider = collision.get_collider()
		var bounce_normal = collision.get_normal()
		if should_bounce_off(collider):
			motion_velocity = BounceUtils.calculate_bounce(motion_velocity, bounce_normal)
			motion_velocity *= 0.9  # optional bounce dampening
		else:
			motion_velocity = Vector2.ZERO

func should_bounce_off(collider: Object) -> bool:
	# Customize this based on your needs
	return collider.is_in_group("walls") or collider.is_in_group("crates")
