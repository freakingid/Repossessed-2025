extends CharacterBody2D

@export var base_speed: float = 200.0 # Initial movement speed
@export var bullet_scene: PackedScene  # Assign Bullet.tscn
@export var base_fire_rate: float = 0.2  # Delay between shots
@export var max_shots_in_level: int = 3 # Total player shots allowed in level at once
@export var max_health: int = 50  # Max health (can be modified in Inspector)
@export var damage: int = 2  # ✅ Player's melee damage
# lightning parameters
@export var lightning_radius: float = 200.0
@export var lightning_cooldown: float = 10.0
@export var stun_duration: float = 3.0
# gem and nova shot
@export var gem_power: int = 0  # Current stored gem power
@export var max_nova_charge: int = 50  # Nova shot requires 50 gem power
@export var nova_shot_scene: PackedScene  # Assign NovaShot.tscn
@export var nova_shot_cooldown: float = 0.5  # Prevents instant spam
# melee management
@export var invincibility_duration: float = 0.5  # 0.5 seconds of invincibility

signal melee_hit(body)  # ✅ Signal emitted when colliding with an enemy

var health: int = max_health  # Current health
var invincible: bool = false # can player be damaged?
var speed: float = base_speed
var fire_rate: float = base_fire_rate
# normal shooting
var can_shoot = true # Is player shot cooldown period past?
# lightning flags
var can_use_lightning = true # Is lightning cooldown period past?
var stunned = false # Is player currently stunned from lightning use?
# nova flags
var can_use_nova = true

@onready var sprite = $Sprite2D  # Ensure your Player has a Sprite2D node
@onready var hud = get_tree().get_first_node_in_group("hud")
@onready var health_bar = $HealthBar  # Ensure a ProgressBar exists as a child node

func _ready():
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = health
	else:
		print("Error: HealthBar node not found!")

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

	# ✅ Detect melee collisions by checking last slide collision
	var collision = get_last_slide_collision()
	if collision:
		var collider = collision.get_collider()
		if collider and collider.is_in_group("enemies") and not invincible:
			emit_signal("melee_hit", collider)  # ✅ Emit signal for melee damage

## Process player shot direction
func _process(delta):
	var aim_direction = Vector2.ZERO
	aim_direction.x = Input.get_axis("aim_left", "aim_right")
	aim_direction.y = Input.get_axis("aim_up", "aim_down")

	# Fire regular shot
	if aim_direction.length() > 0 and can_shoot:
		shoot(aim_direction.normalized())
		can_shoot = false
		await get_tree().create_timer(fire_rate).timeout
		can_shoot = true

	# Fire nova shot
	if Input.is_action_just_pressed("nova_attack"):
		use_nova_shot()

## Fire player shot
func shoot(direction: Vector2):
	# Check how many bullets exist
	var bullets = get_tree().get_nodes_in_group("player_projectiles")
	if bullets.size() >= max_shots_in_level:
		return  # Stop the player from shooting

	# Ensure bullet scene is valid
	if bullet_scene == null:
		print("Error: bullet_scene is NULL")
		return  # Prevent crash

	# Spawn new bullet
	var bullet = bullet_scene.instantiate()
	if bullet == null:
		print("Error: Bullet instantiation failed")
		return

	bullet.position = $Marker2D.global_position  # ERROR LINE
	bullet.direction = direction

	# Add bullet to the scene & make sure it's in the right group
	get_tree().current_scene.add_child(bullet)
	bullet.add_to_group("player_projectiles")  # Ensure it is trackable

func use_nova_shot():
	if not can_use_nova or gem_power < max_nova_charge:
		print("cannot fire nova yet")
		return  # Not enough charge or still on cooldown

	# Consume 50 gem power (1 full charge)
	gem_power -= max_nova_charge
	update_hud()  # Update HUD display

	# Spawn Nova Shot
	var nova = nova_shot_scene.instantiate()
	if nova == null:
		print("Could not instantiate nova")
		return

	nova.global_position = global_position
	print("adding nova")
	get_tree().current_scene.add_child(nova)

	# Start cooldown
	can_use_nova = false
	await get_tree().create_timer(nova_shot_cooldown).timeout
	can_use_nova = true

func add_score(points: int):
	if hud:
		hud.add_score(points)
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
	if body.is_in_group("enemies") and not invincible:
		body.take_damage(1)

## Player taking damage
func take_damage(amount):
	if invincible:
		return  # Ignore damage if already invincible

	health -= amount
	health = max(health, 0)  # Ensure it doesn't go below 0
	if health_bar:
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
	invincible = false

func collect_gem(amount: int):
	gem_power += amount
	update_hud()

## Update HUD specifically for gems collected
func update_hud():
	if hud:
		var full_charges = floor(gem_power / float(max_nova_charge))  # Corrected floor division
		var partial_charge = gem_power % max_nova_charge
		hud.update_gem_power(full_charges, partial_charge)

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
