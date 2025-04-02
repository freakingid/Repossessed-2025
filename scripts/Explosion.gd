extends Node2D
class_name Explosion

@export var shrapnel_scene: PackedScene
@export var num_shrapnel: int = 5
@export var shrapnel_delay: float = 0.25

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var shrapnel_timer: Timer = $ShrapnelTimer
@onready var cleanup_timer: Timer = $CleanupTimer

func _ready():
	sprite.z_index = Global.Z_SHRAPNEL
	sprite.play("explode")
	shrapnel_timer.one_shot = true
	shrapnel_timer.start(shrapnel_delay)
	var duration = sprite.sprite_frames.get_frame_count("explode") / sprite.sprite_frames.get_animation_speed("explode")
	cleanup_timer.start(duration)

# Spawn shrapnel pieces
func _on_ShapnelTimer_timeout():
	for i in num_shrapnel:
		print("Spawning shrapnel # ", i)
		var shrapnel = shrapnel_scene.instantiate()
		shrapnel.global_position = global_position
		var angle = randf() * TAU
		var speed = 250.0 + randf() * 150.0
		shrapnel.linear_velocity = Vector2.RIGHT.rotated(angle) * speed
		shrapnel.angular_velocity = randf_range(-5.0, 5.0)
		get_tree().current_scene.call_deferred("add_child", shrapnel)

# Remove explosion
func _on_CleanupTimer_timeout():
	queue_free()
