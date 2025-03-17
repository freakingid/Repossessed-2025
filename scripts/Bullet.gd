extends Area2D

@export var base_speed: float = 500.0
@export var damage: int = 1  # How much damage the bullet deals
@export var health: int = 1  # How much damage the bullet can take before being destroyed
@export var bounce_shot: bool = false  # Determines if bullets should bounce
@export var lifespan: float = 2.0  # Bullet will last for 2 seconds

var direction = Vector2.ZERO
var speed = base_speed

func _ready():
	monitoring = true  # ✅ Ensure it detects collisions
	# connect("body_entered", _on_body_entered)  # ✅ Listen for collisions
	# Start a timer to delete the bullet after lifespan duration
	await get_tree().create_timer(lifespan).timeout
	queue_free()

func _process(delta):
	position += direction * speed * delta

# What happens when a bullet hits a wall
func _on_body_entered(body):
	if body.is_in_group("walls"):
		if bounce_shot:
			var collision_normal = (global_position - body.global_position).normalized()
			direction = direction.reflect(collision_normal)
		else:
			queue_free()  # Destroy the bullet if no bounce ability

	elif body.is_in_group("enemies"):
		body.take_damage(damage)  # ✅ Enemy takes damage
		take_damage(body.get_bullet_resistance())  # ✅ Bullet takes damage from enemy

		if health <= 0:
			queue_free()  # ✅ Bullet disappears

func take_damage(amount):
	health -= amount
