extends Area2D

@export var powerup_type: String  # Type of powerup (set in Inspector or randomly)
@export var lifetime: float = 30.0  # Expiration time for randomly spawned powerups

@onready var sprite = $Sprite2D
@onready var lifetime_timer = $LifetimeTimer

# Powerup Icons (Preloaded Textures)
var powerup_sprites = {
	"big_shot": preload("res://assets/sprites/powerups/fpo-powerup_B.png"),
	"rapid_shot": preload("res://assets/sprites/powerups/fpo-powerup_R.png"),
	"triple_shot": preload("res://assets/sprites/powerups/fpo-powerup_T.png"),
	"bounce_shot": preload("res://assets/sprites/powerups/fpo-powerup_BB.png")
}

func _ready():
	# Set the correct sprite based on powerup type
	if powerup_type in powerup_sprites:
		sprite.texture = powerup_sprites[powerup_type]
	else:
		print("⚠️ Warning: Powerup type not found!", powerup_type)

	# If randomly placed, start the expiration timer
	if lifetime > 0:
		lifetime_timer.wait_time = lifetime
		lifetime_timer.start()

# When the player touches the powerup
func _on_Powerup_body_entered(body):
	if body.is_in_group("player"):
		body.apply_powerup(powerup_type)
		queue_free()  # Remove powerup after pickup

# Powerup disappears after its lifetime expires
func _on_LifetimeTimer_timeout():
	queue_free()
