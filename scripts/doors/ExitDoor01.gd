# ExitDoor.gd
extends Area2D

@export var target_scene_path: String
@export var spawn_point_name: String = "PlayerStart"

signal player_exited(target_scene_path: String, spawn_point_name: String)

func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		emit_signal("player_exited", target_scene_path, spawn_point_name)
