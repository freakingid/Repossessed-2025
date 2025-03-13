extends CharacterBody2D

@export var health: int = 3
@export var base_speed: float = 50.0
@export var damage: int = 1
@export var is_ranged: bool = false  # Toggle for ranged vs melee enemies
var speed: int = base_speed

@onready var player = get_tree().get_first_node_in_group("player")

func _process(delta):
	move_towards_player(delta)

func move_towards_player(delta):
	if player:
		var direction = (player.global_position - global_position).normalized()
		velocity = direction * speed
		move_and_slide()

func take_damage(amount):
	health -= amount

	if health <= 0:
		die()

func die():
	queue_free()  # Remove enemy from scene
