extends Node2D

func _ready():
	queue_redraw()
	var tilemap_layer = $MyMap/TileMap_Floor

	if tilemap_layer and tilemap_layer is TileMapLayer:
		var used_rect = tilemap_layer.get_used_rect()  # Rect2i

		# ⬇️ Shrink by 1 tile on each side
		used_rect.position += Vector2i.ONE
		used_rect.size -= Vector2i(4, 4)
		
		var tile_size = Vector2(tilemap_layer.tile_set.tile_size)  # Cast to Vector2
		var scale = tilemap_layer.scale

		var pos = Vector2(used_rect.position.x, used_rect.position.y)
		var size = Vector2(used_rect.size.x, used_rect.size.y)

		var world_bounds = Rect2(
			pos * tile_size * scale,
			size * tile_size * scale
		)

		Global.ROOM_BOUNDS = world_bounds
	else:
		push_warning("TileMapLayer not found or incorrect type.")

func _draw():
	draw_rect(Global.ROOM_BOUNDS, Color(0, 1, 0, 0.3), false)
