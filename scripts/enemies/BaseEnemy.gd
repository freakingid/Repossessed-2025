extends CharacterBody2D
class_name BaseEnemy

@export var speed: float = 60.0
@export var health: int = 1
@export var damage: int = 1
@export var score_value: int = 1
@export var is_flying: bool = false
@export var animation_speed_reference: float = 60.0

signal despawned(reason: String, timestamp: float)
var spawn_time: float = 0.0

@onready var nav_agent: NavigationAgent2D = get_node_or_null("NavigationAgent2D")
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

const GEM_SCENE = preload("res://scenes/Gem.tscn")

var DIRECTION_ANIMATIONS := {
	"walk_n": Vector2.UP,
	"walk_ne": Vector2(1, -1).normalized(),
	"walk_e": Vector2.RIGHT,
	"walk_se": Vector2(1, 1).normalized(),
	"walk_s": Vector2.DOWN,
	"walk_sw": Vector2(-1, 1).normalized(),
	"walk_w": Vector2.LEFT,
	"walk_nw": Vector2(-1, -1).normalized()
}

var is_dead := false
var target_node: Node2D

func _ready():
	target_node = get_tree().get_first_node_in_group(Global.GROUPS.PLAYER)

	# Set proper z_index layering
	if is_flying:
		sprite.z_index = Global.Z_FLYING_ENEMIES
	else:
		sprite.z_index = Global.Z_BASE_ENEMIES

func _physics_process(delta):
	if is_dead:
		return

	update_navigation(delta)
	update_animation()
	check_player_collision()

func check_player_collision():
	var collision = get_last_slide_collision()
	if collision:
		var collider = collision.get_collider()
		if collider and collider.is_in_group(Global.GROUPS.PLAYER):
			collider.take_damage(damage, self)

var rotation_attempt_angle := 15
var rotation_attempts := []

func update_navigation(delta):
	if is_dead:
		return

	# Force re-check of target node in case player was reloaded
	target_node = get_tree().get_first_node_in_group(Global.GROUPS.PLAYER)
	move_directly_to_player(delta)

func is_path_blocked(direction: Vector2) -> bool:
	var space_state = get_world_2d().direct_space_state
	var from = global_position
	var to = from + direction * 16
	var result = space_state.intersect_ray(
		PhysicsRayQueryParameters2D.create(from, to)
	)
	if not result.is_empty():
		var collider = result["collider"]
		# Blocked by wall or another enemy
		if collider and (collider.is_in_group(Global.GROUPS.STATIC_OBJECTS) or collider.is_in_group(Global.GROUPS.ENEMIES)):
			return true
	return false

func move_directly_to_player(delta):
	if target_node:
		var direction = target_node.global_position - global_position
		if direction.length() > 1:
			var offset = Vector2(randf() - 0.5, randf() - 0.5) * 10
			velocity = (direction + offset).normalized() * speed
			move_and_slide()
		# retry_timer = 0.0  # Removed because it's only defined in Skeleton.gd

func get_player_global_position() -> Vector2:
	# Always re-fetch player in case of dynamic changes
	var player = get_tree().get_first_node_in_group(Global.GROUPS.PLAYER)
	if player and player is Node2D:
		target_node = player
		return target_node.global_position
	return global_position

func take_damage(amount: int):
	if is_dead:
		return

	health -= amount
	if health <= 0:
		die()

func die():
	is_dead = true

	var gem = GEM_SCENE.instantiate()
	gem.global_position = global_position
	gem.gem_power = score_value
	get_tree().current_scene.call_deferred("add_child", gem)

	var player = get_tree().get_first_node_in_group(Global.GROUPS.PLAYER)
	if player:
		player.add_score(score_value)
		
	if has_meta("source_scene"):
		visible = false
		set_physics_process(false)
		var now = Time.get_ticks_msec() / 1000.0
		emit_signal("despawned", "died_from_damage", now)
		var sprite_node := get_node_or_null("AnimatedSprite2D")
		if sprite_node:
			sprite_node.modulate = Color(1, 0, 0)  # Optional flash before hide
		EnemyPool.recycle_enemy(self, get_meta("source_scene"))
	else:
		queue_free()

func has_line_of_sight() -> bool:
	var player = get_tree().get_first_node_in_group(Global.GROUPS.PLAYER)
	if not player or not is_instance_valid(player):
		return false

	var query := PhysicsRayQueryParameters2D.new()
	query.from = global_position
	query.to = player.global_position
	query.exclude = [self]
	query.collide_with_bodies = true
	query.collide_with_areas = false

	var result = get_world_2d().direct_space_state.intersect_ray(query)

	if result and result.has("collider"):
		var collider = result["collider"]
		if collider == player:
			return true
		else:
			return false

	return true

func update_animation():
	var sprite_node := get_node_or_null("AnimatedSprite2D")
	if sprite_node == null:
		return

	if velocity.length() == 0:
		sprite_node.stop()
		return

	var dir = velocity.normalized()
	var best_match := ""
	var best_dot := -1.0

	for anim in DIRECTION_ANIMATIONS:
		var d = DIRECTION_ANIMATIONS[anim]
		var dot = d.dot(dir)
		if dot > best_dot:
			best_dot = dot
			best_match = anim

	sprite_node.speed_scale = clamp(velocity.length() / animation_speed_reference, 0.75, 1.5)

	if sprite_node.animation != best_match:
		sprite_node.play(best_match)
	elif not sprite_node.is_playing():
		sprite_node.play()

func reset():
	spawn_time = Time.get_ticks_msec() / 1000.0  # Save when it entered the scene
	is_dead = false
	visible = true
	set_physics_process(true)
	health = max(health, 1)
	velocity = Vector2.ZERO

	# Defensive resolve of AnimatedSprite2D
	var sprite_node = get_node_or_null("AnimatedSprite2D")
	if sprite_node:
		sprite_node.modulate = Color(1, 1, 1)
