extends RigidBody2D

var speed: float = Global.SKELETON_SHOOTER.ARROW_SPEED
var damage: int = Global.SKELETON_SHOOTER.ARROW_DAMAGE
var lifespan: float = Global.SKELETON_SHOOTER.ARROW_LIFESPAN

var direction = Vector2.ZERO
var bounce_cooldown := 0.0
var crate_collision_disabled := false

func _ready():
	contact_monitor = true
	max_contacts_reported = 1
	gravity_scale = 0
	linear_damp = 0
	angular_damp = 1000  # Prevents spinning
	linear_velocity = direction.normalized() * speed
	rotation = direction.angle()

	collision_layer = Global.LAYER_ENEMY_PROJECTILE
	collision_mask = (
		Global.LAYER_PLAYER |
		Global.LAYER_WALL |
		Global.LAYER_CRATE | 
		Global.LAYER_BARREL
	)
	$Sprite2D.z_index = Global.Z_FLYING_ENEMIES

	add_to_group("enemy_projectiles")

	await get_tree().create_timer(lifespan).timeout
	queue_free()

	# This causes new arrow to tell all Barrel_Rolled instances to not collide with this new Arrow
	# TODO that seems hackish, maybe we can do something better in the future
	# Optional: Wrap it in a signal for scalability
	# If you want to future-proof this, you can emit a "spawned" signal from EnemyArrow and 
	# have Barrel_Rolled listen and add the exception that way 
	# but for now, the solution above is simple and effective.
	# LATER * See if we can improve the way Barrel_Rolled avoids getting momentum added by Arrow.
	# https://docs.google.com/document/d/1KjGnxEASNrOPFPeJFELTTnXAFlhKHpkn_EUkjkWbndc/edit?usp=drive_link

	for body in get_tree().get_nodes_in_group("barrels_rolled"):
		body.add_collision_exception_with(self)

func _process(delta):
	if linear_velocity.length() > 0:
		rotation = linear_velocity.angle()

	if crate_collision_disabled:
		bounce_cooldown -= delta
		if bounce_cooldown <= 0.0:
			collision_mask |= Global.LAYER_CRATE
			crate_collision_disabled = false

func _integrate_forces(state):
	if crate_collision_disabled:
		return

	for i in range(state.get_contact_count()):
		var collider = state.get_contact_collider_object(i)
		if collider and collider.is_in_group("crates"):
			var impact_vector = (global_position - collider.global_position).normalized()

			# Snap to nearest 45° or 90° direction
			var abs_x = abs(impact_vector.x)
			var abs_y = abs(impact_vector.y)

			if abs(abs_x - abs_y) < 0.2:
				# Close to diagonal → snap to 45°
				direction = Vector2(sign(impact_vector.x), sign(impact_vector.y)).normalized()
			elif abs_x > abs_y:
				# Snap to horizontal
				direction = Vector2(sign(impact_vector.x), 0)
			else:
				# Snap to vertical
				direction = Vector2(0, sign(impact_vector.y))

			linear_velocity = direction * speed
			rotation = direction.angle()

			# Move arrow away from the crate to avoid re-collision
			global_position += direction * 4.0

			# Disable crate collisions temporarily
			collision_mask &= ~Global.LAYER_CRATE
			crate_collision_disabled = true
			bounce_cooldown = 0.2

			break
		elif collider and collider.is_in_group("barrels_rolled"):
			# Cancel physics interaction by removing any force/momentum transfer
			# This preserves the damage exchange in _on_body_entered()
			state.set_linear_velocity(linear_velocity)  # Re-assert current velocity
			state.set_angular_velocity(0)

func _on_body_entered(body):
	if body.is_in_group("player"):
		body.take_damage(damage)
		queue_free()
	elif body.is_in_group("walls"):
		queue_free()
	elif body.is_in_group("barrels"):
		body.take_damage(damage)
		# TODO we might exchange damage with arrow in case arrow gets more health in future
		queue_free()
		

	
	
	
