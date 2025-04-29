extends CharacterBody2D
class_name BaseEnemy

@export var speed: float = 60.0
@export var health: int = 1
@export var damage: int = 1
@export var score_value: int = 1
@export var is_flying: bool = false
@export var animation_speed_reference: float = 60.0

signal despawned(reason: String, timestamp: float)
signal died(global_position: Vector2, score_value: int)

var spawn_time: float = 0.0
var push_velocity: Vector2 = Vector2.ZERO
var push_duration := 0.1  # seconds
var push_timer := 0.0
var is_flashing := false

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

signal request_spawn_gem(position: Vector2, value: int)


func _ready():
	# print("READY: ", name)
	_set_damage_meta_recursive(self)

	await get_tree().process_frame  # Wait one frame in case player isn't in scene yet
	target_node = get_tree().get_first_node_in_group(Global.GROUPS.PLAYER)

	if is_flying:
		sprite.z_index = Global.Z_FLYING_ENEMIES
	else:
		sprite.z_index = Global.Z_BASE_ENEMIES

func _set_damage_meta_recursive(node: Node):
	for child in node.get_children():
		if child is CollisionShape2D or child is Sprite2D:
			child.set_meta("damage_owner", self)
			# print(" → Set damage_owner on: ", child.name)
		_set_damage_meta_recursive(child)

func _physics_process(delta):
	if is_dead:
		return

	if push_timer > 0.0:
		push_timer -= delta

		var attempted_motion = push_velocity * delta
		var collision = move_and_collide(attempted_motion)

		if collision:
			var blocker = collision.get_collider()
			if blocker.is_in_group("walls") or blocker.is_in_group("spawners") or blocker.is_in_group("crates"):
				print("Enemy._physics_process; mysterious death")
				die()
			elif blocker.is_in_group("enemies") and blocker.has_method("attempt_push_or_crush"):
				print("Enemy._physics_process; collide with enemy now call attempt_push_or_crush in that enemy")
				blocker.attempt_push_or_crush(push_velocity)

		if push_timer <= 0.0:
			push_velocity = Vector2.ZERO

		return  # Still in push mode this frame

	# ✅ No push active — run normal AI
	update_navigation(delta)
	update_animation()
	check_player_collision()
	separate_from_player_if_stuck()  # ✅ Add this line


func check_player_collision():
	var collision = get_last_slide_collision()
	if collision:
		var collider = collision.get_collider()
		if collider and collider.is_in_group(Global.GROUPS.PLAYER):
			collider.take_damage(damage, self)

func separate_from_player_if_stuck() -> void:
	var shape: Shape2D = $CollisionShape2D.shape
	var space_state: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state

	var query: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = global_transform
	query.collision_mask = 1  # Replace with Global.LAYER_PLAYER if defined
	query.collide_with_bodies = true
	query.exclude = [self]

	var results: Array = space_state.intersect_shape(query, 4)

	for result in results:
		var collider: Node = result.get("collider")
		if collider and collider.is_in_group(Global.GROUPS.PLAYER):
			var push_vector: Vector2 = (global_position - collider.global_position).normalized() * 4.0
			global_position += push_vector

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

func move_directly_to_player(_delta):
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

func take_damage(amount: int) -> void:
	if is_dead:
		return

	# Visual + audio hit response
	HitEffectUtils.spawn_enemy_hit_effect(global_position)

	# Optional flash for feedback
	if not is_flashing:
		is_flashing = true
		modulate = Color(1, 0.3, 0.3)
		await get_tree().create_timer(0.1).timeout
		modulate = Color(1, 1, 1)
		is_flashing = false

	# Reduce health
	health -= amount
	if health <= 0:
		die()


func die():
	is_dead = true
	
	# Defer spawn gem to avoid physics errors
	call_deferred("_handle_death_cleanup")
	
	# Immediate kill queue
	queue_free()

func _handle_death_cleanup():
	if not is_inside_tree():
		return
	
	# Emit the died signal
	emit_signal("died", global_position, score_value)
	
	# Normal despawn logic
	var tree = get_tree()
	var parent = null
	if tree:
		parent = tree.current_scene
	if parent == null:
		parent = get_parent()

	var player = null
	if tree:
		player = tree.get_first_node_in_group(Global.GROUPS.PLAYER)
	if player:
		player.add_score(score_value)

	if has_meta("source_scene"):
		visible = false
		set_physics_process(false)

		var now = Time.get_ticks_msec() / 1000.0
		emit_signal("despawned", "died_from_damage", now)

		var sprite_node = get_node_or_null("AnimatedSprite2D")
		if sprite_node:
			sprite_node.modulate = Color(1, 0, 0)

		EnemyPool.recycle_enemy(self, get_meta("source_scene"))

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

func attempt_push_or_crush(push_vector: Vector2) -> void:
	if is_dead:
		return

	# Try to move now
	var attempted_motion = push_vector
	var collision = move_and_collide(attempted_motion)

	if collision:
		var blocker = collision.get_collider()
		if blocker.is_in_group("walls") or blocker.is_in_group("spawners") or blocker.is_in_group("crates"):
			print("Enemy died crushed by wall or spawner or crate")
			die()
		elif blocker.is_in_group("enemies") and blocker.has_method("attempt_push_or_crush"):
			print("Enemy is pushed into another Enemy")
			blocker.attempt_push_or_crush(push_vector)
	else:
		# Move succeeded, still add a short push timer for any follow-up
		push_velocity = push_vector
		push_timer = 0.1

@onready var hit_fx_scene = preload("res://scenes/fx/EnemyHitEffect.tscn")  # adjust path

func spawn_hit_effect() -> void:
	var fx = hit_fx_scene.instantiate()
	fx.global_position = global_position
	get_tree().current_scene.add_child(fx)
	# TODO: Play hit sound
	if has_node("HitSound"):  # optional child AudioStreamPlayer2D
		$HitSound.play()
