extends CharacterBody2D

@export var pause_time: float = 1.2  # Time before setting a new target
@export var dash_speed: float = 180.0  # Speed when dashing
@export var chase_range: float = 500.0  # Distance at which it will start chasing the player
@export var wander_time: float = 3.0  # Time spent wandering before dashing again
@export var wander_distance: float = 80.0  # How far it hovers around

var health: int = 2  # Low health
var damage: int = 2  # Melee damage
var speed: float = 120  # Bats move fast
var score_value: int = 3  # Reward score when killed

var is_dashing: bool = false  # If the bat is currently dashing
var target_position: Vector2  # Position the bat is flying towards
var is_wandering: bool = false  # If the bat is hovering randomly

@onready var timer = $Timer  # A timer node for controlling movement cycles
@onready var player = get_tree().get_first_node_in_group("player") # player is in BaseEnemy.gd but we're not a child

func _ready():
	timer.timeout.connect(_on_timer_timeout)
	timer.start(pause_time)  # Start first movement cycle

func _physics_process(delta):
	if is_dashing or is_wandering:
		# Move the bat towards the target position
		var direction = (target_position - global_position).normalized()
		velocity = direction * speed
	else:
		velocity = Vector2.ZERO

	move_and_slide()

	# If close to the target, stop dashing and start wandering
	if position.distance_to(target_position) < 5:
		is_dashing = false
		is_wandering = true
		timer.start(wander_time)  # Start wandering phase
		start_wandering()

	var collision = get_last_slide_collision()
	if collision:
		var collider = collision.get_collider()
		if collider and collider.is_in_group("player"):
			# Do something, like damage player or take damage
			print("Bat hit by player: ", collider)
			if not collider.invincible: # player can take damage
				take_damage(collider.damage)  # Bat takes Player's melee damage
				collider.take_damage(damage)  # Apply damage to player

func _on_timer_timeout():
	if is_wandering:
		# Stop wandering and return to dashing
		is_wandering = false
		player = get_tree().get_first_node_in_group("player")
		if player:
			target_position = player.global_position
			is_dashing = true  # Start dashing toward the target
			speed = dash_speed  # Reset speed to normal
	else:
		# Start wandering phase
		is_wandering = true
		start_wandering()
		timer.start(wander_time)  # Restart wander timer

func start_wandering():
	# Pick a random point within the wander area
	var wander_offset = Vector2(randf_range(-wander_distance, wander_distance), randf_range(-wander_distance, wander_distance))
	target_position = global_position + wander_offset

	# Create a Tween dynamically using SceneTreeTween
	var tween = create_tween()
	tween.tween_property(self, "position", target_position, wander_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _on_body_entered(area):
	if area.is_in_group("player"):  # Ensure it's the player
		print("Bat hit by player: ", area)
		if not area.invincible: # player can take damage
			take_damage(area.damage)  # Bat takes Player's melee damage
			area.take_damage(damage)  # Apply damage to player

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
	var gem = preload("res://Scenes/Gem.tscn").instantiate()
	gem.global_position = global_position
	gem.gem_power = score_value  # Gem power = enemy score value
	get_tree().current_scene.call_deferred("add_child", gem)

	# Remove the enemy from the scene
	queue_free()
	
