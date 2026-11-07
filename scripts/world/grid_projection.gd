class_name GridProjection
extends RefCounted

# Pocket Worlds uses a 2:1 diamond ground grid with three-quarter-view artwork.
const AXIS_A := Vector2(48.0, 24.0)
const AXIS_B := Vector2(-48.0, 24.0)

func get_axis_a() -> Vector2:
	return AXIS_A

func get_axis_b() -> Vector2:
	return AXIS_B

func grid_to_world(cell: Vector2i, origin: Vector2 = Vector2.ZERO) -> Vector2:
	return origin + AXIS_A * cell.x + AXIS_B * cell.y

func cell_center(cell: Vector2i, origin: Vector2 = Vector2.ZERO) -> Vector2:
	return grid_to_world(cell, origin) + (AXIS_A + AXIS_B) * 0.5

func world_to_grid(world_position: Vector2, origin: Vector2 = Vector2.ZERO) -> Vector2i:
	var local_position := world_position - origin
	var determinant := AXIS_A.x * AXIS_B.y - AXIS_A.y * AXIS_B.x
	if is_zero_approx(determinant):
		return Vector2i(-1, -1)
	var grid_x := (local_position.x * AXIS_B.y - local_position.y * AXIS_B.x) / determinant
	var grid_y := (AXIS_A.x * local_position.y - AXIS_A.y * local_position.x) / determinant
	return Vector2i(floori(grid_x), floori(grid_y))

func get_cell_polygon(cell: Vector2i, origin: Vector2 = Vector2.ZERO) -> PackedVector2Array:
	var point := grid_to_world(cell, origin)
	return PackedVector2Array([
		point,
		point + AXIS_A,
		point + AXIS_A + AXIS_B,
		point + AXIS_B
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
