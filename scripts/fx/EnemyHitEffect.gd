# EnemyHitEffect.gd
extends Node2D

@onready var particles := $CPUParticles2D

func _ready():
	# Ensure correct layering
	z_index = Global.Z_CHARACTER_FX
	particles.z_index = Global.Z_CHARACTER_FX + 1  # slightly above root if needed

	# Emit and self-delete
	particles.emitting = true
	await get_tree().create_timer(particles.lifetime).timeout
	queue_free()
