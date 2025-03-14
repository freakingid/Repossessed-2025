extends "res://scripts/BaseEnemy.gd"  # Subclassing BaseEnemy

@export var score_value: int = 1
var hit_player_recently = false  # Prevents continuous attacks, but NOT melee damage

func _ready():
	player = get_tree().get_first_node_in_group("player")
	if player == null:
		print("Error executing Zombie.gd: No player found!")
	health = 8  # Zombies have higher health
	base_speed = 30.0  # Zombies are slower
	damage = 3  # Zombies deal high melee damage
	
	# Randomize zombie speed by ±20%
	speed = base_speed * randf_range(0.8, 1.2)  # Between 80% and 120% of base speed
		
func _physics_process(delta):
	if player and is_instance_valid(player):  # Ensure the player still exists
		var direction = (player.global_position - global_position).normalized()
		velocity = direction * speed
		move_and_slide()
		## Checking for collisions after zombie moved
		for i in range(get_slide_collision_count()):
			var collision = get_slide_collision(i)
			if collision:  # Ensure the collision object exists
				var body = collision.get_collider()
				if body:  # Ensure the collider exists
					if body.is_in_group("player") and not body.invincible:
						body.take_damage(1)
						# Apply Knockback (push the zombie slightly away)
						var knockback_direction = -(player.global_position - global_position).normalized() * 20
						global_position += knockback_direction
						# Temporarily ignore Player for attacks but still allow melee hits
						hit_player_recently = true
						await get_tree().create_timer(0.3).timeout  # 0.3s delay
						hit_player_recently = false  # zombie can hit again

	else:
		player = null  # Prevent further errors if the Player is removed
		velocity = Vector2.ZERO  # Stop moving if Player is gone

## Only take damage from bullets the player shot
# TODO: I think the "1" hard-coded needs to reference the "damage" property of the player bullet
func _on_body_entered(body):
	if body.is_in_group("player_projectiles"):
		take_damage(1)
	elif body.is_in_group("player") and not body.invincible:
		body.take_damage(1)  # Damage the Player

func take_damage(amount):
	health -= amount
	
	if health <= 0:
		# Grant score to player upon death
		var player = get_tree().get_first_node_in_group("player")
		if player:
			player.add_score(score_value)  # Or any value you want
		queue_free()  # Destroy the zombie
