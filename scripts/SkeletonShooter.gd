extends "res://scripts/BaseEnemy.gd"  # Inherits common enemy logic

@export var fire_rate: float = 1.5  # Delay between shots
@export var projectile_scene: PackedScene  # Assign the Skeleton's arrow scene
# @export var detection_range: float = 250.0  # Distance at which the Skeleton stops and shoots
@export var melee_range: float = 64.0  # ✅ Distance too close for arrows, forces melee
@export var ranged_range: float = 320.0  # ✅ Ideal range for firing arrows
@export var sidestep_distance: float = 32.0  # How far Skeleton moves after shooting
@export var wander_time: float = 2.0  # Time spent wandering when player is not in sight
var sidestep_direction: Vector2 = Vector2.ZERO  # ✅ Stores direction of sidestep
var sidestep_timer: float = 0  # ✅ Tracks how long to sidestep
@export var sidestep_duration: float = 0.4  # ✅ Duration of sidestepping movement
@onready var fire_timer = $FireTimer # Reference to the shooting timer
@onready var shoot_marker = $Marker2D  # Where arrows spawn
var shots_fired: int = 0  # Track how many shots fired before moving sideways
var wander_timer: float = 0  # Timer for random wandering

func _ready():
	super()  # Calls BaseEnemy.gd's _ready()
	health = 4  # Skeletons are tougher than Ghosts
	speed = 80.0  # Skeletons move slower
	score_value = 4
	damage = 2
	fire_timer.wait_time = fire_rate
	fire_timer.one_shot = true  # ✅ Fire once per cycle
	fire_timer.timeout.connect(shoot)  # ✅ Connect Timer to shoot function

func _process(delta):
	if not player:
		return

	var distance = global_position.distance_to(player.global_position)

	# ✅ If sidestepping, continue moving in that direction for the set duration
	if sidestep_timer > 0:
		velocity = sidestep_direction * base_speed
		sidestep_timer -= delta
		move_and_slide()
		return  # ✅ Skip other movement logic while sidestepping

	if distance <= melee_range:
		if has_line_of_sight():
			move_towards_player(delta)
			wander_timer = 0  # Reset wandering
			shots_fired = 0  # Reset shot counter
		else:
			# wander
			wander(delta)

	elif distance <= ranged_range:
		if has_line_of_sight():
			velocity = Vector2.ZERO
			if fire_timer.is_stopped():
				shoot()
				fire_timer.start()
				shots_fired += 1

			if shots_fired >= randi_range(1,2):  # ✅ Move after 1-2 shots
				sidestep()
				shots_fired = 0  # ✅ Reset counter

	else:
		# Skeleton is far from player
		if has_line_of_sight():
			move_towards_player(delta)  # ✅ Chase player
			wander_timer = 0  # ✅ Reset wandering
		else:
			wander(delta)  # ✅ Move randomly

func sidestep():
	# ✅ Pick a random direction (left or right)
	sidestep_direction = Vector2.RIGHT if randi() % 2 == 0 else Vector2.LEFT
	
	# ✅ Start sidestepping for a fixed duration
	sidestep_timer = sidestep_duration


func has_line_of_sight() -> bool:
	# ✅ Cast a ray to check if there’s a direct path to the player
	var space = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(global_position, player.global_position)
	query.collision_mask = 3  # ✅ Detect walls & obstacles

	var result = space.intersect_ray(query)
	return result.is_empty() or result.get("collider") == player  # ✅ True if no obstacle in the way

func wander(delta):
	if wander_timer <= 0:
		# ✅ Pick a random direction
		var random_direction = Vector2.RIGHT.rotated(randf_range(-PI, PI))
		velocity = random_direction * base_speed
		wander_timer = wander_time  # ✅ Set wander duration

	wander_timer -= delta  # ✅ Decrease timer
	move_and_slide()

func shoot():
	if projectile_scene:
		var arrow = projectile_scene.instantiate()
		arrow.position = shoot_marker.global_position
		arrow.direction = (player.global_position - global_position).normalized()
		get_tree().current_scene.add_child(arrow)
	else:
		print("No projectile_scene")
