extends CharacterBody2D

signal direction_changed(new_direction: Vector2)

var last_move_direction: Vector2 = Vector2.DOWN  # or whatever default
var is_vaulting := false
var fire_direction_during_vault: Variant = null
# Tweak how long the vault takes
var vault_duration := 0.8
var vault_timer := 0.0
var vault_direction := Vector2.ZERO
var vault_distance := 0.0
var vault_distance_traveled := 0.0
var vault_crate_drop_position := Vector2.ZERO

# New physics crate stuff
@export var carried_crate_scene: PackedScene
@export var bullet_scene: PackedScene  # Assign Bullet.tscn

var is_carrying_crate = false # Are we carrying a crate?
var carried_crate_instance: Node = null # The crate we are carrying
var static_crate_instance: Node = null # The crate we hit for pickup
var is_carrying_barrel = false # Are we carrying a barrel?
var carried_barrel_instance: Node = null
var static_barrel_instance: Node = null
var speed_modifier: float = 0.9 # slower speed when carrying

var max_health: int = Global.PLAYER.HEALTH  # Max health for HUD bar percent calc
var speed: float = Global.PLAYER.SPEED
var damage: int = Global.PLAYER.DAMAGE  # ✅ Player's melee damage
var health: int = max_health  # Current health
# Base values for shooting
var base_fire_rate: float = Global.PLAYER.BULLET_BASE_FIRE_RATE  # Delay between shots
var base_max_shots: int = Global.PLAYER.BULLET_BASE_MAX_SHOTS  # Total shots allowed in scene
var base_bullet_lifespan: float = Global.PLAYER.BULLET_LIFESPAN  # Bullet lifespan

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

var invincible: bool = false # can player be damaged?

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

# Dynamic values (affected by powerups)
var fire_rate: float
var max_shots_in_level: int
var bullet_lifespan: float

@onready var sprite = $AnimatedSprite2D
@onready var hud = get_tree().get_first_node_in_group("hud")
@onready var health_bar = $HealthBar  # Ensure a ProgressBar exists as a child node
@onready var DIRECTION_ANIMATIONS := {
	"walk_e": Vector2.RIGHT,
	"walk_se": Vector2(1, 1).normalized(),
	"walk_s": Vector2.DOWN,
	"walk_sw": Vector2(-1, 1).normalized(),
	"walk_w": Vector2.LEFT,
	"walk_nw": Vector2(-1, -1).normalized(),
	"walk_n": Vector2.UP,
	"walk_ne": Vector2(1, -1).normalized()
}

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
		
	$PickupDetector.collision_mask = (
		Global.LAYER_CRATE |
		Global.LAYER_BARREL
	)
	
	sprite.z_index = Global.Z_PLAYER_AND_CRATES
	$HealthBar.z_index = Global.Z_UI_FLOATING


## Process player movement
func _physics_process(_delta):
	# Vaulting override
	if is_vaulting:
		vault_timer += _delta
		var t = vault_timer / vault_duration

		# AnimatedSprite2D scale (with ease)
		if t <= 0.5:
			var scale_t = ease(t * 2, -1.5)
			$AnimatedSprite2D.scale = Vector2(1, 1).lerp(Vector2(1.5, 1.5), scale_t)
		else:
			var scale_t = ease((t - 0.5) * 2, 1.5)
			$AnimatedSprite2D.scale = Vector2(1.5, 1.5).lerp(Vector2(1, 1), scale_t)

		# Automatic vault movement (manual control)
		var step = vault_direction * (vault_distance / vault_duration) * _delta
		global_position += step
		vault_distance_traveled += step.length()

		# End of vault
		if vault_distance_traveled >= vault_distance or vault_timer >= vault_duration:
			is_vaulting = false
			vault_timer = 0.0
			vault_distance_traveled = 0.0
			# update player sprite and draw order and collision
			$AnimatedSprite2D.scale = Vector2(1, 1)
			sprite.z_index = Global.Z_PLAYER_AND_CRATES
			set_collision_mask_value(5, true)
			
			# drop_crate(vault_crate_drop_position)
			velocity = Vector2.ZERO

			# Fire if buffered
			if fire_direction_during_vault != null:
				shoot(fire_direction_during_vault)
				fire_direction_during_vault = null
		return  # 🚨 SKIP all further input and physics



	# ----------------------------------
	# Regular movement (not vaulting)
	# ----------------------------------

	var move_direction = Vector2.ZERO

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
		move_direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * 200

	if move_direction != Vector2.ZERO:
		last_move_direction = move_direction.normalized()

	update_animation()

	if is_carrying_crate:
		speed_modifier = 0.9
	else:
		speed_modifier = 1.0
	velocity = move_direction.normalized() * speed * speed_modifier
	move_and_slide()

	if drop_cooldown_timer > 0.0:
		drop_cooldown_timer -= _delta

	var collision = get_last_slide_collision()
	if collision:
		var collider = collision.get_collider()
		if collider and collider.is_in_group("enemies") and not invincible:
			emit_signal("melee_hit", collider)


## ✅ Auto pickup crate on collision
func _on_PickupDetector_body_entered(body):
	if is_carrying_crate == false and is_carrying_barrel == false:  # can only pickup if we are not carrying anything
		if body.is_in_group("crates_static"):
			var direction_to_crate = (body.global_position - global_position).normalized()
			if direction_to_crate.dot(last_move_direction) > 0.7:  # facing toward crate
				if drop_cooldown_timer <= 0.0:
					static_crate_instance = body
					is_carrying_crate = true
					body.pickup(self)
		elif body.is_in_group("barrels_static"):
			var direction_to_barrel = (body.global_position - global_position).normalized()
			if direction_to_barrel.dot(last_move_direction) > 0.7 and drop_cooldown_timer <= 0.0:
				if drop_cooldown_timer <= 0.0:
					static_barrel_instance = body
					is_carrying_barrel = true
					body.pickup(self)

#func pickup_crate(crate_static: Node2D):
	#if is_carrying_crate:
		#return
#
	## Hide or free the static crate
	#crate_static.visible = false
	#crate_static.set_physics_process(false)
#
	## Spawn the carried crate
	#carried_crate_instance = carried_crate_scene.instantiate()
	#carried_crate_instance.player = self  # 🔗 Assign reference
#
	#get_parent().add_child(carried_crate_instance)  # Add to scene
	#is_carrying_crate = true

## ✅ Drop the crate
func drop_crate(forced_position: Variant = null):
	if carried_crate_instance == null:
		return

	var drop_position: Vector2
	if forced_position == null:
		var drop_offset = get_valid_drop_direction(last_move_direction) * 16
		drop_position = global_position + drop_offset
	else:
		drop_position = forced_position as Vector2

	static_crate_instance.reactivate(drop_position)
	carried_crate_instance.queue_free()
	is_carrying_crate = false
	drop_cooldown_timer = 0.2

func vault_over_crate(crate_position: Vector2, direction: Vector2):
	if is_vaulting:
		return
	
	is_vaulting = true
	vault_timer = 0.0
	vault_direction = direction.normalized()
	vault_distance = 2.5 * Global.CRATE_SIZE

	set_collision_mask_value(5, false)
	$AnimatedSprite2D.z_index = Global.Z_FLYING_ENEMIES
	#set_collision_mask_value(Global.LAYER_WALL, false)

	# Save position where the crate should drop after vault
	vault_crate_drop_position = crate_position
	# drop the crate (turn into Crate_Static) as vault begins
	drop_crate(vault_crate_drop_position)


func drop_barrel():
	if carried_barrel_instance == null:
		return
	

	var drop_direction = last_move_direction.normalized()
	var drop_position = global_position + drop_direction * 16

	# Decide if rolling or placing
	if velocity.length() > 0:
		# Spawn Barrel_Rolled
		var rolled_scene = preload("res://scenes/carryables/Barrel_Rolled.tscn")
		var barrel = rolled_scene.instantiate()
		barrel.global_position = drop_position
		barrel.linear_velocity = drop_direction * 300  # Adjust launch speed

		# ✅ Transfer health and flame
		barrel.health = carried_barrel_instance.health
		barrel.max_health = carried_barrel_instance.max_health
		BarrelUtils.update_flame(barrel.flame_sprite, barrel.health, barrel.max_health)

		get_tree().current_scene.call_deferred("add_child", barrel)
	else:
		# Reactivate static barrel
		# Update Barrel Static with current health
		static_barrel_instance.health = carried_barrel_instance.health
		static_barrel_instance.max_health = carried_barrel_instance.max_health
		static_barrel_instance.reactivate(drop_position)

	# Clear carried state
	carried_barrel_instance.queue_free()
	is_carrying_barrel = false
	drop_cooldown_timer = 0.2

func get_valid_drop_direction(dir: Vector2) -> Vector2:
	var allowed_dirs = [
		Vector2(0, -1),   # up
		Vector2(-1, -1),  # up-left
		Vector2(1, -1),   # up-right
		Vector2(-1, 0),   # left
		Vector2(1, 0),    # right
		Vector2(0, 1),    # down
		Vector2(-1, 1),   # down-left
		Vector2(1, 1),    # down-right
	]

	var best_match = Vector2.ZERO
	var best_dot = -1.0

	for d in allowed_dirs:
		var dot = d.normalized().dot(dir.normalized())
		if dot > best_dot:
			best_dot = dot
			best_match = d.normalized()

	return best_match


## Process player shot direction
func _process(_delta):
	var aim_direction = Vector2(
		Input.get_action_strength("aim_right") - Input.get_action_strength("aim_left"),
		Input.get_action_strength("aim_down") - Input.get_action_strength("aim_up")
	)

	# Is there fire direction input?
	if aim_direction.length() > 0:
		# Are we carrying anyting?
		if is_carrying_barrel:
			drop_barrel()
			can_shoot = false
			await get_tree().create_timer(Global.BARREL.DROPWAIT).timeout
			can_shoot = true
		elif is_carrying_crate:
			drop_crate()
			can_shoot = false
			await get_tree().create_timer(Global.CRATE.DROPWAIT).timeout
			can_shoot = true
		elif can_shoot:
			if is_vaulting:
				# queue up a shot for when we land
				fire_direction_during_vault = aim_direction.normalized()
			else:
				# Fire regular shot
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
	bullet.direction = direction # Error message fired here
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

func _on_melee_hit(enemy):
	enemy.take_damage(damage)  # ✅ Player damages enemy

## Player taking damage
func take_damage(amount: int, source: Node = null):
	if invincible:
		return

	health -= amount
	health = max(health, 0)
	if health_bar:
		health_bar.value = health
	else:
		print("HealthBar not found!")

	# Optional knockback effect
	if source:
		var knockback_vector = source.global_position.direction_to(global_position) * 200
		velocity = knockback_vector

	invincible = true
	$InvincibilityTimer.start()
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

func update_animation():
	if velocity.length() == 0:
		sprite.stop()
		return

	var best_match = ""
	var best_dot = -1.0
	var dir = last_move_direction.normalized()

	for anim in DIRECTION_ANIMATIONS:
		var d = DIRECTION_ANIMATIONS[anim]
		var dot = d.dot(dir)
		if dot > best_dot:
			best_dot = dot
			best_match = anim

	sprite.speed_scale = clamp(velocity.length() / speed, 0.75, 1.5)

	if sprite.animation != best_match:
		sprite.play(best_match)
	elif not sprite.is_playing():
		sprite.play()  # Restart current animation if it had stopped

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
