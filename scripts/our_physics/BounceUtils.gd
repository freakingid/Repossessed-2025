# BounceUtils.gd
extends Node

## Purpose:
# - Provides bounce vector calculations
# - Reusable by any mover (bullet, barrel, shrapnel)
# - May expand later to include angle clamping, dampening, etc.

class_name BounceUtils

static func calculate_bounce(velocity: Vector2, normal: Vector2) -> Vector2:
	# Reflect the velocity vector off the surface normal
	return velocity.bounce(normal)

# Optional helper: angle-based bounce (can add later)
static func reflect_angle(incoming_angle: float, surface_angle: float) -> float:
	# Bounce angle = 2 * surface_angle - incoming_angle
	return 2.0 * surface_angle - incoming_angle
