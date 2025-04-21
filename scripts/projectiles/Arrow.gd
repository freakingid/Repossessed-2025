extends KinematicMover

@export var speed: float = Global.SKELETON_SHOOTER.ARROW_SPEED
@export var damage: int = Global.SKELETON_SHOOTER.ARROW_DAMAGE
@export var lifetime: float = Global.SKELETON_SHOOTER.ARROW_LIFESPAN

var time_alive: float = 0.0

func _ready():
	# Face the direction of motion
	motion_velocity = Vector2.RIGHT.rotated(rotation) * speed

func _physics_process(delta: float) -> void:
	time_alive += delta
	if time_alive > lifetime:
		queue_free()
		return

	var collision = move_and_collide(motion_velocity * delta)
	if collision:
		var collider = collision.get_collider()

		if collider.is_in_group("player"):
			if collider.has_method("take_damage"):
				collider.take_damage(damage)
			queue_free()
			return

		# Optional: Stop when hitting anything else (walls, crates)
		queue_free()
