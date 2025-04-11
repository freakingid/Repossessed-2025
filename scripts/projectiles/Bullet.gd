extends RigidBody2D

var speed := Global.PLAYER.BULLET_SPEED
var damage := Global.PLAYER.BULLET_DAMAGE
var lifespan := Global.PLAYER.BULLET_LIFESPAN
var can_bounce := false
var max_bounces := 1
var bounces_remaining := 0
var direction: Vector2 = Vector2.ZERO
@onready var hitbox = $Hitbox


func _ready():
	add_to_group(Global.GROUPS.PLAYER_PROJECTILES)
	add_to_group(Global.GROUPS.DAMAGING)
	add_to_group(Global.GROUPS.PROJECTILES)
	
	# hitbox.body_entered.connect(_on_hitbox_body_entered)	
	contact_monitor = true
	max_contacts_reported = 1

	bounces_remaining = max_bounces if can_bounce else 0
	
	#print("Hitbox mask:", hitbox.collision_mask)  # Should print 8
	#print("Hitbox layer:", hitbox.collision_layer)  # Should be 0 or unused
	#print("Monitoring:", hitbox.monitoring)  # Should be true\
	#print("Hitbox enabled?", hitbox.monitoring)
	#print("Hitbox shape enabled?", hitbox.get_node("CollisionShape2D").disabled)
#
	#hitbox.area_entered.connect(_on_hitbox_area_entered)

	# Bullet self-destruct after time
	await get_tree().create_timer(lifespan).timeout
	if is_instance_valid(self):
		queue_free()

## for debug
#func _on_hitbox_area_entered(area):
	#print("HITBOX saw AREA: ", area.name)

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

#func _on_hitbox_body_entered(body):
	#print("HITBOX: saw body: ", body.name)
	#print("Layers: ", body.collision_layer)
	#print("In group 'damageable'?: ", body.is_in_group("damageable"))
	#if body.is_in_group("damageable"):
		#print("Damageable body detected!")
		#if body.has_method("take_damage"):
			#print("Calling take_damage on:", body.name)
			#body.take_damage(damage)
		#queue_free() # or trigger pool return, depending on your system

func bounce_off(body):
	var collision = move_and_collide(linear_velocity * get_physics_process_delta_time())
	if collision:
		var normal = collision.get_normal()
		linear_velocity = linear_velocity.bounce(normal)
