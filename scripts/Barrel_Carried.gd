extends CharacterBody2D

var player: Node2D

@onready var sprite: Sprite2D = $Sprite2D

func _ready():
	collision_layer = Global.LAYER_BARREL
	collision_mask = (
		Global.LAYER_PLAYER |
		Global.LAYER_WALL |
		Global.LAYER_ENEMY |
		Global.LAYER_SPAWNER
	)
	add_to_group("barrels_carried")

func _physics_process(_delta):
	if not player:
		return

	# Position barrel slightly in front of the player
	var offset = player.last_move_direction.normalized() * 10
	global_position = player.global_position + offset

	# Adjust z_index to appear in front or behind player
	if player.last_move_direction.y > 0:
		sprite.z_index = Global.Z_PLAYER_AND_CRATES + 1
	else:
		sprite.z_index = Global.Z_PLAYER_AND_CRATES - 1
