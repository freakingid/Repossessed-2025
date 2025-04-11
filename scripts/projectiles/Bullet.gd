extends RigidBody2D

var speed := Global.PLAYER.BULLET_SPEED
var damage := Global.PLAYER.BULLET_DAMAGE
var lifespan := Global.PLAYER.BULLET_LIFESPAN
var can_bounce := false
var max_bounces := 1
var bounces_remaining := 0
var direction: Vector2 = Vector2.ZERO

func _ready():
	add_to_group(Global.GROUPS.PLAYER_PROJECTILES)
	add_to_group(Global.GROUPS.DAMAGING)
	add_to_group(Global.GROUPS.PROJECTILES)
	
	contact_monitor = true
	max_contacts_reported = 1

	bounces_remaining = max_bounces if can_bounce else 0

	# Bullet self-destruct after time
	await get_tree().create_timer(lifespan).timeout
	if is_instance_valid(self):
		queue_free()

func _physics_process(delta):
	linear_velocity = direction.normalized() * speed

func _on_body_entered(body):
	print("Bullet._on_body_entered with body: ", body.name)
	if body == null:
		return

	var target = body

	# Forward to parent if needed
	if not body.has_method("take_damage") and body.get_parent() and body.get_parent().has_method("take_damage"):
		target = body.get_parent()

	if target.is_in_group(Global.GROUPS.DAMAGEABLE):
		target.take_damage(damage)
		queue_free()
		return

	if body.is_in_group(Global.GROUPS.STATIC_OBJECTS) and can_bounce and bounces_remaining > 0:
		bounce_off(body)
		bounces_remaining -= 1
	else:
		queue_free()

func bounce_off(body):
	var collision = move_and_collide(linear_velocity * get_physics_process_delta_time())
	if collision:
		var normal = collision.get_normal()
		linear_velocity = linear_velocity.bounce(normal)
