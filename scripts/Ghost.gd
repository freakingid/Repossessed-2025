extends CharacterBody2D

@export var base_speed: float = 100  # Default speed of a ghost
@export var health: int = 2
var player = null
var hit_player_recently = false  # Prevents continuous attacks, but NOT melee damage
var speed: float  # Each ghost will have its own unique speed

func _ready():
	player = get_tree().get_first_node_in_group("player")
	if player == null:
		print("Error: No player found!")
		
	# Randomize ghost speed by ±20%
	speed = base_speed * randf_range(0.8, 1.2)  # Between 80% and 120% of base speed
	print("Ghost spawned with speed:", speed)  # Debugging output
		
func _physics_process(delta):
	if player and is_instance_valid(player):  # Ensure the player still exists
		var direction = (player.global_position - global_position).normalized()
		velocity = direction * speed
		move_and_slide()
		## Checking for collisions after ghost moved
		for i in range(get_slide_collision_count()):
			var collision = get_slide_collision(i)
			if collision:  # Ensure the collision object exists
				var body = collision.get_collider()
				if body:  # Ensure the collider exists
					if body.is_in_group("player") and not body.invincible:
						print("Ghost hit Player!")
						body.take_damage(1)
						# Apply Knockback (push the Ghost slightly away)
						var knockback_direction = -(player.global_position - global_position).normalized() * 20
						global_position += knockback_direction
						# Temporarily ignore Player for attacks but still allow melee hits
						hit_player_recently = true
						await get_tree().create_timer(0.3).timeout  # 0.3s delay
						hit_player_recently = false  # Ghost can hit again

	else:
		player = null  # Prevent further errors if the Player is removed
		velocity = Vector2.ZERO  # Stop moving if Player is gone

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
	print(name, "took damage! Remaining health:", health)  # Debugging output
	
	if health <= 0:
		print(name, "has died!")
		queue_free()  # Destroy the ghost
