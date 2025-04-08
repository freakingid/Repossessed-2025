extends CharacterBody2D
class_name BaseEnemy

@export var speed: float = 60.0
@export var health: int = 1
@export var damage: int = 1
@export var score_value: int = 1
@export var is_flying: bool = false

@onready var nav_agent: NavigationAgent2D = get_node_or_null("NavigationAgent2D")
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

const GEM_SCENE = preload("res://scenes/Gem.tscn")

# Direction vector mappings
var DIRECTION_ANIMATIONS := {
	"walk_n": Vector2.UP,
	"walk_ne": Vector2(1, -1).normalized(),
	"walk_e": Vector2.RIGHT,
	"walk_se": Vector2(1, 1).normalized(),
	"walk_s": Vector2.DOWN,
	"walk_sw": Vector2(-1, 1).normalized(),
	"walk_w": Vector2.LEFT,
	"walk_nw": Vector2(-1, -1).normalized()
}

var is_dead := false
var target_node: Node2D

func _ready():
	target_node = get_tree().get_first_node_in_group(Global.GROUPS.PLAYER)

func _physics_process(delta):
	if is_dead:
		return

	update_navigation(delta)
	update_animation()

func update_navigation(delta):
	if nav_agent == null:
		return

	if is_flying:
		move_directly_to_player(delta)
		return

	if nav_agent.is_navigation_finished():
		return

	nav_agent.target_position = get_player_global_position()
	var direction = nav_agent.get_next_path_position() - global_position
	if direction.length() > 1:
		velocity = direction.normalized() * speed
		move_and_slide()

func move_directly_to_player(delta):
	if target_node:
		var direction = target_node.global_position - global_position
		if direction.length() > 1:
			velocity = direction.normalized() * speed
			move_and_slide()

func get_player_global_position() -> Vector2:
	if not is_instance_valid(target_node):
		target_node = get_tree().get_first_node_in_group(Global.GROUPS.PLAYER)
	return target_node.global_position if target_node else global_position

func take_damage(amount: int) -> void:
	if is_dead:
		return

	health -= amount
	if health <= 0:
		die()

func die():
	is_dead = true

	# Drop a gem when the enemy dies
	var gem = GEM_SCENE.instantiate()
	gem.global_position = global_position
	gem.gem_power = score_value
	get_tree().current_scene.call_deferred("add_child", gem)

	queue_free()

func update_animation():
	if velocity.length() == 0:
		sprite.stop()
		return

	var dir = velocity.normalized()
	var best_match := ""
	var best_dot := -1.0

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
		sprite.play()
