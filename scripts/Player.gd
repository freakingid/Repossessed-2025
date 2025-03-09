extends CharacterBody2D

@export var speed: float = 200.0  # Movement speed
@export var bullet_scene: PackedScene  # Assign Bullet.tscn
@export var fire_rate: float = 0.2  # Delay between shots
# lightning parameters
@export var lightning_radius: float = 200.0
@export var lightning_cooldown: float = 10.0
@export var stun_duration: float = 3.0

# normal shooting
var can_shoot = true # Is player shot cooldown period past?
# lightning flags
var can_use_lightning = true # Is lightning cooldown period past?
var stunned = false # Is player currently stunned from lightning use?

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

## Melee attack for player
func _on_Area2D_body_entered(body):
	if body.is_in_group("enemies"):
		body.take_damage(1)  # Deal melee damage on collision

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
