extends "res://scripts/BaseEnemy.gd"  # Inherits from BaseEnemy

@onready var raycast_forward = $RaycastForward
@onready var raycast_left = $RaycastLeft
@onready var raycast_right = $RaycastRight

@export var score_value: int = 1

func _ready():
	super()  # Calls BaseEnemy.gd's _ready()
	health = 4  # Skeletons are tougher than Ghosts
	speed = 80.0  # Skeletons move slower

func _process(delta):
	move_towards_player(delta)

func move_towards_player(delta):
	if player:
		var direction = (player.global_position - global_position).normalized()
		var sep_vector = get_separation_vector()  # Avoid other skeletons
		var wall_avoidance = get_wall_avoidance_vector()  # Avoid walls

		# ✅ Add slight randomness to movement
		var jitter = Vector2(randf_range(-0.2, 0.2), randf_range(-0.2, 0.2)) * speed * 0.2

		# ✅ Final movement calculation
		velocity = (direction + sep_vector * 1.5 + wall_avoidance + jitter).normalized() * speed
		move_and_slide()

func get_separation_vector() -> Vector2:
	var separation = Vector2.ZERO
	var enemies = get_tree().get_nodes_in_group("enemies") # for avoiding other enemies

	for enemy in enemies:
		if enemy != self:
			var distance = global_position.distance_to(enemy.global_position)
			if distance < separation_radius:
				var push_direction = (global_position - enemy.global_position).normalized()
				separation += push_direction / max(distance, 1)  # Prevent division by zero

	return separation.normalized() * separation_strength

func get_wall_avoidance_vector() -> Vector2:
	var repulsion = Vector2.ZERO

	if raycast_forward.is_colliding():
		repulsion += -raycast_forward.get_collision_normal()
	if raycast_left.is_colliding():
		repulsion += -raycast_left.get_collision_normal()
	if raycast_right.is_colliding():
		repulsion += -raycast_right.get_collision_normal()

	return repulsion.normalized() * 1.5  # Boost repulsion force
