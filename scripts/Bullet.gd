extends Area2D

@export var speed: float = 500.0
var direction = Vector2.ZERO

func _process(delta):
	position += direction * speed * delta

func _on_body_entered(body):
	print("Bullet collision detected with:", body.name, "| Groups:", body.get_groups())  # Debugging output

	if body.is_in_group("enemies"):
		print("Bullet hit an enemy!")
		body.take_damage(1)
		queue_free()  # Destroy the bullet

	elif body.is_in_group("spawners"):
		print("Bullet hit a spawner!")
		body.take_damage(1)
		queue_free()  # Destroy the bullet
