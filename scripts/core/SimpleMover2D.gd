@tool
extends Node2D
class_name SimpleMover2D     # ← changed name to avoid duplicate

## ───────────────────────────────── PUBLIC FIELDS ──────────────────────────
@export var velocity   : Vector2 = Vector2.ZERO
@export var bounciness : float   = 0.0          # 1 = perfect, 0 = absorb
@export var friction   : float   = 0.0          # units / sec
@export var hit_mask   : int     = 0            # collision mask for queries
@export var exclude    : Array   = []           # extra nodes to ignore

signal collided(hit: Dictionary)

## ────────────────────────────────── MAIN LOOP ─────────────────────────────
func _physics_process(delta: float) -> void:
	if velocity == Vector2.ZERO:
		return

	var target := global_position + velocity * delta
	var space  := get_world_2d().direct_space_state

	# Build query object (Godot 4.3 API)
	var q := PhysicsRayQueryParameters2D.create(global_position, target)
	q.exclude        = exclude + [self]
	q.collision_mask = hit_mask

	var result := space.intersect_ray(q)

	if result:                         # we hit something
		global_position = result.position
		velocity        = velocity.bounce(result.normal) * bounciness
		emit_signal("collided", result)
	else:                              # clear path
		global_position = target

	if friction > 0.0:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
