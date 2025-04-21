extends KinematicMover
class_name Barrel_Rolled

@export var static_barrel_scene: PackedScene
@export var explosion_scene: PackedScene

@onready var sprite: Sprite2D = $Sprite2D
@onready var flame_sprite: AnimatedSprite2D = $FlameSprite

const ROLL_STOP_THRESHOLD := 64.0  # squared length threshold for stopping

var max_health: int = Global.BARREL.HEALTH
var health: int = Global.BARREL.HEALTH
var invincible_time := Global.BARREL.DROPWAIT
var drop_invincibility_timer := 0.0

var _initial_velocity: Vector2 = Vector2.ZERO
var _should_add_collision_exception := false


func _ready():
	# Set initial motion from drop direction
	motion_velocity = _initial_velocity
	friction = 2.5
	drop_invincibility_timer = Global.BARREL.DROPWAIT

	if _should_add_collision_exception:
		var player = get_tree().get_first_node_in_group("player")
		if player:
			add_collision_exception_with(player)

	print("Barrel_Rolled.ready and motion_velocity == ", motion_velocity)

	# Visual layering
	sprite.z_index = Global.Z_BARRELS
	if flame_sprite:
		flame_sprite.z_index = Global.Z_BARRELS_FLAME
		BarrelUtils.set_barrel_state(self, flame_sprite, health, max_health)

	# Set collision layers and masks
	collision_layer = Global.LAYER_BARREL
	collision_mask = (
		Global.LAYER_PLAYER |
		Global.LAYER_PLAYER_BULLET |
		Global.LAYER_ENEMY |
		Global.LAYER_ENEMY_PROJECTILE |
		Global.LAYER_SPAWNER |
		Global.LAYER_CRATE |
		Global.LAYER_WALL
	)

func _physics_process(delta: float) -> void:
	if drop_invincibility_timer > 0.0:
		drop_invincibility_timer -= delta

	move_with_velocity(delta)
	
	var collision = get_last_slide_collision()
	if collision:
		var collider = collision.get_collider()

		if drop_invincibility_timer <= 0.0 and collider.has_method("take_damage"):
			collider.take_damage(1)

		var normal = collision.get_normal()
		if should_bounce_off(collider):
			motion_velocity = BounceUtils.calculate_bounce(motion_velocity, normal)
			motion_velocity *= 0.9
		else:
			motion_velocity = Vector2.ZERO

	# Check for stopping condition
	if motion_velocity.length_squared() < ROLL_STOP_THRESHOLD:
		convert_to_static()

func take_damage(amount: int):
	if drop_invincibility_timer > 0.0:
		return

	health -= amount

	if flame_sprite:
		flame_sprite.play()
		BarrelUtils.update_flame(flame_sprite, health, max_health)

	if health <= 0:
		explode()

func explode():
	if explosion_scene:
		var explosion = explosion_scene.instantiate()
		explosion.global_position = global_position
		get_tree().current_scene.call_deferred("add_child", explosion)
	queue_free()

# Player calls this before kicking barrel
func set_velocity_from_drop(velocity: Vector2):
	_initial_velocity = velocity
	_should_add_collision_exception = true


func _add_player_collision_exception():
	var player = get_tree().get_first_node_in_group("player")
	if player:
		add_collision_exception_with(player)

func convert_to_static():
	if not is_inside_tree():
		return

	var static_barrel = static_barrel_scene.instantiate()
	static_barrel.global_position = global_position
	BarrelUtils.set_barrel_state(static_barrel, static_barrel.flame_sprite, health, max_health)
	get_tree().current_scene.call_deferred("add_child", static_barrel)
	queue_free()

func should_bounce_off(collider: Object) -> bool:
	return collider.is_in_group("walls") or collider.is_in_group("crates")
