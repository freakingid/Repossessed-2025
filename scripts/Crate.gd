extends CharacterBody2D

@export var push_force: float = 8.0  # How strongly enemies get pushed away

var is_carried: bool = false
var player: Node = null

func _process(delta):
	if is_carried and player:
		# Follow the player while carried
		position = player.position + Vector2(0, -16)

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

	# ✅ Reflect player bullets
	if area.is_in_group("player_projectiles"):
		var bounce_direction = (area.global_position - global_position).normalized()
		area.direction = area.direction.reflect(bounce_direction)

	# ✅ Reflect enemy bullets
	if area.is_in_group("enemy_projectiles"):
		var bounce_direction = (area.global_position - global_position).normalized()
		area.direction = area.direction.reflect(bounce_direction)

	# ✅ Lobber explosives should NOT be affected by crates
	if area.is_in_group("lobber_explosives"):
		return
