extends Area2D

@export var gem_power: int = 5  # Default gem power value (varies per enemy)
@export var lifespan: float = 10.0  # Time before disappearing
@export var blink_start_time: float = 5.0  # When to start blinking
@export var magnet_range: float = 80.0  # Magnet effect range

var player: Node2D = null
var magnet_speed: float = 100.0  # Speed gems move toward the player

@onready var sprite = $Sprite2D
@onready var blink_timer = $Timer
@onready var animation_player = $AnimationPlayer

func _ready():
	# Start lifespan countdown
	blink_timer.start(lifespan/2)

	# Adjust gem color based on power
	set_gem_color()

func _process(delta):
	# Magnet Effect: Move toward player if nearby
	if player and global_position.distance_to(player.global_position) < magnet_range:
		var direction = (player.global_position - global_position).normalized()
		position += direction * magnet_speed * delta

func set_gem_color():
	# Example: Different colors for different values
	if gem_power <= 1:
		sprite.modulate = Color(0.2, 0.8, 1.0)  # Light Blue
	elif gem_power <= 2:
		sprite.modulate = Color(0.2, 1.0, 0.2)  # Green
	elif gem_power <= 8:
		sprite.modulate = Color(1.0, 0.8, 0.2)  # Yellow
	else:
		sprite.modulate = Color(1.0, 0.2, 0.2)  # Red (highest value)

func _on_Gem_body_entered(body):
	if body.is_in_group("player"):
		body.collect_gem(gem_power)
		queue_free()  # Remove gem

func _on_timer_timeout() -> void:
	# Start blinking effect using a Tween
	start_blinking_effect()

	# Wait 5 more seconds, then remove the gem
	await get_tree().create_timer(5.0).timeout
	queue_free()

func start_blinking_effect():
	var blink_time = 0.2  # Each blink cycle (fade-out + fade-in) takes 0.2 seconds
	var total_blink_time = lifespan / 2  # Blink for half the lifespan
	var blink_loops = floor(total_blink_time / blink_time)  # How many times to loop

	var tween = get_tree().create_tween()
	tween.set_loops(blink_loops)  # Adjust loop count dynamically
	tween.tween_property(sprite, "modulate", Color(1, 1, 1, 0), blink_time / 2)  # Fade out
	tween.tween_property(sprite, "modulate", Color(1, 1, 1, 1), blink_time / 2)  # Fade in
