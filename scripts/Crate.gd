extends CharacterBody2D

@export var push_force: float = 8.0  # How strongly enemies get pushed away

var is_carried: bool = false
var player: Node = null

func _process(delta):
	if is_carried and player:
		var dir = player.last_move_direction.normalized()
		var carry_offset = dir * 12  # tweak distance if needed
		global_position = player.global_position + carry_offset

		# Adjust Z-index for layering
		if dir.y > 0.5:  # Moving down → crate in front
			z_index = player.z_index + 1
		elif dir.y < -0.5:  # Moving up → crate behind
			z_index = player.z_index - 1
		else:
			z_index = player.z_index  # Left/right/diagonal → neutral layering

func _physics_process(delta):
	if !is_carried:
		move_and_slide()  # Keeps physics active for collision response

func pickup(player_ref):
	if not is_carried:
		is_carried = true
		player = player_ref  # Store reference to player

func drop():
	if is_carried:
		is_carried = false
		player = null

func _on_Area2D_area_entered(area):
	# ✅ Lobber explosives should NOT be affected by crates
	if area.is_in_group("lobber_explosives"):
		return

	# ✅ Reflect player bullets
	if area.is_in_group("player_projectiles"):
		var bounce_direction = (area.global_position - global_position).normalized()
		bounce_direction += Vector2(randf_range(-0.1, 0.1), randf_range(-0.1, 0.1)).normalized() * 0.1
		area.direction = area.direction.reflect(bounce_direction.normalized())

	# ✅ Reflect enemy bullets
	if area.is_in_group("enemy_projectiles"):
		var bounce_direction = (area.global_position - global_position).normalized()
		bounce_direction += Vector2(randf_range(-0.1, 0.1), randf_range(-0.1, 0.1)).normalized() * 0.1
		area.direction = area.direction.reflect(bounce_direction.normalized())

	# ✅ Push enemies away when they collide with the crate
	if area.is_in_group("enemies") and not area.is_in_group("bats"):
		var push_direction = (area.global_position - global_position).normalized()
		area.position += push_direction * push_force
