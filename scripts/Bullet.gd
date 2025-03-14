extends Area2D

@export var base_speed: float = 500.0
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
			# Reverse direction on bounce (this might need tweaking for better physics)
			direction = direction.reflect(Vector2(1, 1))
		else:
			queue_free()  # Destroy the bullet if no bounce ability

	elif body.is_in_group("enemies"):
		body.take_damage(1)
		queue_free()  # Destroy the bullet

	elif body.is_in_group("spawners"):
		body.take_damage(1)
		queue_free()  # Destroy the bullet
