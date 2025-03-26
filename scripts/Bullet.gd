extends RigidBody2D

var speed: float = Global.PLAYER.BULLET_SPEED
var damage: int = Global.PLAYER.BULLET_DAMAGE
var health: int = Global.PLAYER.BULLET_HEALTH
var lifespan: float = Global.PLAYER.BULLET_LIFESPAN

var direction = Vector2.ZERO
var bounce_shot: bool = false  # Determines if bullets should bounce

func _ready():
	collision_layer = Global.LAYER_PLAYER_BULLET
	collision_mask = (
		Global.LAYER_ENEMY | 
		Global.LAYER_SPAWNER | 
		Global.LAYER_WALL | 
		Global.LAYER_CRATE
	)
	
	contact_monitor = true
	max_contacts_reported = 1
	gravity_scale = 0  # top-down game
	linear_velocity = direction.normalized() * speed
	$Sprite2D.z_index = Global.Z_PLAYER_AND_CRATES


	# Start a timer to delete the bullet after lifespan duration
	await get_tree().create_timer(lifespan).timeout
	queue_free()

# What happens when a bullet hits a wall
func _on_body_entered(body):
	if body.is_in_group("crates"):
		return  # Crates are handled in _integrate_forces()

	elif body.is_in_group("walls"):
		if bounce_shot:
			var collision_normal = (global_position - body.global_position).normalized()
			direction = direction.reflect(collision_normal)
		else:
			queue_free()  # Destroy the bullet if no bounce ability

	# Do we really want to add this? The collision is handled in the enemy currently 
	elif body.is_in_group("enemies"):
		body.take_damage(damage)  # Assumes enemy has take_damage() method
		queue_free()
		
	elif body.is_in_group("spawners"):
		body.take_damage(damage)
		queue_free()

func take_damage(amount):
	health -= amount
	if health <= 0:
		queue_free()  # ✅ Bullet disappears
