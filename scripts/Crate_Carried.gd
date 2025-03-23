extends CharacterBody2D

var player: Node = null  # assigned on pickup

func _process(delta):
	if player:
		position = player.position + get_offset_based_on_direction(player.last_move_direction)
		update_z_index(player.last_move_direction)

func get_offset_based_on_direction(dir: Vector2) -> Vector2:
	var spacing = 10.0
	return dir.normalized() * spacing

func update_z_index(dir: Vector2):
	# Visually layer the crate based on direction
	if dir.y > 0:
		z_index = player.z_index + 1  # In front of player
	else:
		z_index = player.z_index - 1  # Behind player
