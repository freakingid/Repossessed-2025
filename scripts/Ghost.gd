extends CharacterBody2D

@export var speed: float = 100.0
var player = null

func _ready():
	player = get_tree().get_first_node_in_group("player")
	if player == null:
		print("Error: No player found!")
		
func _physics_process(delta):
	if player:
		var direction = (player.global_position - global_position).normalized()
		velocity = direction * speed
		move_and_slide()

func take_damage(amount):
	queue_free()  # Ghosts die instantly
