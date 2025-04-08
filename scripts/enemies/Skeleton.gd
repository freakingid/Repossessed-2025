extends BaseEnemy

var sidestep_direction := Vector2.ZERO
var sidestep_distance := 16

func _ready():
	# Skeleton stats
	speed = Global.SKELETON.SPEED
	health = Global.SKELETON.HEALTH
	damage = Global.SKELETON.DAMAGE
	score_value = Global.SKELETON.SCORE
	is_flying = false

	super._ready()

func update_navigation(delta):
	if is_dead:
		return

	if has_line_of_sight():
		sidestep_direction = Vector2.ZERO
		move_directly_to_player(delta)
	else:
		if sidestep_direction == Vector2.ZERO:
			sidestep_direction = choose_sidestep_direction()

		var side_target = global_position + sidestep_direction * sidestep_distance
		var direction = (side_target - global_position).normalized()
		velocity = direction * speed

		if is_path_blocked(direction):
			sidestep_direction = -sidestep_direction

		move_and_slide()

func has_line_of_sight() -> bool:
	var result = get_world_2d().direct_space_state.intersect_ray(
		PhysicsRayQueryParameters2D.create(global_position, get_player_global_position())
	)
	return result.is_empty()

func choose_sidestep_direction() -> Vector2:
	var right = Vector2.RIGHT.rotated((get_player_global_position() - global_position).angle())
	var left = -right

	if not is_path_blocked(right):
		return right
	elif not is_path_blocked(left):
		return left
	else:
		return Vector2.ZERO

func is_path_blocked(direction: Vector2) -> bool:
	var from = global_position
	var to = from + direction.normalized() * sidestep_distance
	var result = get_world_2d().direct_space_state.intersect_ray(
		PhysicsRayQueryParameters2D.create(from, to)
	)
	return not result.is_empty()
