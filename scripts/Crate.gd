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
	# ✅ Push enemies away when they collide with the crate
	if area.is_in_group("enemies") and not area.is_in_group("bats"):
		var push_direction = (area.global_position - global_position).normalized()
		area.position += push_direction * push_force

	# ✅ Ignore lobber explosives
	if area.is_in_group("lobber_explosives"):
		return

	# ✅ Bounce logic for projectiles
	if area.is_in_group("player_projectiles") or area.is_in_group("enemy_projectiles"):
		var delta = area.global_position - global_position
		var abs_x = abs(delta.x)
		var abs_y = abs(delta.y)

		# Determine side of impact (axis-aligned ricochet)
		if abs_x > abs_y:
			area.direction.x *= -1  # Flip horizontal direction
		else:
			area.direction.y *= -1  # Flip vertical direction

		# Optional: Normalize direction for consistency
		area.direction = area.direction.normalized()
		var projectile_sprite = area.get_node("Sprite2D")
		projectile_sprite.rotation = area.direction.angle()
		print("Bounce: new direction = ", area.direction)
		print("Rotation in degrees: ", rad_to_deg(area.direction.angle()))
		# Optional: Slight nudge to get it off the crate edge
		area.global_position += area.direction * 2
