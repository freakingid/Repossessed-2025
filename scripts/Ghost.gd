extends CharacterBody2D

@export var speed: float = 100.0
@export var health: int = 2
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

## Only take damage from bullets the player shot
func _on_body_entered(body):
	if body.is_in_group("player_projectiles"):
		take_damage(1)

func take_damage(amount):
	health -= amount
	print(name, "took damage! Remaining health:", health)
	
	if health <= 0:
		queue_free()  # Destroy the ghost
