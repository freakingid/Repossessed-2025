extends RigidBody2D

@export var speed: float = 150.0
@export var damage: int = 2
@export var lifespan: float = 3.0  # Time before the arrow disappears

var direction = Vector2.ZERO

func _ready():
	contact_monitor = true
	max_contacts_reported = 1
	add_to_group("enemy_projectiles")  # ✅ Add to correct group
	await get_tree().create_timer(lifespan).timeout
	queue_free()

func _integrate_forces(state):
	for i in range(state.get_contact_count()):
		var collider = state.get_contact_collider_object(i)
		var normal = state.get_contact_local_normal(i)
		
		if collider and collider.is_in_group("crates"):
			linear_velocity = linear_velocity.bounce(normal)

func _on_Timer_timeout():
	queue_free()  # Destroy the arrow after lifespan expires

func _on_body_entered(body):
	if body.is_in_group("crates"):
		return

	elif body.is_in_group("player"):
		body.take_damage(damage)
		queue_free()

	elif body.is_in_group("walls"):
		queue_free()
