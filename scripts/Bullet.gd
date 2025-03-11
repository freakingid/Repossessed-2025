extends Area2D

@export var speed: float = 500.0
@export var bounce_shot: bool = false  # Determines if bullets should bounce
var direction = Vector2.ZERO

func _process(delta):
	position += direction * speed * delta

func _on_body_entered(body):
	print("Bullet collision detected with:", body.name, "| Groups:", body.get_groups())  # Debugging output
	if body.is_in_group("walls"):
		print("Bullet hit a wall!")
		if bounce_shot:
			# Reverse direction on bounce
			direction = direction.reflect(Vector2(1, 1))
		else:
			queue_free()  # Destroy the bullet if no bounce ability

	if body.is_in_group("enemies"):
		print("Bullet hit an enemy!")
		body.take_damage(1)
		queue_free()  # Destroy the bullet

	elif body.is_in_group("spawners"):
		print("Bullet hit a spawner!")
		body.take_damage(1)
		queue_free()  # Destroy the bullet
