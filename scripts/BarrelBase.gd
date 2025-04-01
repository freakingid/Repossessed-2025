extends Node

var health: int = 10
var max_health: int = 10
var flame_sprite: Node = null  # Optional: set in _ready() of child

func set_barrel_state(h: int, max_h: int) -> void:
	health = h
	max_health = max_h
	if has_method("update_flame"):
		update_flame()

func take_damage(amount: int) -> void:
	health -= amount
	if has_method("update_flame"):
		update_flame()

	if health <= 0:
		if has_method("explode"):
			explode()
		else:
			queue_free()  # fallback

func update_flame() -> void:
	if not flame_sprite:
		return

	var ratio = float(health) / float(max_health)

	if ratio > 0.9:
		flame_sprite.visible = false
	elif ratio > 0.7:
		flame_sprite.visible = true
		flame_sprite.scale = Vector2.ONE * 0.4
		flame_sprite.modulate = Color(1, 0, 0)  # 🔥 Red
	elif ratio > 0.5:
		flame_sprite.visible = true
		flame_sprite.scale = Vector2.ONE * 0.7
		flame_sprite.modulate = Color(1, 0, 0)  # 🔥 Red
	elif ratio > 0.3:
		flame_sprite.visible = true
		flame_sprite.scale = Vector2.ONE * 1.0
		flame_sprite.modulate = Color(1, 1, 0)  # 🔥 Yellow
	else:
		flame_sprite.visible = true
		flame_sprite.scale = Vector2.ONE * 1.4
		flame_sprite.modulate = Color(1, 1, 0.9)  # 🔥 White-yellow

func explode() -> void:
	if has_node("ExplosionScene"):
		var explosion_scene = get("ExplosionScene")
		if explosion_scene:
			var explosion = explosion_scene.instantiate()
			explosion.global_position = global_position
			get_tree().current_scene.call_deferred("add_child", explosion)

	queue_free()
