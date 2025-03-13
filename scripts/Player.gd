extends CharacterBody2D

@export var base_speed: float = 200.0 # Initial movement speed
@export var bullet_scene: PackedScene  # Assign Bullet.tscn
@export var base_fire_rate: float = 0.2  # Delay between shots
@export var max_shots_in_level: int = 3 # Total player shots allowed in level at once
@export var max_health: int = 50  # Max health (can be modified in Inspector)
# lightning parameters
@export var lightning_radius: float = 200.0
@export var lightning_cooldown: float = 10.0
@export var stun_duration: float = 3.0
# melee management
@export var invincibility_duration: float = 0.5  # 0.5 seconds of invincibility

var health: int = max_health  # Current health
var invincible: bool = false # can player be damaged?
var speed: float = base_speed
var fire_rate: float = base_fire_rate
# normal shooting
var can_shoot = true # Is player shot cooldown period past?
# lightning flags
var can_use_lightning = true # Is lightning cooldown period past?
var stunned = false # Is player currently stunned from lightning use?

@onready var sprite = $Sprite2D  # Ensure your Player has a Sprite2D node
@onready var hud = get_tree().get_first_node_in_group("hud")
@onready var health_bar = $HealthBar  # Ensure a ProgressBar exists as a child node

func _ready():
	if health_bar:
		print("HUD Node:", hud)  # Debugging output
		print("HealthBar found!")  # Debugging output	health = max_health  # Initialize health
		health_bar.max_value = max_health
		health_bar.value = health
	else:
		print("Error: HealthBar node not found!")

	print("HUD Node:", hud) # Debug HUD


## Process player movement
func _physics_process(delta):
	var move_direction = Vector2.ZERO

	# Normal movement
	if not stunned:
		if Input.is_action_pressed("move_up"):
			move_direction.y -= 1
		if Input.is_action_pressed("move_down"):
			move_direction.y += 1
		if Input.is_action_pressed("move_left"):
			move_direction.x -= 1
		if Input.is_action_pressed("move_right"):
			move_direction.x += 1
	else:
		# Erratic movement when stunned
		move_direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * 200

	velocity = move_direction.normalized() * speed
	move_and_slide()

## Process player shot direction
func _process(delta):
	var aim_direction = Vector2.ZERO
	aim_direction.x = Input.get_axis("aim_left", "aim_right")
	aim_direction.y = Input.get_axis("aim_up", "aim_down")

	if aim_direction.length() > 0 and can_shoot:
		shoot(aim_direction.normalized())
		can_shoot = false
		await get_tree().create_timer(fire_rate).timeout
		can_shoot = true

## Fire player shot
func shoot(direction: Vector2):
	# TODO we need to see if `max_shots_in_level` num of bullets exist and possibly disallow shooting
	if bullet_scene == null:
		print("Error: bullet_scene is NULL")
		return  # Prevent crash

	var bullet = bullet_scene.instantiate()
	if bullet == null:
		print("Error: Bullet instantiation failed")
		return

	bullet.position = $Marker2D.global_position  # ERROR LINE
	bullet.direction = direction
	get_tree().current_scene.add_child(bullet)

func add_score(points: int):
	if hud:
		print("Adding score:", points)  # Debugging output
		hud.add_score(points)
		print("Score increased! New score:", Global.score)  # Debugging output
	else:
		print("HUD not found in add_score()!")

## Lightning attack for player
func use_lightning():
	if not can_use_lightning:
		return

	# Find enemies in range
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if global_position.distance_to(enemy.global_position) <= lightning_radius:
			enemy.queue_free()  # Instantly destroy enemies

	# Apply stun effect
	stunned = true
	can_use_lightning = false
	$StunTimer.start(stun_duration)
	$CooldownTimer.start(lightning_cooldown)

func _on_StunTimer_timeout():
	stunned = false  # Restore normal movement

func _on_CooldownTimer_timeout():
	can_use_lightning = true  # Ability ready again

## Melee attack for player
func _on_MeleeArea_body_entered(body):
	print("Melee collision detected with:", body.name)  # Debugging output

	if body.is_in_group("enemies") and not invincible:
		print("Melee hit:", body.name)
		print("Player is damaging enemy by hard-coded value")
		body.take_damage(1)

## Player taking damage
func take_damage(amount):
	if invincible:
		print("Player is invincible! No damage taken.")
		return  # Ignore damage if already invincible

	health -= amount
	health = max(health, 0)  # Ensure it doesn't go below 0
	print("Player took damage! Health:", health)
	if health_bar:
		print("Updating HealthBar. New Value:", health)  # Debugging output
		health_bar.value = health  # Update the health bar
	else:
		print("HealthBar not found!")

	# Start invincibility
	invincible = true
	$InvincibilityTimer.start()
	
	# Make Player sprite blink (optional, add later)
	start_blinking_effect()

	if health <= 0:
		die()

func start_blinking_effect():
	var tween = get_tree().create_tween()
	tween.tween_property(sprite, "modulate", Color(1, 1, 1, 0), 0.1)  # Invisible
	tween.tween_property(sprite, "modulate", Color(1, 1, 1, 1), 0.1)  # Visible
	tween.set_loops(5)  # Blink 5 times over 0.5s

## Make player vulnerable to attack again
func _on_invincibility_timer_timeout() -> void:
	print("invincibility timer timeout, player should take damage")
	invincible = false
	print("Player is no longer invincible.")

func die():
	print("Player has died!")  # Debugging message
	
	# Optional: Play a death animation or sound
	# Example: $AnimationPlayer.play("death")

	# Optional: Respawn the player (if needed)
	# Example: position = Vector2(START_X, START_Y)

	# For now, remove the Player from the scene
	queue_free()  # Deletes the player

	# Optional: Restart the level
	# get_tree().reload_current_scene()
