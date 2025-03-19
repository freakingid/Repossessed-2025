extends "res://scripts/BaseEnemy.gd"  # Inherits common enemy logic

@export var fire_rate: float = 1.5  # Delay between shots
@export var projectile_scene: PackedScene  # Assign the Skeleton's arrow scene
@export var detection_range: float = 250.0  # Distance at which the Skeleton stops and shoots

@onready var fire_timer = $FireTimer # Reference to the shooting timer
@onready var shoot_marker = $Marker2D  # Where arrows spawn

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
	if player:
		var distance = global_position.distance_to(player.global_position)

		if distance <= detection_range:
			# Stop moving and shoot if within range
			velocity = Vector2.ZERO
			if fire_timer.is_stopped():
				shoot()
				fire_timer.start()
		else:
			# Keep moving toward the player if out of range
			move_towards_player(delta)

func shoot():
	if projectile_scene:
		var arrow = projectile_scene.instantiate()
		arrow.position = shoot_marker.global_position
		arrow.direction = (player.global_position - global_position).normalized()
		get_tree().current_scene.add_child(arrow)
	else:
		print("No projectile_scene")
