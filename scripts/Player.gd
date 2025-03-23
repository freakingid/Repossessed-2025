extends CharacterBody2D

signal direction_changed(new_direction: Vector2)

var last_move_direction: Vector2 = Vector2.DOWN  # or whatever default

# New physics crate stuff
@export var carried_crate_scene: PackedScene
var carrying_crate = false
var carried_crate_instance: Node = null

@export var base_speed: float = 100.0 # Initial movement speed
@export var bullet_scene: PackedScene  # Assign Bullet.tscn
@export var max_health: int = 50  # Max health (can be modified in Inspector)
@export var damage: int = 2  # ✅ Player's melee damage

# ✅ Crate Handling Variables (Added)
var drop_cooldown_timer: float = 0.0

# lightning parameters
@export var lightning_radius: float = 100.0
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

# normal shooting
var can_shoot = true # Is player shot cooldown period past?

# lightning flags
var can_use_lightning = true # Is lightning cooldown period past?
var stunned = false # Is player currently stunned from lightning use?

# nova flags
var can_use_nova = true

# Powerup State Variables
var has_big_shot: bool = false
var has_rapid_shot: bool = false
var has_triple_shot: bool = false
var has_bounce_shot: bool = false

# Base values
@export var base_fire_rate: float = 0.2  # Delay between shots
@export var base_max_shots: int = 3  # Total shots allowed in scene
@export var base_bullet_lifespan: float = 2.0  # Bullet lifespan

# Dynamic values (affected by powerups)
var fire_rate: float
var max_shots_in_level: int
var bullet_lifespan: float

@onready var sprite = $Sprite2D  # Ensure your Player has a Sprite2D node
@onready var hud = get_tree().get_first_node_in_group("hud")
@onready var health_bar = $HealthBar  # Ensure a ProgressBar exists as a child node

func _ready():
	# Set default weapon values (to allow normal shooting without powerups)
	fire_rate = base_fire_rate
	max_shots_in_level = base_max_shots
	bullet_lifespan = base_bullet_lifespan
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = health
	else:
		print("Error: HealthBar node not found!")

## Process player movement
func _physics_process(_delta):
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

	# For understanding where to put carried crate
	if move_direction != Vector2.ZERO:
		last_move_direction = move_direction.normalized()

	velocity = move_direction.normalized() * speed
	move_and_slide()

	# Tracking when we can pickup a crate again after having dropped one
	if drop_cooldown_timer > 0.0:
		drop_cooldown_timer -= _delta

	# ✅ Drop the crate when pressing a fire direction
	var aim_direction = Vector2.ZERO
	aim_direction.x = Input.get_axis("aim_left", "aim_right")
	aim_direction.y = Input.get_axis("aim_up", "aim_down")

	if carrying_crate and aim_direction.length() > 0:
		drop_crate()

	# ✅ Detect melee collisions by checking last slide collision
	var collision = get_last_slide_collision()
	if collision:
		var collider = collision.get_collider()
		if collider and collider.is_in_group("enemies") and not invincible:
			emit_signal("melee_hit", collider)  # ✅ Emit signal for melee damage

## ✅ Auto pickup crate on collision
func _on_PickupDetector_body_entered(body):
	if carrying_crate == null and body.is_in_group("crates_static"):
		var direction_to_crate = (body.global_position - global_position).normalized()
		if direction_to_crate.dot(last_move_direction) > 0.7:  # facing toward crate
			if drop_cooldown_timer <= 0.0:
				print("🟫 Picked up crate: ", body)
				carrying_crate = body
				body.pickup(self)

func pickup_crate(crate_static: Node2D):
	if carrying_crate:
		return

	# Hide or free the static crate
	crate_static.visible = false
	crate_static.set_physics_process(false)

	# Spawn the carried crate
	carried_crate_instance = carried_crate_scene.instantiate()
	carried_crate_instance.player = self  # 🔗 Assign reference

	get_parent().add_child(carried_crate_instance)  # Add to scene
	carrying_crate = true

## ✅ Drop the crate
func drop_crate():
	if carrying_crate:
		carrying_crate.drop()
		carrying_crate = null
		drop_cooldown_timer = 0.4  # Short cooldown before pickup again

## Process player shot direction
func _process(_delta):
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
	if get_tree().get_nodes_in_group("player_projectiles").size() >= max_shots_in_level:
		return  # Prevent shooting if max bullets exist

	# Ensure bullet scene is valid
	if bullet_scene == null:
		print("Error: bullet_scene is NULL")
		return  # Prevent crash

	# Create the bullet
	var bullet = bullet_scene.instantiate()
	bullet.position = $Marker2D.global_position
	bullet.direction = direction
	bullet.add_to_group("player_projectiles")  # Ensure it is trackable

	# Apply powerup effects
	if has_big_shot:
		bullet.scale *= 2  # Make bullet bigger
		bullet.damage *= 2
		bullet.health *= 2
		bullet.lifespan *= 2

	if has_bounce_shot:
		bullet.bounce_shot = true
		# Bounce shot extends lifespan, but only if big shot isn’t already boosting it
		if not has_big_shot:
			bullet.lifespan *= 2

	# Add bullet to scene
	get_tree().current_scene.add_child(bullet)

	# Handle triple shot
	if has_triple_shot:
		var left_bullet = bullet_scene.instantiate()
		left_bullet.position = bullet.position
		left_bullet.direction = direction.rotated(deg_to_rad(-15))
		left_bullet.add_to_group("player_projectiles")  # Ensure it is trackable
		get_tree().current_scene.add_child(left_bullet)

		var right_bullet = bullet_scene.instantiate()
		right_bullet.position = bullet.position
		right_bullet.direction = direction.rotated(deg_to_rad(15))
		right_bullet.add_to_group("player_projectiles")  # Ensure it is trackable
		get_tree().current_scene.add_child(right_bullet)

	# Cooldown before next shot
	can_shoot = false
	await get_tree().create_timer(fire_rate).timeout
	can_shoot = true

func apply_powerup(powerup_type: String):
	match powerup_type:
		"big_shot":
			has_big_shot = true
		"rapid_shot":
			has_rapid_shot = true
		"triple_shot":
			has_triple_shot = true
		"bounce_shot":
			has_bounce_shot = true

	# Recalculate fire rate & max bullets
	update_weapon_stats()

	# Send updated powerup state to HUD
	if hud:
		hud.update_powerup_display({
			"big_shot": has_big_shot,
			"rapid_shot": has_rapid_shot,
			"triple_shot": has_triple_shot,
			"bounce_shot": has_bounce_shot
		})

func update_weapon_stats():
	# Adjust fire rate
	fire_rate = base_fire_rate / 2 if has_rapid_shot else base_fire_rate
	
	# Adjust max bullets (Now allows 6x if both Rapid Shot + Triple Shot are active)
	if has_triple_shot and has_rapid_shot:
		max_shots_in_level = base_max_shots * 6  # ✅ Both combined = 6x normal shots
	elif has_triple_shot or has_rapid_shot:
		max_shots_in_level = base_max_shots * 3  # ✅ One of them = 3x normal shots
	else:
		max_shots_in_level = base_max_shots  # Default normal shooting
	
	# Adjust bullet lifespan (Big Shot and Bounce Shot do NOT stack lifespan)
	if has_big_shot or has_bounce_shot:
		bullet_lifespan = base_bullet_lifespan * 2
	else:
		bullet_lifespan = base_bullet_lifespan

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
