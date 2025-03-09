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

		# Check for collisions manually
		for i in range(get_slide_collision_count()):
			var collision = get_slide_collision(i)
			var body = collision.get_collider()
			
			if body and body.is_in_group("player"):
				print("Ghost hit Player!")  # Debugging
				body.take_damage(1)  # Damage the Player

## Only take damage from bullets the player shot
func _on_body_entered(body):
	print("Ghost collided with:", body.name)  # Debugging

	if body.is_in_group("player_projectiles"):
		print("Ghost hit by bullet!")
		take_damage(1)
	elif body.is_in_group("player") and not body.invincible:
		print("Ghost hit Player!")  # Debugging message
		body.take_damage(1)  # Damage the Player

func take_damage(amount):
	health -= amount
	print(name, "took damage! Remaining health:", health)
	
	if health <= 0:
		queue_free()  # Destroy the ghost
