extends Area2D

var health: int = 50  # Total damage it can deal
var expand_speed: float = 400.0  # How fast it expands
var start_size: float = 4.0  # Diameter of nova at start
var max_size: float = 512.0  # Maximum diameter before disappearing


var sprite_size: float = 512.0  # Size of the actual sprite
var current_scale: float  # Start scale, calculated dynamically

@onready var collision_shape = $CollisionShape2D
@onready var sprite = $Sprite2D

func _ready():
	# Correctly calculate initial scale
	current_scale = start_size / sprite_size
	scale = Vector2(current_scale, current_scale)  # Apply the correct starting scale

func _process(delta):
	# Increase scale based on expansion speed
	var scale_factor = (expand_speed * delta) / sprite_size
	current_scale += scale_factor  # Apply scale change
	scale = Vector2(current_scale, current_scale)  # Update actual node scale

	# Ensure Nova Shot doesn't exceed max size
	if (scale.x * sprite_size) >= max_size:  # Check actual visual size
		queue_free()  # Remove when reaching max size
		return

	# Update collision shape size to match sprite scale
	collision_shape.shape.radius = (scale.x * sprite_size) / 2  # Keep radius proportional

	# Optional: Fade out slightly as it expands
	sprite.modulate.a = max(0.2, 1.0 - (scale.x / 2))

	# Remove Nova Shot if it runs out of health
	if health <= 0:
		queue_free()
func take_damage(_damage):
	health -= _damage
	if health <= 0:
		queue_free()  # Nova disappears when health runs out

# Note: This will no process Bat, which is Area2D. Bat is processing.
func _on_NovaShot_body_entered(body):
	if body.is_in_group("enemies"):
		var enemy_health = body.health
		body.take_damage(health)  # Damage enemy
		take_damage(enemy_health)
