extends RigidBody2D

var direction: Vector2 = Vector2.ZERO
var speed := Global.SKELETON_SHOOTER.ARROW_SPEED
var damage := Global.SKELETON_SHOOTER.ARROW_DAMAGE
var lifespan := Global.SKELETON_SHOOTER.ARROW_LIFESPAN

func _ready():
	# Disable bounce behavior
	var mat := PhysicsMaterial.new()
	mat.bounce = 0
	physics_material_override = mat

	# Orient the sprite in the direction of travel
	rotation = direction.angle()

	# Arrow self-destruct after time
	await get_tree().create_timer(lifespan).timeout
	if is_instance_valid(self):
		queue_free()

func _physics_process(_delta):
	linear_velocity = direction.normalized() * speed

func _on_body_entered(body):
	if body == null:
		return

	if body.is_in_group(Global.GROUPS.PLAYER):
		body.take_damage(damage)
		queue_free()
		return

	if body.is_in_group(Global.GROUPS.STATIC_OBJECTS):
		queue_free()
