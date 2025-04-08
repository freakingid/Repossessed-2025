extends RigidBody2D

var speed: float = Global.PLAYER.BULLET_SPEED
var damage: int = Global.PLAYER.BULLET_DAMAGE
var health: int = Global.PLAYER.BULLET_HEALTH
var lifespan: float = Global.PLAYER.BULLET_LIFESPAN

var direction = Vector2.ZERO
var bounce_shot: bool = false  # Determines if bullets should bounce

func _ready():
	collision_layer = Global.LAYER_PLAYER_BULLET
	collision_mask = (
		Global.LAYER_ENEMY | 
		Global.LAYER_SPAWNER | 
		Global.LAYER_WALL | 
		Global.LAYER_CRATE |
		Global.LAYER_BARREL  # Include if not already set
	)

	contact_monitor = true
	max_contacts_reported = 1
	custom_integrator = true  # ✅ Prevent bullets from pushing other bodies
	$Sprite2D.z_index = Global.Z_PLAYER_AND_CRATES

	mass = 0.01
	gravity_scale = 0
	linear_damp = 0
	angular_velocity = 0
	angular_damp = 100

	var mat := PhysicsMaterial.new()
	if bounce_shot:
		mat.bounce = 0.4
	else:
		mat.bounce = 0.0
	mat.friction = 0.0
	physics_material_override = mat

	# Bullet lifespan timer
	await get_tree().create_timer(lifespan).timeout
	queue_free()

# ✅ Manual velocity update to avoid Godot applying physics impulses
func _integrate_forces(state: PhysicsDirectBodyState2D):
	var new_velocity = direction.normalized() * speed

	for i in range(state.get_contact_count()):
		var collider = state.get_contact_collider_object(i)
		if not collider:
			continue

		# 💥 Skip barrels — handled in _on_body_entered
		if collider.is_in_group("barrels_static") or collider.is_in_group("barrels_rolled") or collider.is_in_group("barrels_carried"):
			continue

		# ✅ Bounce off crates — always, even for non-bounce bullets
		if collider.is_in_group("crates_static") or collider.is_in_group("crates_carried"):
			var crate_center = collider.global_position
			var to_crate = crate_center.direction_to(global_position)
			direction = get_corner_bounce_direction(to_crate)
			new_velocity = direction * speed
			global_position += direction * 4.0  # Prevent sticking
			break

		elif bounce_shot and collider.is_in_group("walls"):
			var normal = state.get_contact_local_normal(i)
			direction = direction.bounce(normal).normalized()
			new_velocity = direction * speed
			global_position += direction * 4.0
			break

	state.linear_velocity = new_velocity




func get_corner_bounce_direction(to_crate: Vector2) -> Vector2:
	var dirs = [
		Vector2(1, 1), Vector2(-1, 1),
		Vector2(-1, -1), Vector2(1, -1)
	]

	var best_dir = dirs[0]
	var best_dot = -1.0

	for d in dirs:
		var dot = d.normalized().dot(to_crate.normalized())
		if dot > best_dot:
			best_dot = dot
			best_dir = d

	return best_dir.normalized()

func get_opposite_bounce_direction(dir: Vector2) -> Vector2:
	var directions = [
		Vector2(1, 0), Vector2(1, 1).normalized(),
		Vector2(0, 1), Vector2(-1, 1).normalized(),
		Vector2(-1, 0), Vector2(-1, -1).normalized(),
		Vector2(0, -1), Vector2(1, -1).normalized()
	]

	var best_dir = directions[0]
	var best_dot = -1.0

	for d in directions:
		var dot = d.dot(dir.normalized())
		if dot > best_dot:
			best_dot = dot
			best_dir = d

	return -best_dir



func get_snapped_reflection(velocity: Vector2, normal: Vector2) -> Vector2:
	var reflected = velocity.reflect(normal).normalized()
	var directions = [
		Vector2(1, 0), Vector2(-1, 0),
		Vector2(0, 1), Vector2(0, -1),
		Vector2(1, 1).normalized(), Vector2(-1, 1).normalized(),
		Vector2(1, -1).normalized(), Vector2(-1, -1).normalized()
	]

	var best_dir = directions[0]
	var best_dot = -1.0
	for dir in directions:
		var dot = reflected.dot(dir)
		if dot > best_dot:
			best_dot = dot
			best_dir = dir

	return best_dir


# Handle collision events
func _on_body_entered(body):
	if (
		body.is_in_group("barrels_static") or 
		body.is_in_group("barrels_rolled") or 
		body.is_in_group("barrels_carried")
	):
		body.take_damage(damage)
		queue_free()
	
	elif body.is_in_group("walls"):
		if not bounce_shot:
			queue_free()  # Non-bounce bullets die on impact

	elif body.is_in_group("enemies"):
		body.take_damage(damage)
		queue_free()

	elif body.is_in_group("spawners"):
		body.take_damage(damage)
		queue_free()

func take_damage(amount):
	health -= amount
	if health <= 0:
		queue_free()
