class_name GridProjection
extends RefCounted

enum ProjectionMode {
	THREE_QUARTER,
	ISOMETRIC
}

var mode: int = ProjectionMode.THREE_QUARTER

func get_axis_a() -> Vector2:
	if mode == ProjectionMode.ISOMETRIC:
		return Vector2(48.0, 24.0)
	return Vector2(54.0, 16.0)

func get_axis_b() -> Vector2:
	if mode == ProjectionMode.ISOMETRIC:
		return Vector2(-48.0, 24.0)
	return Vector2(-38.0, 38.0)

func grid_to_world(cell: Vector2i, origin: Vector2 = Vector2.ZERO) -> Vector2:
	return origin + get_axis_a() * cell.x + get_axis_b() * cell.y

func cell_center(cell: Vector2i, origin: Vector2 = Vector2.ZERO) -> Vector2:
	return grid_to_world(cell, origin) + (get_axis_a() + get_axis_b()) * 0.5

func world_to_grid(world_position: Vector2, origin: Vector2 = Vector2.ZERO) -> Vector2i:
	var local_position := world_position - origin
	var axis_a := get_axis_a()
	var axis_b := get_axis_b()
	var determinant := axis_a.x * axis_b.y - axis_a.y * axis_b.x
	if is_zero_approx(determinant):
		return Vector2i(-1, -1)
	var grid_x := (local_position.x * axis_b.y - local_position.y * axis_b.x) / determinant
	var grid_y := (axis_a.x * local_position.y - axis_a.y * local_position.x) / determinant
	return Vector2i(floori(grid_x), floori(grid_y))

func get_cell_polygon(cell: Vector2i, origin: Vector2 = Vector2.ZERO) -> PackedVector2Array:
	var point := grid_to_world(cell, origin)
	var axis_a := get_axis_a()
	var axis_b := get_axis_b()
	return PackedVector2Array([
		point,
		point + axis_a,
		point + axis_a + axis_b,
		point + axis_b
	])

func get_map_bounds(map_size: Vector2i, origin: Vector2 = Vector2.ZERO) -> Rect2:
	var points := PackedVector2Array([
		grid_to_world(Vector2i.ZERO, origin),
		grid_to_world(Vector2i(map_size.x, 0), origin),
		grid_to_world(map_size, origin),
		grid_to_world(Vector2i(0, map_size.y), origin)
	])
	var minimum := points[0]
	var maximum := points[0]
	for point in points:
		minimum.x = minf(minimum.x, point.x)
		minimum.y = minf(minimum.y, point.y)
		maximum.x = maxf(maximum.x, point.x)
		maximum.y = maxf(maximum.y, point.y)
	return Rect2(minimum, maximum - minimum)

func is_cell_inside(cell: Vector2i, map_size: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < map_size.x and cell.y < map_size.y
