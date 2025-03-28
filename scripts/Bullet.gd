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
	state.linear_velocity = direction.normalized() * speed

# Handle collision events
func _on_body_entered(body):
	if body.is_in_group("crates"):
		return  # Crates bounce handled separately if needed

	elif body.is_in_group("walls"):
		if bounce_shot:
			var collision_normal = (global_position - body.global_position).normalized()
			direction = direction.reflect(collision_normal)
		else:
			queue_free()

	elif body.is_in_group("enemies"):
		body.take_damage(damage)
		queue_free()

	elif body.is_in_group("spawners"):
		body.take_damage(damage)
		queue_free()

	elif body.is_in_group("barrels_rolled"):
		body.take_damage(damage)
		queue_free()

func take_damage(amount):
	health -= amount
	if health <= 0:
		queue_free()
