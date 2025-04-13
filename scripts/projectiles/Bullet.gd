extends RigidBody2D

var speed := Global.PLAYER.BULLET_SPEED
var damage := Global.PLAYER.BULLET_DAMAGE
var lifespan := Global.PLAYER.BULLET_LIFESPAN
var can_bounce := false
var max_bounces := 1
var direction: Vector2 = Vector2.ZERO

func _ready():
	add_to_group(Global.GROUPS.PLAYER_PROJECTILES)
	add_to_group(Global.GROUPS.DAMAGING)
	add_to_group(Global.GROUPS.PROJECTILES)
	
	contact_monitor = true
	max_contacts_reported = 1

	# Bullet self-destruct after time
	await get_tree().create_timer(lifespan).timeout
	if is_instance_valid(self):
		queue_free()

func _physics_process(delta):
	linear_velocity = direction.normalized() * speed

func _on_body_entered(body):
	if body == null:
		return

	# so we can reference parent but still have access to body
	var target = body

	# Forward to parent if needed
	if not body.has_method("take_damage") and body.get_parent() and body.get_parent().has_method("take_damage"):
		target = body.get_parent()

	if target.is_in_group(Global.GROUPS.DAMAGEABLE):
		target.take_damage(damage)
		queue_free()
		return
		
	# Always bounce of crates
	if body.is_in_group(Global.GROUPS.CRATES):
		bounce_off(body)
		return

	# can_bounce should reflect whether we have the bounce_shot or not
	if body.is_in_group(Global.GROUPS.STATIC_OBJECTS) and can_bounce:
		bounce_off(body)
	else:
		queue_free()

func bounce_off(body):
	var collision = move_and_collide(linear_velocity * get_physics_process_delta_time())
	if collision:
		var normal = collision.get_normal()
		linear_velocity = linear_velocity.bounce(normal)
