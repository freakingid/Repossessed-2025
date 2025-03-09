extends Area2D

@export var speed: float = 500.0
var direction = Vector2.ZERO

func _process(delta):
	position += direction * speed * delta

func _on_body_entered(body):
	print("Bullet collision detected with:", body.name)  # Debugging output

	if body.is_in_group("enemies"):
		print("Bullet hit:", body.name)  # Debugging
		body.take_damage(1)  # Ghost should lose health
		queue_free()  # Destroy the bullet on impact
