## BarrelUtils.gd
extends Node

class_name BarrelUtils

# Update flame sprite based on damage level
static func update_flame(flame_sprite: AnimatedSprite2D, health: int, max_health: int) -> void:
	if flame_sprite == null:
		return

	var ratio = float(health) / float(max_health)

	if ratio > 0.9:
		flame_sprite.visible = false
		flame_sprite.stop()
		flame_sprite.frame = 0  # force to idle
		flame_sprite.scale = Vector2.ONE
		flame_sprite.modulate = Color(1, 1, 1)
	else:
		flame_sprite.visible = true
		flame_sprite.play()  # ✅ <- THIS is the missing line

		if ratio > 0.7:
			flame_sprite.scale = Vector2.ONE * 0.4
			flame_sprite.modulate = Color(1, 0, 0)
		elif ratio > 0.5:
			flame_sprite.scale = Vector2.ONE * 0.7
			flame_sprite.modulate = Color(1, 0, 0)
		elif ratio > 0.3:
			flame_sprite.scale = Vector2.ONE * 1.0
			flame_sprite.modulate = Color(1, 1, 0)
		else:
			flame_sprite.scale = Vector2.ONE * 1.4
			flame_sprite.modulate = Color(1, 1, 0)


# Shared explosion logic
static func explode(explosion_owner: Node2D, explosion_scene: PackedScene) -> void:
	print("Barrel trying to explode")
	if explosion_scene:
		var explosion = explosion_scene.instantiate()
		explosion.global_position = explosion_owner.global_position
		explosion_owner.get_tree().current_scene.call_deferred("add_child", explosion)

	explosion_owner.queue_free()

# Assign health and update flame
static func set_barrel_state(barrel: Node, flame_sprite: AnimatedSprite2D, h: int, max_h: int) -> void:
	barrel.health = h
	barrel.max_health = max_h

	update_flame(flame_sprite, h, max_h)

	if flame_sprite:
		var should_burn = h < max_h  # or h < 100% of max_h
		flame_sprite.visible = should_burn

		if should_burn:
			flame_sprite.play()
		else:
			flame_sprite.stop()
			flame_sprite.scale = Vector2.ONE
			flame_sprite.modulate = Color(1, 1, 1)

# Handle taking damage and possibly exploding
#static func take_damage(barrel: Node, amount: int, explosion_scene: PackedScene) -> void:
	#if not barrel.has_method("queue_free"):
		#return
#
	#barrel.health -= amount
#
	#if barrel.has_node("FlameSprite"):
		#update_flame(barrel.get_node("FlameSprite"), barrel.health, barrel.max_health)
#
	#if barrel.health <= 0:
		#explode(barrel.global_position, explosion_scene)
		#barrel.queue_free()

# Shared initialization
static func init_barrel(barrel: Node, layer: int, mask: int, group: String) -> void:
	barrel.collision_layer = layer
	barrel.collision_mask = mask
	barrel.add_to_group(group)
	barrel.health = barrel.max_health
	if barrel.has_node("Sprite2D"):
		barrel.get_node("Sprite2D").z_index = Global.Z_PLAYER_AND_CRATES
	if barrel.has_node("FlameSprite"):
		barrel.get_node("FlameSprite").z_index = Global.Z_PLAYER_AND_CRATES + 1
