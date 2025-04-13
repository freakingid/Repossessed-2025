extends CharacterBody2D

var speed := Global.PLAYER.BULLET_SPEED
var damage := Global.PLAYER.BULLET_DAMAGE
var lifespan := Global.PLAYER.BULLET_LIFESPAN
var can_bounce := false
var direction: Vector2 = Vector2.ZERO

func _ready():
	add_to_group(Global.GROUPS.PLAYER_PROJECTILES)
	add_to_group(Global.GROUPS.DAMAGING)
	add_to_group(Global.GROUPS.PROJECTILES)

	await get_tree().create_timer(lifespan).timeout
	if is_instance_valid(self):
		queue_free()

func _physics_process(delta):
	var motion = direction.normalized() * speed * delta
	var collision = move_and_collide(motion)
	
	if collision:
		var collider = collision.get_collider()

		# Handle damage
		var target = collider
		if not collider.has_method("take_damage") and collider.get_parent() and collider.get_parent().has_method("take_damage"):
			target = collider.get_parent()

		if target.is_in_group(Global.GROUPS.DAMAGEABLE):
			target.take_damage(damage)
			queue_free()
			return

		# Handle bounce
		if collider.is_in_group(Global.GROUPS.CRATES) or (collider.is_in_group(Global.GROUPS.STATIC_OBJECTS) and can_bounce):
			var normal = collision.get_normal()
			direction = direction.bounce(normal)
		else:
			queue_free()
