extends Area2D

@export var speed: float = 150.0
@export var damage: int = 2
@export var lifespan: float = 3.0  # Time before the arrow disappears

var direction = Vector2.ZERO

func _ready():
	add_to_group("enemy_projectiles")  # ✅ Add to correct group
	$Timer.wait_time = lifespan
	$Timer.start()

	# ✅ Rotate the arrow to face the direction it's traveling
	rotation = direction.angle()

func _process(delta):
	position += direction * speed * delta  # Move in a straight line

func _on_Timer_timeout():
	queue_free()  # Destroy the arrow after lifespan expires

func _on_body_entered(body):
	# ✅ Normal behavior if hitting Player or Wall
	if body.is_in_group("player"):
		body.take_damage(damage)
		queue_free()

	elif body.is_in_group("walls"):
		queue_free()
