extends BaseEnemy

var sidestep_index := 0
var sidestep_angles := []
var direction_to_player := Vector2.ZERO
var last_clear_direction := Vector2.ZERO
var retry_timer := 0.0
const RETRY_COOLDOWN := 0.75
const MAX_ATTEMPTS := 24  # 15° * 24 = full 360° sweep
const ANGLE_STEP := 15

func _ready():
	# Skeleton stats
	speed = Global.SKELETON.SPEED
	health = Global.SKELETON.HEALTH
	damage = Global.SKELETON.DAMAGE
	score_value = Global.SKELETON.SCORE
	is_flying = false

	super._ready()

	sidestep_angles.clear()
	for i in MAX_ATTEMPTS:
		sidestep_angles.append(deg_to_rad(i * ANGLE_STEP))

func update_navigation(delta):
	if is_dead:
		return

	direction_to_player = get_player_global_position() - global_position

	# Always check for LOS first, every frame
	if has_line_of_sight():
		last_clear_direction = direction_to_player.normalized()
		velocity = last_clear_direction * speed
		move_and_slide()
		sidestep_index = 0
		return

	# If we had a valid direction and it's still good, use it
	if last_clear_direction != Vector2.ZERO and not is_path_blocked(last_clear_direction):
		velocity = last_clear_direction * speed
		move_and_slide()
		return

	# Try a new test direction (one per frame)
	if sidestep_index < sidestep_angles.size():
		var test_angle = sidestep_angles[sidestep_index]
		var test_direction = direction_to_player.rotated(test_angle).normalized()
		sidestep_index += 1

		if not is_path_blocked(test_direction):
			last_clear_direction = test_direction
			velocity = test_direction * speed
			move_and_slide()
			sidestep_index = 0
			return

	# No direction found this frame — stand still
	velocity = Vector2.ZERO

	retry_timer += delta
	if retry_timer >= RETRY_COOLDOWN:
		last_clear_direction = Vector2.ZERO
		sidestep_index = 0
		retry_timer = 0.0

func has_line_of_sight() -> bool:
	var player = get_tree().get_first_node_in_group(Global.GROUPS.PLAYER)
	if not player or not is_instance_valid(player):
		return false


	var query := PhysicsRayQueryParameters2D.new()
	query.from = global_position
	query.to = player.global_position
	query.exclude = [self]
	query.collide_with_bodies = true
	query.collide_with_areas = false

	var result = get_world_2d().direct_space_state.intersect_ray(query)

	if result and result.has("collider"):
		var collider = result["collider"]
		if collider == player:
			return true
		else:
			return false

	return true

func is_path_blocked(direction: Vector2) -> bool:
	var space_state = get_world_2d().direct_space_state
	var from = global_position
	var to = from + direction * 16
	var result = space_state.intersect_ray(
		PhysicsRayQueryParameters2D.create(from, to)
	)
	if not result.is_empty():
		var collider = result["collider"]
			# Blocked by wall or another enemy
		if collider and (collider.is_in_group(Global.GROUPS.STATIC_OBJECTS) or collider.is_in_group(Global.GROUPS.ENEMIES)):
			return true
	return false

func reset() -> void:
	super.reset()
	sidestep_index = 0
	sidestep_angles.clear()
	for i in MAX_ATTEMPTS:
		sidestep_angles.append(deg_to_rad(i * ANGLE_STEP))
	last_clear_direction = Vector2.ZERO
	retry_timer = 0.0
