extends BaseEnemy

@export var arrow_scene: PackedScene

const ATTACK_RANGE := 160.0
const MELEE_RANGE := 80.0
var fire_rate := Global.SKELETON_SHOOTER.ARROW_FIRE_RATE
var fire_cooldown := 0.0

func _ready():
	speed = Global.SKELETON_SHOOTER.SPEED
	health = Global.SKELETON_SHOOTER.HEALTH
	damage = Global.SKELETON_SHOOTER.DAMAGE
	score_value = Global.SKELETON_SHOOTER.SCORE
	is_flying = false

	super._ready()

func _physics_process(delta):
	if is_dead:
		return

	fire_cooldown = max(fire_cooldown - delta, 0.0)
	
	if not is_instance_valid(target_node):
		target_node = get_tree().get_first_node_in_group(Global.GROUPS.PLAYER)
		
	if not target_node:
		return

	var distance = global_position.distance_to(target_node.global_position)
	var has_los = has_line_of_sight()

	if distance <= MELEE_RANGE:
		# Flee from player
		var flee_vector = (global_position - target_node.global_position).normalized()
		velocity = flee_vector * speed
		move_and_slide()

	elif distance <= ATTACK_RANGE and has_los:
		velocity = Vector2.ZERO  # Stand and shoot
		if fire_cooldown <= 0.0:
			fire_arrow(target_node.global_position)
			fire_cooldown = fire_rate
	else:
		# Move toward player
		update_navigation(delta)

	update_animation()

func fire_arrow(target_pos: Vector2):
	if arrow_scene == null:
		return

	var arrow = arrow_scene.instantiate()
	arrow.global_position = global_position
	arrow.direction = (target_pos - global_position).normalized()
	get_tree().current_scene.call_deferred("add_child", arrow)

func reset() -> void:
	super.reset()
	fire_cooldown = 0.0
