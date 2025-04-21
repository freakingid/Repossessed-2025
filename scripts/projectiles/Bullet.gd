# Bullet.gd
extends KinematicMover

@export var speed: float = Global.PLAYER.BULLET_SPEED
@export var damage: int = Global.PLAYER.BULLET_DAMAGE
@export var max_bounces: int = 5
@export var lifetime: float = Global.PLAYER.BULLET_LIFESPAN

var bounces_remaining: int
var time_alive: float = 0.0

func _ready() -> void:
	# Start moving in the direction the bullet is facing
	motion_velocity = Vector2.RIGHT.rotated(rotation) * speed
	bounces_remaining = max_bounces

func _physics_process(delta: float) -> void:
	time_alive += delta
	if time_alive > lifetime:
		queue_free()
		return

	var collision = move_and_collide(motion_velocity * delta)
	if collision:
		var collider = collision.get_collider()

		# DAMAGE ENEMY
		# Case 1: Collider itself has take_damage()
		if collider.has_method("take_damage"):
			collider.take_damage(damage)
			queue_free()
			return

		# Case 2: Collider is a child; check for meta pointing to damage_owner
		if collider.has_meta("damage_owner"):
			var _owner = collider.get_meta("damage_owner")
			if _owner and _owner.has_method("take_damage"):
				_owner.take_damage(damage)
				queue_free()
				return

		# BOUNCE OFF CRATES / WALLS
		var bounce_normal = collision.get_normal()
		if should_bounce_off(collider):
			motion_velocity = BounceUtils.calculate_bounce(motion_velocity, bounce_normal)
			bounces_remaining -= 1
			motion_velocity *= 0.9
		else:
			queue_free()
			return


func should_bounce_off(collider: Object) -> bool:
	# Only bounce off crates and walls (if power-up active)
	if collider.is_in_group("crates"):
		bounces_remaining -= 1
		return true
	elif collider.is_in_group("walls") and player_has_bounce_powerup():
		bounces_remaining -= 1
		return true
	return false

func player_has_bounce_powerup() -> bool:
	# Replace this with a proper check to your player state
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("has_powerup"):
		return player.has_powerup("Bounce Shot")
	return false
