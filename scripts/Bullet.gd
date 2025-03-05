extends Area2D

@export var speed: float = 500.0
var direction = Vector2.ZERO

func _process(delta):
	position += direction * speed * delta

func _on_body_entered(body):
	if body.is_in_group("enemies"):
		body.take_damage(1)
		queue_free()  # Destroy bullet upon hit
