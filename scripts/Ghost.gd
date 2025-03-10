extends CharacterBody2D

@export var speed: float = 100.0
@export var health: int = 2
var player = null
var hit_player_recently = false  # Flag to prevent continuous collisions


func _ready():
	player = get_tree().get_first_node_in_group("player")
	if player == null:
		print("Error: No player found!")
		
func _physics_process(delta):
	if player and not hit_player_recently:
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
				# Apply Knockback (push the Ghost slightly away)
				var knockback_direction = -direction * 20  # Push away from Player
				global_position += knockback_direction  # Move the Ghost back
				
				# Temporarily disable collision to prevent rapid re-hits
				hit_player_recently = true
				await get_tree().create_timer(0.3).timeout  # 0.3s delay
				hit_player_recently = false  # Ghost can hit again

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
