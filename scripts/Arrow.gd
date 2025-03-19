extends Area2D

@export var speed: float = 300.0
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
	if body.is_in_group("player"):  # ✅ Checks if it hit the player
		body.take_damage(damage)  # ✅ Apply damage
		queue_free()  # ✅ Remove arrow after hitting the player
	elif body.is_in_group("walls"):  # ✅ Arrow should disappear if it hits a wall
		queue_free()
