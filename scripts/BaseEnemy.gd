extends CharacterBody2D

@export var health: int = 3
@export var base_speed: float = 50.0
@export var damage: int = 1
@export var is_ranged: bool = false  # Toggle for ranged vs melee enemies
@export var separation_radius: float = 40.0  # Distance at which enemies push away from each other
@export var separation_strength: float = 150.0  # How strong the push should be

var speed: int = base_speed

@onready var player = get_tree().get_first_node_in_group("player")

func _process(delta):
	move_towards_player(delta)

func move_towards_player(delta):
	if player:
		var direction = (player.global_position - global_position).normalized()
		velocity = direction * speed

		# Apply separation from other enemies
		velocity += get_separation_vector() * separation_strength

		move_and_slide()

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


func take_damage(amount):
	health -= amount

	if health <= 0:
		die()

func die():
	queue_free()  # Remove enemy from scene
