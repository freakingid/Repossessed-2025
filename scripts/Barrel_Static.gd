extends StaticBody2D

@export var carried_scene: PackedScene
@export var max_health: int = 10
var health: int
@onready var sprite: Sprite2D = $Sprite2D

func _ready():
	health = max_health
	collision_layer = Global.LAYER_BARREL
	collision_mask = (
		Global.LAYER_PLAYER |
		Global.LAYER_PLAYER_BULLET |
		Global.LAYER_ENEMY |
		Global.LAYER_ENEMY_PROJECTILE |
		Global.LAYER_SPAWNER
	)
	add_to_group("barrels_static")
	$Sprite2D.z_index = Global.Z_PLAYER_AND_CRATES

func pickup(player):
	visible = false
	collision_layer = 0
	collision_mask = 0
	set_physics_process(false)

	var carried = carried_scene.instantiate()
	carried.player = player
	player.carried_barrel_instance = carried
	get_tree().current_scene.add_child(carried)

func reactivate(position: Vector2):
	global_position = position
	visible = true
	collision_layer = Global.LAYER_BARREL
	collision_mask = Global.LAYER_PLAYER | Global.LAYER_PLAYER_BULLET | Global.LAYER_ENEMY
	set_physics_process(true)
	health = max_health
