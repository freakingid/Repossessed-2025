extends CharacterBody2D

# These values are just to init; override in child classes, please
@export var health: int = 3
@export var speed: float = 25.0
@export var damage: int = 1
@export var score_value: int = 0 # initialize score award

@export var is_ranged: bool = false  # Toggle for ranged vs melee enemies
@export var separation_radius: float = 20.0  # Distance at which enemies push away from each other
@export var separation_strength: float = 75.0  # How strong the push should be

@onready var player = get_tree().get_first_node_in_group("player")
@onready var sprite = $AnimatedSprite2D
@onready var DIRECTION_ANIMATIONS := {
	"walk_e": Vector2.RIGHT,
	"walk_se": Vector2(1, 1).normalized(),
	"walk_s": Vector2.DOWN,
	"walk_sw": Vector2(-1, 1).normalized(),
	"walk_w": Vector2.LEFT,
	"walk_nw": Vector2(-1, -1).normalized(),
	"walk_n": Vector2.UP,
	"walk_ne": Vector2(1, -1).normalized()
}

func get_bullet_resistance():
	return health

func _ready():
	if player:
		player.melee_hit.connect(_on_player_melee_hit)  # ✅ Listen for melee hits
	sprite.z_index = Global.Z_BASE_ENEMIES



func _on_player_melee_hit(_collider):
	if player and player.global_position.distance_to(global_position) < 20:  # Ensure close range
		take_damage(player.damage)  # ✅ Enemy takes damage from Player
		player.take_damage(damage)  # ✅ Player takes damage from Enemy

# New: Handle damage dealt from Player melee or Player shots
func _on_body_entered(body):
	if body.is_in_group("player_projectiles"):
		take_damage(body.damage)  # ✅ Enemy applies the bullet's damage!
		body.health -= damage  # Bullet takes damage from enemy

		# Destroy bullet if its health reaches 0
		if body.health <= 0:
			body.queue_free()
			
	elif body.is_in_group("player") and not body.invincible:
		body.take_damage(damage)  # Player takes enemy melee damage

func _process(delta):
	move_towards_player(delta)
	update_animation()

func move_towards_player(_delta):
	if player:
		var direction = (player.global_position - global_position).normalized()
		velocity = direction * speed
		move_and_slide()

# Check if enemy is near other enemies (within a certain radius)
func is_near_other_enemies() -> bool:
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if enemy != self and global_position.distance_to(enemy.global_position) < separation_radius:
			return true
	return false

# Avoid other enemies by applying a small push away from them
func get_separation_vector() -> Vector2:
	var separation = Vector2.ZERO
	var enemies = get_tree().get_nodes_in_group("enemies")  # Get all enemies

	for enemy in enemies:
		if enemy != self:  # Don't check self
			var distance = global_position.distance_to(enemy.global_position)
			if distance < separation_radius:
				var push_direction = (global_position - enemy.global_position).normalized()
				separation += push_direction / max(distance, 1)  # Prevent division by zero

	return separation.normalized()

func update_animation():
	if velocity.length() == 0:
		sprite.stop()
		return

	var dir = velocity.normalized()

	var best_match = ""
	var best_dot = -1.0

	for anim in DIRECTION_ANIMATIONS:
		var d = DIRECTION_ANIMATIONS[anim]
		var dot = d.dot(dir)
		if dot > best_dot:
			best_dot = dot
			best_match = anim

	# Adjust animation speed based on movement speed
	var max_speed = speed
	var actual_speed = velocity.length()
	sprite.speed_scale = clamp(actual_speed / max_speed, 0.75, 1.5)

	if sprite.animation != best_match:
		sprite.play(best_match)
	elif not sprite.is_playing():
		sprite.play()

func _on_melee_hit(body):
	if body.is_in_group("player"):
		if not body.invincible:  # Player takes enemy damage
			body.take_damage(damage)

		take_damage(body.damage)  # Enemy takes Player's melee damage

		# New: Push enemy slightly away from the Player to avoid sticking
		var pushback_direction = (global_position - body.global_position).normalized()
		position += pushback_direction * 5  # Small push to separate from Player

		# New: Reset movement to ensure AI resumes
		reset_movement()

func reset_movement():
	var direction = (player.global_position - global_position).normalized()
	velocity = direction * speed  # Ensure movement continues

func take_damage(amount):
	health -= amount
	
	if health <= 0:
		# Grant score to player upon death
		player = get_tree().get_first_node_in_group("player")
		if player:
			player.add_score(score_value)  # Or any value you want
		
		die() # Destroy the enemy instance

func die():
	# Drop a gem when the enemy dies
	var gem = preload("res://scenes/Gem.tscn").instantiate()
	gem.global_position = global_position
	gem.gem_power = score_value  # Gem power = enemy score value
	get_tree().current_scene.call_deferred("add_child", gem)

	# Remove the enemy from the scene
	queue_free()
