extends RigidBody2D

# Default to Skeleton Shooter arrow stats
var speed := Global.SKELETON_SHOOTER.ARROW_SPEED
var damage := Global.SKELETON_SHOOTER.ARROW_DAMAGE
var lifespan := Global.SKELETON_SHOOTER.ARROW_LIFESPAN

func _ready():
	add_to_group(Global.GROUPS.ENEMY_PROJECTILES)
	add_to_group(Global.GROUPS.DAMAGING)
	add_to_group(Global.GROUPS.PROJECTILES)

	# Arrow self-destruct after time
	await get_tree().create_timer(lifespan).timeout
	if is_instance_valid(self):
		queue_free()

func _physics_process(delta):
	linear_velocity = transform.x * speed

func _on_body_entered(body):
	if body == null:
		return

	if body.is_in_group(Global.GROUPS.PLAYER):
		body.take_damage(damage)
		queue_free()
		return

	if body.is_in_group(Global.GROUPS.STATIC_OBJECTS):
		queue_free()
