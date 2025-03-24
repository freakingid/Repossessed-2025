extends RigidBody2D

@export var base_speed: float = 250.0
@export var damage: int = 1  # How much damage the bullet deals
@export var health: int = 1  # How much damage the bullet can take before being destroyed
@export var bounce_shot: bool = false  # Determines if bullets should bounce
@export var lifespan: float = 1.5  # Bullet will last for 2 seconds

var direction = Vector2.ZERO
var speed = base_speed

func _ready():
	contact_monitor = true
	max_contacts_reported = 1
	gravity_scale = 0  # top-down game
	linear_velocity = direction.normalized() * speed

	# Start a timer to delete the bullet after lifespan duration
	await get_tree().create_timer(lifespan).timeout
	queue_free()

func _integrate_forces(state):
	for i in range(state.get_contact_count()):
		var collider = state.get_contact_collider_object(i)
		var normal = state.get_contact_local_normal(i)

		if collider and collider.is_in_group("enemies"):
			linear_velocity = linear_velocity.bounce(normal)

# What happens when a bullet hits a wall
func _on_body_entered(body):
	if body.is_in_group("crates"):
		return  # Crates are handled in _integrate_forces()

	elif body.is_in_group("walls"):
		if bounce_shot:
			var collision_normal = (global_position - body.global_position).normalized()
			direction = direction.reflect(collision_normal)
		else:
			queue_free()  # Destroy the bullet if no bounce ability

	# Do we really want to add this? The collision is handled in the enemy currently 
	elif body.is_in_group("enemies"):
		body.take_damage(damage)  # Assumes enemy has take_damage() method
		queue_free()

func take_damage(amount):
	health -= amount
	if health <= 0:
		queue_free()  # ✅ Bullet disappears
