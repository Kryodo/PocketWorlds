class_name WorldDebugGround
extends Node2D

var projection: GridProjection
var map_size: Vector2i = Vector2i(32, 32)
var world_id: String = "sanctuary"
var selected_cell: Vector2i = Vector2i(-1, -1)

func configure(next_projection: GridProjection, next_map_size: Vector2i, next_world_id: String) -> void:
	projection = next_projection
	map_size = next_map_size
	world_id = next_world_id
	queue_redraw()

func _draw() -> void:
	if projection == null:
		return
	for y in range(map_size.y):
		for x in range(map_size.x):
			var cell := Vector2i(x, y)
			var polygon := projection.get_cell_polygon(cell)
			draw_colored_polygon(polygon, _get_cell_color(cell))
			var outline := polygon.duplicate()
			outline.append(polygon[0])
			draw_polyline(outline, Color(0.12, 0.19, 0.16, 0.32), 1.0, true)
			if cell == selected_cell:
				var inset: PackedVector2Array = PackedVector2Array()
				var center := projection.cell_center(cell)
				for point in polygon:
					inset.append(center + (point - center) * 0.84)
				inset.append(inset[0])
				draw_polyline(inset, Color("f2d58a"), 2.0, true)

	var top_left := projection.grid_to_world(Vector2i.ZERO)
	var top_right := projection.grid_to_world(Vector2i(map_size.x, 0))
	var bottom_right := projection.grid_to_world(map_size)
	var bottom_left := projection.grid_to_world(Vector2i(0, map_size.y))
	draw_polyline(PackedVector2Array([top_left, top_right, bottom_right, bottom_left, top_left]), Color("d6c28c"), 3.0, true)

func _get_cell_color(cell: Vector2i) -> Color:
	var variation := posmod(cell.x * 7 + cell.y * 11 + cell.x * cell.y, 5)
	if world_id == "whispering_woods":
		var woods_colors: Array[Color] = [
			Color("294b3b"),
			Color("315440"),
			Color("355b45"),
			Color("2b4e3d"),
			Color("385c46")
		]
		return woods_colors[variation]
	var sanctuary_colors: Array[Color] = [
		Color("355c43"),
		Color("3a6448"),
		Color("345840"),
		Color("40694c"),
		Color("3a6047")
	]
	return sanctuary_colors[variation]
