extends Area2D

@export var base_speed: float = 500.0
@export var damage: int = 1  # How much damage the bullet deals
@export var health: int = 1  # How much damage the bullet can take before being destroyed
@export var bounce_shot: bool = false  # Determines if bullets should bounce
@export var lifespan: float = 2.0  # Bullet will last for 2 seconds

var direction = Vector2.ZERO
var speed = base_speed

func _ready():
	# Start a timer to delete the bullet after lifespan duration
	await get_tree().create_timer(lifespan).timeout
	queue_free()

func _process(delta):
	position += direction * speed * delta

func _on_body_entered(body):
	if body.is_in_group("walls"):
		if bounce_shot:
			# Get the collision normal using the Bullet's position vs the Wall's position
			var collision_normal = (global_position - body.global_position).normalized()
			direction = direction.reflect(collision_normal)  # Reflect based on collision angle
		else:
			queue_free()  # Destroy the bullet if no bounce ability
