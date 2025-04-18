extends Node

@export var crate: CharacterBody2D
@export var detection_radius := 18.0
@export var log_duration := 0.2  # Seconds of debug logging when active

var logging_time := 0.0

func _physics_process(delta):
	if not crate:
		return
	
	var player = crate.get("player")
	if not player:
		return

	var motion = player.global_position + crate.get_offset_based_on_direction(player.last_move_direction) - crate.global_position
	var collision = crate.move_and_collide(motion)

	if collision:
		logging_time = log_duration
	else:
		# Fallback: check proximity to barrels
		for barrel in get_tree().get_nodes_in_group("barrels_static"):
			var dist = crate.global_position.distance_to(barrel.global_position)
			if dist < detection_radius:
				logging_time = log_duration
				break

	if logging_time > 0.0:
		logging_time -= delta
