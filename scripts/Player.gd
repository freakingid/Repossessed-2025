extends CharacterBody2D

# BEGIN adding reparenting
@onready var carried_crate_node = $CarriedCrate
@onready var move_collider_small = $move_collider_small
@onready var move_collider_up = $move_collider_up
@onready var move_collider_down = $move_collider_down
@onready var move_collider_left = $move_collider_left
@onready var move_collider_right = $move_collider_right
@onready var move_collider_up_right = $move_collider_up_right
@onready var move_collider_up_left = $move_collider_up_left
@onready var move_collider_down_right = $move_collider_down_right
@onready var move_collider_down_left = $move_collider_down_left
var carried_crate_source: Node = null  # Reference to original Crate_Static node
# END adding reparenting
@onready var bullet_sfx = [
	preload("res://assets/audio/sfx/player-shoots/player-slingshot-01.mp3"),
	preload("res://assets/audio/sfx/player-shoots/player-slingshot-02.mp3"),
	preload("res://assets/audio/sfx/player-shoots/player-slingshot-03.mp3"),
	preload("res://assets/audio/sfx/player-shoots/player-slingshot-04.mp3")
]
@onready var vault_sfx = [
	preload("res://assets/audio/sfx/player-vault/player-vault-001.ogg"),
	preload("res://assets/audio/sfx/player-vault/player-vault-002.ogg"),
	preload("res://assets/audio/sfx/player-vault/player-vault-003.ogg"),
	preload("res://assets/audio/sfx/player-vault/player-vault-004.ogg")
]
@onready var crate_pickup_sfx = [
	preload("res://assets/audio/sfx/crate-pickup/crate-pickup-001.ogg"),
	preload("res://assets/audio/sfx/crate-pickup/crate-pickup-002.ogg"),
	preload("res://assets/audio/sfx/crate-pickup/crate-pickup-003.ogg")
]
@onready var crate_drop_sfx = [
	preload("res://assets/audio/sfx/crate-dropped/crate-drop-001.ogg"),
	preload("res://assets/audio/sfx/crate-dropped/crate-drop-002.ogg"),
	preload("res://assets/audio/sfx/crate-dropped/crate-drop-003.ogg"),
	preload("res://assets/audio/sfx/crate-dropped/crate-drop-004.ogg")
]


signal direction_changed(new_direction: Vector2)

# Some debug properties
var vault_debug_position := Vector2.ZERO
var vault_debug_radius := 8.0
var vault_debug_timer := 1.0

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
var should_spin_during_vault := false


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
const DROP_COOLDOWN := 0.3  # seconds
var drop_cooldown_timer: float = DROP_COOLDOWN

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
@onready var base_collision_mask := (
	Global.LAYER_WALL |
	Global.LAYER_BARREL |
	Global.LAYER_SPAWNER |
	Global.LAYER_ENEMY |
	Global.LAYER_CRATE  # for solid blocking
)

const PLAYER_CARRY_COLLISION_MASK = (
	Global.LAYER_WALL |
	Global.LAYER_BARREL |
	Global.LAYER_SPAWNER |
	Global.LAYER_ENEMY |
	Global.LAYER_CRATE  # 🟡 this will be conditionally toggled
)

func _ready():
	# Disable all movement colliders initially
	move_collider_up.disabled = true
	move_collider_down.disabled = true
	move_collider_left.disabled = true
	move_collider_right.disabled = true
	move_collider_up_right.disabled = true
	move_collider_up_left.disabled = true
	move_collider_down_right.disabled = true
	move_collider_down_left.disabled = true
	
	# Enable the small normal collider by default
	move_collider_small.disabled = false
	
	# Setup for carried crate
	# Reference the Area2D inside CarriedCrate
	var crate_area := $CarriedCrate/Area2D	
	# Set the collision layer (which layer this Area2D is on)
	# Example: Global.LAYER_CRATE_HITBOX (define this as needed)
	crate_area.collision_layer = Global.LAYER_CRATE
	# Set the collision mask (which layers this Area2D will detect)
	# Example: Detects enemy projectiles and shrapnel
	crate_area.collision_mask = (
		Global.LAYER_ENEMY_PROJECTILE |
		Global.LAYER_PLAYER_BULLET |
		Global.LAYER_SHRAPNEL
	)
	
	# Setup collision layer and mask for Player portion
	self.collision_layer = Global.LAYER_PLAYER
	update_player_collision_mask()
		
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
	
	sprite.z_index = Global.Z_PLAYER
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
		
		# Spinning the jump
		if should_spin_during_vault:
			var spin_direction : int = sign(vault_direction.x)  # +1 for right, -1 for left, 0 for up/down
			$AnimatedSprite2D.rotation = spin_direction * vault_timer / vault_duration * TAU


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
			$AnimatedSprite2D.rotation = 0
			sprite.z_index = Global.Z_PLAYER
			# allow to collide with obstacles again
			restore_blocking_collisions()
			await play_landing_squash()
			
			# make sure we stop moving
			# TODO maybe we could have a slowdown speed instead of a hard landing??
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
	update_carried_crate_z_index()
	update_carried_crate_position()
	update_movement_collider()

	# Are we carrying a crate? If so, we will walk a bit slower.
	if carried_crate_source != null:
		# Yes, carrying a crate
		speed_modifier = 0.9
	else:
		# No, not carrying a crate
		speed_modifier = 1.0

	# Now move Player
	velocity = move_direction.normalized() * speed * speed_modifier
	move_and_slide()

	if drop_cooldown_timer > 0.0:
		drop_cooldown_timer -= _delta

	# See if we hit stuff. So far we just look for enemies for auto-melee damage
	var collision = get_last_slide_collision()
	if collision:
		var collider = collision.get_collider()
		if collider and collider.is_in_group("enemies") and not invincible:
			emit_signal("melee_hit", collider)
		else:
			# maybe we need to auto vault if collided with obstacle
			check_auto_vault(collider)

## ✅ Auto pickup crate on collision
func _on_PickupDetector_body_entered(body: Node) -> void:
	print("Player pickup detector body entered TOP")
	
	if carried_crate_source == null and is_carrying_barrel == false:  # can only pick up if empty-handed
		
		if body.is_in_group("crates_static"):
			var direction_to_crate = (body.global_position - global_position).normalized()
			if direction_to_crate.dot(last_move_direction) > 0.7:  # facing toward crate
				if drop_cooldown_timer <= 0.0:
					print("Attempting to pick up Crate_Static")
					begin_carrying_crate(body)  # <<< NEW
				else:
					print("Cannot pickup crate because of crate cooldown timer")
					
		elif body.is_in_group("barrels_static"):
			var direction_to_barrel = (body.global_position - global_position).normalized()
			if direction_to_barrel.dot(last_move_direction) > 0.7:
				if drop_cooldown_timer <= 0.0:
					print("Attempting to pick up Barrel_Static")
					begin_carrying_barrel(body)  # <<< You’ll need a similar method like begin_carrying_barrel()

func vault_over_crate(crate_position: Vector2, direction: Vector2) -> bool:
	print("Player.vault_over_crate() called")
	if is_vaulting:
		# Already in the middle of vaulting, so do not start anew
		return false

	# Check if vaulting would land us on a forbidden obstacle (e.g. Spawner, Wall)
	if vault_landing_should_cancel(crate_position, direction, 2.5 * Global.CRATE_SIZE):
		print("Vault canceled: landing blocked by a disallowed obstacle.")
		play_vault_fail_feedback()
		velocity = Vector2.ZERO
		global_position -= last_move_direction * 4  # Small nudge backward to indicate bump
		return false

	# Try to make sure we wouldn't land outside room boundaries
	var projected_landing = crate_position + direction.normalized() * 2.5 * Global.CRATE_SIZE	
	if not Global.is_inside_room_bounds(projected_landing):
		print("Vault canceled: landing outside room bounds.")
		play_vault_fail_feedback()
		velocity = Vector2.ZERO
		return false

	# ✅ Begin vault sequence
	is_vaulting = true
	vault_timer = 0.0
	vault_direction = direction.normalized()
	vault_distance = 2.5 * Global.CRATE_SIZE

	# 🔈 Stub: play vault sound
	play_vault_sound()

	# Determine if we should spin (horizontal/diagonal vault)
	if abs(vault_direction.y) < 0.8:
		should_spin_during_vault = true
	else:
		should_spin_during_vault = false	

	# Disable collisions with blocking layers so we phase through
	disable_blocking_collisions()

	# Temporarily raise sprite's z-index to fly over objects
	$AnimatedSprite2D.z_index = Global.Z_FLYING_ENEMIES

	# Drop the carried crate as the vault begins
	vault_crate_drop_position = crate_position
	drop_crate(vault_crate_drop_position)

	# ✅ Vault triggered successfully
	return true

func drop_barrel():
	if carried_barrel_instance == null:
		return

	var drop_direction = last_move_direction.normalized()
	var drop_position = global_position + drop_direction * 16

	# Decide if rolling or placing
	if velocity.length() > 0:
		print("Going to spawn barrel rolled")
		# Spawn Barrel_Rolled (KinematicMover-based)
		var rolled_scene = preload("res://scenes/carryables/Barrel_Rolled.tscn")
		var barrel = rolled_scene.instantiate()
		barrel.global_position = drop_position

		# Apply motion manually using new system
		barrel.set_velocity_from_drop(drop_direction * Global.BARREL.KICK_SPEED)

		# Transfer health + flame state
		barrel.health = carried_barrel_instance.health
		barrel.max_health = carried_barrel_instance.max_health
		BarrelUtils.update_flame(barrel.flame_sprite, barrel.health, barrel.max_health)

		get_tree().current_scene.call_deferred("add_child", barrel)
	else:
		print("Going to spawn barrel static")
		# Reactivate static barrel and transfer state
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
	# drop cooldown timer is for waiting before picking up crate again
	if drop_cooldown_timer > 0.0:
		drop_cooldown_timer -= _delta

	if vault_debug_timer > 0.0:
		vault_debug_timer -= _delta
		queue_redraw()  # triggers _draw
	# Did we press an aim direction?
	var aim_direction = Vector2(
		Input.get_action_strength("aim_right") - Input.get_action_strength("aim_left"),
		Input.get_action_strength("aim_down") - Input.get_action_strength("aim_up")
	)

	# Is there fire direction input?
	if aim_direction.length() > 0:
		# Calculate if we are moving or not
		var is_moving = velocity.length() > 0.1  # or use move_direction.length() > 0.1 if available
		# Are we carrying anyting?
		if is_carrying_barrel:
			## TODO we should use drop cooldown timer here just like in crate below
			drop_barrel()
			can_shoot = false
			await get_tree().create_timer(Global.BARREL.DROPWAIT).timeout
			can_shoot = true
		elif carried_crate_source != null:
			print("Going to drop crate")
			var proposed_landing_pos = global_position + get_valid_drop_direction(last_move_direction) * 16

			if is_moving:
				# Attempt vault only while moving
				if vault_over_crate(global_position + carried_crate_node.position, last_move_direction):
					can_shoot = false
					await get_tree().create_timer(Global.CRATE.DROPWAIT).timeout
					can_shoot = true
			else:
				# Standing still: just drop the crate
				drop_crate(proposed_landing_pos)
				# we need z_index of crate updated??
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
		return

	if bullet_scene == null:
		print("Error: bullet_scene is NULL")
		return

	# Primary bullet
	var bullet = bullet_scene.instantiate()
	bullet.global_position = $Marker2D.global_position
	bullet.rotation = direction.angle()
	bullet.add_to_group("player_projectiles")

	# Powerup effects
	if has_big_shot:
		bullet.scale *= 2
		bullet.damage *= 2
		bullet.health *= 2
		bullet.lifetime *= 2  # renamed from lifespan

	if has_bounce_shot:
		bullet.max_bounces = 10  # or some appropriate number
		if not has_big_shot:
			bullet.lifetime *= 2

	get_tree().current_scene.add_child(bullet)

	# Triple Shot
	if has_triple_shot:
		for angle_offset in [-15, 15]:
			var extra_bullet = bullet_scene.instantiate()
			extra_bullet.global_position = bullet.global_position
			extra_bullet.rotation = direction.angle() + deg_to_rad(angle_offset)
			extra_bullet.add_to_group("player_projectiles")
			get_tree().current_scene.add_child(extra_bullet)

	# Player Bullet SFX
	play_bullet_sound()
	
	# Cooldown
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

# Effects upon Player landing a vault
func play_landing_squash():
	var squash_scale = Vector2(1.1, 0.6)
	var squash_duration = 0.08
	var rebound_duration = 0.08
	var slide_distance = 4.0

	# Start with squash
	$AnimatedSprite2D.scale = squash_scale

	# Try to slide forward slightly (only if unblocked)
	var space_state = get_world_2d().direct_space_state
	var forward = vault_direction.normalized()
	var slide_pos = global_position + forward * slide_distance

	var shape = CircleShape2D.new()
	shape.radius = 6

	var transform = Transform2D.IDENTITY
	transform.origin = slide_pos

	var params = PhysicsShapeQueryParameters2D.new()
	params.shape = shape
	params.transform = transform
	params.exclude = [self]
	params.collision_mask = (
		Global.LAYER_WALL |
		Global.LAYER_SPAWNER |
		Global.LAYER_CRATE
	)
	params.collide_with_bodies = true

	var result = space_state.intersect_shape(params, 1)

	if result.size() == 0:
		global_position = slide_pos  # Perform nudge if not blocked

	await get_tree().create_timer(squash_duration).timeout
	# Rebound to normal
	$AnimatedSprite2D.scale = Vector2(1, 1)
	await get_tree().create_timer(rebound_duration).timeout
	
	# 🎯 If enemy was left behind, play a taunt sound
	if should_taunt_after_vault():
		play_taunt_sound()

func play_vault_fail_feedback():
	pass
	# Add shake, sound, or visual cue here
	# print("This is where we would play a vaulting fail tone")
	#$VaultFailSound.play()
	# print("This is where we would show a brief vaulting fail flash")
	#$SpriteFlash.flash_red()  # if you have a sprite flash node or method

func check_auto_vault(_collider) -> void:
	# print("check_auto_vault TOP")
	if carried_crate_source == null:
		return  # Not carrying crate

	if is_vaulting:
		return  # Already vaulting

	#if velocity.length() < 5.0:
		#print("Moving less than 5.0; returning without vault")
		#return  # Not moving enough to count as intentional movement

	if _collider and (_collider.is_in_group("crates_static") or _collider.is_in_group("walls") or _collider.is_in_group("spawners")):
		var crate_world_position = global_position + carried_crate_node.position
		vault_over_crate(crate_world_position, last_move_direction)

func try_vault_from(start_pos: Vector2, direction: Vector2) -> bool:
	if vault_landing_should_cancel(start_pos, direction, 2.5 * Global.CRATE_SIZE):
		# print("Vault canceled.")
		play_vault_fail_feedback()
		velocity = Vector2.ZERO
		return false

	# Vault is allowed — set state
	vault_direction = direction.normalized()
	vault_distance = 2.5 * Global.CRATE_SIZE
	vault_timer = 0.0
	vault_distance_traveled = 0.0
	is_vaulting = true

	return true

func vault_landing_should_cancel(vault_start: Vector2, vault_direction: Vector2, vault_distance: float) -> bool:
	var space_state = get_world_2d().direct_space_state
	var shape := CircleShape2D.new()
	shape.radius = 8.0  # vault landing zone footprint
	var landing_adjust := 12.0  # tweak this value as needed
	var landing_pos = vault_start + vault_direction.normalized() * (vault_distance - landing_adjust)
	var _transform := Transform2D.IDENTITY
	_transform.origin = landing_pos
	var shape_query := PhysicsShapeQueryParameters2D.new()
	shape_query.shape = shape
	shape_query.transform = _transform
	shape_query.exclude = [self]
	shape_query.collide_with_bodies = true
	# Vault-blocking obstacles go here
		# To add more, just OR in additional layers, like:
		# | Global.LAYER_PIT
		# | Global.LAYER_SPIKES
	shape_query.collision_mask = (
		Global.LAYER_SPAWNER |
		Global.LAYER_WALL |
		Global.LAYER_CRATE |
		Global.LAYER_BARREL
	)
	# start debug
	vault_debug_position = landing_pos
	vault_debug_radius = shape.radius
	vault_debug_timer = 0.15  # show for 0.15 seconds
	# stop debug
	var result = space_state.intersect_shape(shape_query, 1)
	return result.size() > 0

func should_taunt_after_vault() -> bool:
	var space_state = get_world_2d().direct_space_state
	var check_radius := 20.0

	var shape := CircleShape2D.new()
	shape.radius = check_radius

	var origin := vault_crate_drop_position  # Where crate was dropped
	var transform := Transform2D.IDENTITY
	transform.origin = origin

	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = transform
	query.collide_with_bodies = true
	query.collision_mask = Global.LAYER_ENEMY
	query.exclude = [self]

	var result := space_state.intersect_shape(query, 4)
	return result.size() > 0


func play_vault_sound():
	var sfx = vault_sfx.pick_random()
	SoundManager.play_sfx(sfx, global_position, true)

func play_taunt_sound():
	# 🔈 TODO: Replace with actual taunt voice line
	print("Taunt SFX: 'Ha ha!' or similar")
	# $TauntSoundPlayer.play()

# Allow player to vault over certain objects rather than collide
func disable_blocking_collisions():
	print("disable blocking collisions")
	set_collision_mask_value(3, false) # enemies
	set_collision_mask_value(4, false) # enemy spawners
	set_collision_mask_value(5, false) # walls
	set_collision_layer_value(1, false)  # Player


# Restore player collisions with certain obstacles after vaulting ends
func restore_blocking_collisions():
	print("enable blocking collisions")
	set_collision_mask_value(3, true) # enemies
	set_collision_mask_value(4, true) # enemy spawners
	set_collision_mask_value(5, true) # walls
	set_collision_layer_value(1, true)  # Player

# BEGIN reparenting work
func begin_carrying_crate(crate_node: Node) -> void:
	if is_vaulting or carried_crate_source != null:
		return
	
	carried_crate_source = crate_node
	carried_crate_node.visible = true
	
	# Position crate relative to player
	var offset = last_move_direction.normalized() * 15
	carried_crate_node.position = offset
	
	# Enable carried crate hitbox and sprite
	carried_crate_node.get_node("Area2D/CollisionShape2D").set_deferred("disabled", false)
	carried_crate_node.get_node("Sprite2D").z_index = Global.Z_CARRIED_CRATE_IN_FRONT
	
	# Switch to large movement collider
	move_collider_small.set_deferred("disabled", true)
	update_movement_collider()
	update_player_collision_mask()
	
	# Deactivate the source crate properly
	crate_node.deactivate()
	
	# Play crate pickup sfx
	SoundManager.play_sfx(crate_pickup_sfx.pick_random(), global_position, true)

func drop_crate(drop_position: Vector2) -> void:
	if carried_crate_source == null:
		return
	
	# Move static crate back to world
	carried_crate_source.reactivate(drop_position)
	carried_crate_source = null
	
	# Hide carried version
	carried_crate_node.visible = false
	carried_crate_node.get_node("Area2D/CollisionShape2D").disabled = true
	
	# Restore player collision shape
	update_collider_after_drop()  # 🔥 instead of manually toggling collider states
	update_player_collision_mask()
	# Optional pushback after drop
	var push_vector = -last_move_direction.normalized() * 8.0
	move_and_collide(push_vector)
	# Play crate drop sfx
	SoundManager.play_sfx(crate_drop_sfx.pick_random(), global_position, true)

	# start drop cooldown
	drop_cooldown_timer = DROP_COOLDOWN

func begin_carrying_barrel(barrel_node: Node) -> void:
	if is_vaulting or carried_crate_source != null or is_carrying_barrel:
		return
	
	static_barrel_instance = barrel_node  # Save the original static barrel
	
	# Show barrel visual carried by player (future: you will create CarriedBarrel Node2D like CarriedCrate)
	# For now, just mark that we're carrying
	is_carrying_barrel = true
	
	# Deactivate the static barrel (hide it, disable collisions)
	barrel_node.set_deferred("visible", false)
	barrel_node.set_physics_process(false)
	barrel_node.set_deferred("collision_layer", 0)
	barrel_node.set_deferred("collision_mask", 0)
	
	# [Later]: Enable CarriedBarrel visuals and damage hitbox here.
	# [Later]: Set position offset based on facing direction.
	
	print("✅ begin_carrying_barrel() completed")

func update_carried_crate_z_index() -> void:
	if not carried_crate_node.visible:
		return
	
	var sprite = carried_crate_node.get_node("Sprite2D")
	
	if last_move_direction.y < 0.1:
		# Moving up, left, right, or upward diagonals → Player above
		sprite.z_index = Global.Z_CARRIED_CRATE_BEHIND
	else:
		# Moving down or downward diagonals → Crate above
		sprite.z_index = Global.Z_CARRIED_CRATE_IN_FRONT

## Used after dropping a crate or barrel to update movement colliders
func update_collider_after_drop() -> void:
	# Re-enable normal movement collider
	move_collider_small.set_deferred("disabled", false)

	# Disable all directional colliders
	move_collider_up.disabled = true
	move_collider_down.disabled = true
	move_collider_left.disabled = true
	move_collider_right.disabled = true
	move_collider_up_right.disabled = true
	move_collider_up_left.disabled = true
	move_collider_down_right.disabled = true
	move_collider_down_left.disabled = true

func update_player_collision_mask() -> void:
	if carried_crate_source == null and not is_carrying_barrel:
		# Not carrying: ignore Crate_Static — allows overlapping for PickupDetector
		collision_mask = PLAYER_CARRY_COLLISION_MASK & ~Global.LAYER_CRATE
	else:
		# Carrying: solid crates block Player and allow vaulting
		collision_mask = PLAYER_CARRY_COLLISION_MASK


## Used every step to activate correct movement collider
func update_movement_collider() -> void:
	# If not carrying a crate or barrel, restore small collider and exit
	if carried_crate_source == null and not is_carrying_barrel:
		## move_collider_up.set_deferred("disabled", true)

		move_collider_small.set_deferred("disabled", false)

		# Disable all carry-based colliders
		move_collider_up.set_deferred("disabled", true)
		move_collider_down.set_deferred("disabled", true)
		move_collider_left.set_deferred("disabled", true)
		move_collider_right.set_deferred("disabled", true)
		move_collider_up_right.set_deferred("disabled", true)
		move_collider_up_left.set_deferred("disabled", true)
		move_collider_down_right.set_deferred("disabled", true)
		move_collider_down_left.set_deferred("disabled", true)

		return  # ✅ Nothing more to do

	# --- Otherwise, carrying a crate or barrel ---
	move_collider_small.set_deferred("disabled", true)

	# Disable all directionals first
	move_collider_up.set_deferred("disabled", true)
	move_collider_down.set_deferred("disabled", true)
	move_collider_left.set_deferred("disabled", true)
	move_collider_right.set_deferred("disabled", true)
	move_collider_up_right.set_deferred("disabled", true)
	move_collider_up_left.set_deferred("disabled", true)
	move_collider_down_right.set_deferred("disabled", true)
	move_collider_down_left.set_deferred("disabled", true)

	var dir = last_move_direction.normalized()
	var x = dir.x
	var y = dir.y

	# Prioritize diagonals
	if x > 0.5 and y < -0.5:
		move_collider_up_right.set_deferred("disabled", false)
	elif x < -0.5 and y < -0.5:
		move_collider_up_left.set_deferred("disabled", false)
	elif x > 0.5 and y > 0.5:
		move_collider_down_right.set_deferred("disabled", false)
	elif x < -0.5 and y > 0.5:
		move_collider_down_left.set_deferred("disabled", false)
	# Then cardinal
	elif y < -0.7:
		move_collider_up.set_deferred("disabled", false)
	elif y > 0.7:
		move_collider_down.set_deferred("disabled", false)
	elif x > 0.7:
		move_collider_right.set_deferred("disabled", false)
	elif x < -0.7:
		move_collider_left.set_deferred("disabled", false)



func update_carried_crate_position() -> void:
	if not carried_crate_node.visible:
		return  # No carried crate, no update needed
	
	var spacing = 15.0  # How far in front of player the crate should float
	
	if last_move_direction.length() == 0:
		return  # Standing still; no offset change
	
	var target_offset = last_move_direction.normalized() * spacing
	var smoothing_speed = 10.0  # Higher = faster snap; Lower = floatier
	
	# Smoothly interpolate towards target offset
	carried_crate_node.position = carried_crate_node.position.lerp(target_offset, smoothing_speed * get_physics_process_delta_time())


# END reparenting work

## SOUND FUNCTIONS
func play_bullet_sound():
	var sfx = bullet_sfx.pick_random()
	SoundManager.play_sfx(sfx, global_position)

## DEBUG FUNCTIONS
func _draw() -> void:
	if vault_debug_timer > 0.0:
		draw_circle(to_local(vault_debug_position), vault_debug_radius, Color.YELLOW)
