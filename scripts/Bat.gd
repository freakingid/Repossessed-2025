extends CharacterBody2D

var health = Global.BAT.HEALTH
var speed = Global.BAT.SPEED
var damage = Global.BAT.DAMAGE
var score_value = Global.BAT.SCORE

# Bat-specific
var dash_speed: float = speed * 2  # Speed when dashing
var wandering_speed: float = speed * 0.8 # normal speed?
var pause_time: float = 1.2  # Time before setting a new target
var chase_range: float = 500.0  # Distance at which it will start chasing the player
var wander_time: float = 3.0  # Time spent wandering before dashing again
var wander_distance: float = 80.0  # How far it hovers around

var is_dashing: bool = false  # If the bat is currently dashing
var target_position: Vector2  # Position the bat is flying towards
var is_wandering: bool = false  # If the bat is hovering randomly

@onready var timer = $Timer  # A timer node for controlling movement cycles
@onready var player = get_tree().get_first_node_in_group("player") # player is in BaseEnemy.gd but we're not a child

func _ready():
	timer.timeout.connect(_on_timer_timeout)
	if player:
		target_position = player.global_position
		is_dashing = true
		speed = dash_speed
		timer.start(pause_time)  # Starts the dash → wander cycle

	collision_layer = Global.LAYER_FLYING_ENEMY
	collision_mask = (
		Global.LAYER_PLAYER |
		Global.LAYER_PLAYER_BULLET
	)
	$Sprite2D.z_index = Global.Z_FLYING_ENEMIES


func _process(_delta):
	if is_dashing:
		var direction = (target_position - global_position).normalized()
		velocity = direction * speed
		move_and_slide()

		if position.distance_to(target_position) < 5:
			is_dashing = false
			is_wandering = true
			start_wandering()
			timer.start(wander_time)

func _on_timer_timeout():
	if is_wandering:
		# Time to start dashing again
		is_wandering = false
		player = get_tree().get_first_node_in_group("player")
		if player:
			target_position = player.global_position
			is_dashing = true
			speed = dash_speed
			timer.start(pause_time)  # Dash for X seconds
	else:
		# Time to start wandering
		is_dashing = false
		is_wandering = true
		speed = wandering_speed
		start_wandering()
		timer.start(wander_time)  # Wander for Y seconds

func start_wandering():
	# Pick a random point within the wander area
	var wander_offset = Vector2(
		randf_range(-wander_distance, wander_distance), 
		randf_range(-wander_distance, wander_distance)
	)
	target_position = global_position + wander_offset

	# Create a Tween dynamically using SceneTreeTween
	var tween = create_tween()
	tween.tween_property(self, "position", target_position, wander_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func take_damage(amount):
	health -= amount
	
	if health <= 0:
		# Grant score to player upon death
		player = get_tree().get_first_node_in_group("player")
		if player:
			player.add_score(score_value)  # Or any value you want
		
		die() # Destroy the enemy instance

func die():
	# Drop a gem when the enemy dies
	var gem = preload("res://scenes/Gem.tscn").instantiate()
	gem.global_position = global_position
	gem.gem_power = score_value  # Gem power = enemy score value
	get_tree().current_scene.call_deferred("add_child", gem)

	# Remove the enemy from the scene
	queue_free()

func _on_Hitbox_area_entered(area: Area2D) -> void:
	if area.is_in_group("player_projectiles"):
		print("Bat collided with player bullet!")
		take_damage(area.damage)
		area.take_damage(damage)
	elif area.is_in_group("nova_shot"):
		print("Bat collided with nova shot")
		var _my_health = health
		# TODO Some concern that we might destroy the Bat before finishing damage to Nova
		# take damage from the novashot
		take_damage(area.health)
		# subtract my original health from novashot
		area.take_damage(_my_health)

func _on_Hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and not body.invincible:
		print("Bat collided with player!")
		body.take_damage(damage)
		take_damage(body.damage)  # Optional if you want bat to take melee damage too
