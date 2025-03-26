extends "res://scripts/BaseEnemy.gd"  # Inherits common enemy logic

@export var show_debug_circles: bool = false  # ✅ Toggle this in the Inspector
@export var projectile_scene: PackedScene  # Assign the Skeleton's arrow scene

var fire_rate: float = Global.SKELETON_SHOOTER.ARROW_FIRE_RATE  # Delay between shots

var melee_range: float = 100.0  # ✅ Distance too close for arrows, forces melee
var ranged_range: float = 200.0  # ✅ Ideal range for firing arrows
var sidestep_distance: float = 16.0  # How far Skeleton moves after shooting
var wander_time: float = 2.0  # Time spent wandering when player is not in sight
var sidestep_direction: Vector2 = Vector2.ZERO  # ✅ Stores direction of sidestep
var sidestep_timer: float = 0  # ✅ Tracks how long to sidestep
var sidestep_duration: float = 0.4  # ✅ Duration of sidestepping movement
var shots_fired: int = 0  # Track how many shots fired before moving sideways
var wander_timer: float = 0  # Timer for random wandering
@onready var fire_timer = $FireTimer # Reference to the shooting timer
@onready var shoot_marker = $Marker2D  # Where arrows spawn

func _ready():
	super()  # Calls BaseEnemy.gd's _ready()
	health = Global.SKELETON_SHOOTER.HEALTH
	speed = Global.SKELETON_SHOOTER.SPEED
	score_value = Global.SKELETON_SHOOTER.SCORE
	damage = Global.SKELETON_SHOOTER.DAMAGE
	fire_timer.wait_time = fire_rate
	fire_timer.one_shot = true  # ✅ Fire once per cycle
	fire_timer.timeout.connect(shoot)  # ✅ Connect Timer to shoot function
	$Sprite2D.z_index = Global.Z_BASE_ENEMIES

func _process(delta):
	if show_debug_circles:
		queue_redraw()  # ✅ Force the debug circles to update

	if not player:
		return

	var distance = global_position.distance_to(player.global_position)

	# ✅ If sidestepping, continue moving in that direction for the set duration
	if sidestep_timer > 0:
		velocity = sidestep_direction * speed
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
		velocity = random_direction * speed
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

func _draw():
	if not show_debug_circles:
		return  # ✅ Skip drawing if debug mode is OFF

	# ✅ Draw Green circle (Melee range)
	draw_circle_outline(melee_range, Color(0, 1, 0))  # Green

	# ✅ Draw Yellow circle (Ranged attack range)
	draw_circle_outline(ranged_range, Color(1, 1, 0))  # Yellow

# ✅ Helper function to draw a circle outline
func draw_circle_outline(radius: float, color: Color):
	var points = []
	var segments = 32  # Adjust for smoother circles
	for i in range(segments):
		var angle1 = (i * TAU) / segments
		var angle2 = ((i + 1) * TAU) / segments
		var p1 = Vector2(cos(angle1), sin(angle1)) * radius
		var p2 = Vector2(cos(angle2), sin(angle2)) * radius
		points.append(p1)
		points.append(p2)
	
	# ✅ Draw the outline
	for i in range(0, points.size(), 2):
		draw_line(points[i], points[i + 1], color, 1.0)
