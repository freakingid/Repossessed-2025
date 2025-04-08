extends RigidBody2D
class_name Shrapnel

@export var damage: int = Global.SHRAPNEL.DAMAGE
@export var lifespan: float = Global.SHRAPNEL.LIFESPAN

@onready var lifespan_timer: Timer = $Timer

func _ready():
	gravity_scale = 0
	lifespan_timer.start(lifespan)
	contact_monitor = true
	max_contacts_reported = 4
	
	collision_layer = Global.LAYER_SHRAPNEL
	collision_mask = (
		Global.LAYER_PLAYER |
		Global.LAYER_ENEMY |
		Global.LAYER_WALL |
		Global.LAYER_CRATE | 
		Global.LAYER_BARREL
	)
	$Sprite2D.z_index = Global.Z_SHRAPNEL

func _on_Timer_timeout():
	queue_free()

func _on_body_entered(body: Node):
	if not body.has_method("take_damage"):
		return

	var target_health = body.health if "health" in body else damage
	var dealt = min(damage, target_health)
	body.take_damage(dealt)
	damage -= dealt

	if damage <= 0:
		queue_free()
