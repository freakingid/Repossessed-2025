extends CharacterBody2D

@export var health: int = 3
@export var base_speed: float = 50.0
@export var damage: int = 1
@export var is_ranged: bool = false  # Toggle for ranged vs melee enemies
@export var separation_radius: float = 40.0  # Distance at which enemies push away from each other
@export var separation_strength: float = 150.0  # How strong the push should be

var speed: float = base_speed

@onready var player = get_tree().get_first_node_in_group("player")
# Raycast Nodes for Wall Avoidance
@onready var raycast_forward = $RaycastForward
@onready var raycast_left = $RaycastLeft
@onready var raycast_right = $RaycastRight

func get_bullet_resistance():
	return health

func _ready():
	if player:
		player.melee_hit.connect(_on_player_melee_hit)  # ✅ Listen for melee hits

func _on_player_melee_hit(player):
	if player and player.global_position.distance_to(global_position) < 40:  # Ensure close range
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

func move_towards_player(delta):
	if player:
		var direction = (player.global_position - global_position).normalized()
		var sep_vector = get_separation_vector()

		# Only apply jitter if the enemy is near other enemies or obstacles
		var jitter = Vector2.ZERO
		if is_near_obstacle():
			jitter = Vector2(randf_range(-0.2, 0.2), randf_range(-0.2, 0.2)) * speed  # Add jitter

		# Apply normal movement + jitter + separation
		velocity = (direction + jitter).normalized() * speed + sep_vector * separation_strength

		# NEW: Repel from Walls
		if is_near_wall():
			velocity += get_wall_repulsion_vector() * 100  # Push away from walls

		move_and_slide()

# Check if enemy is near walls or other enemies
func is_near_obstacle() -> bool:
	return is_near_wall() or is_near_other_enemies()

# Check if enemy is near walls
func is_near_wall() -> bool:
	return raycast_forward.is_colliding() or raycast_left.is_colliding() or raycast_right.is_colliding()

# Check if enemy is near other enemies (within a certain radius)
func is_near_other_enemies() -> bool:
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if enemy != self and global_position.distance_to(enemy.global_position) < separation_radius:
			return true
	return false

func get_wall_repulsion_vector() -> Vector2:
	var repulsion = Vector2.ZERO

	if raycast_forward.is_colliding():
		repulsion += -raycast_forward.get_collision_normal()  # Push back
	if raycast_left.is_colliding():
		repulsion += -raycast_left.get_collision_normal()  # Push away from left
	if raycast_right.is_colliding():
		repulsion += -raycast_right.get_collision_normal()  # Push away from right

	return repulsion.normalized()

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
		die()

func die():
	queue_free()  # Remove enemy from scene
