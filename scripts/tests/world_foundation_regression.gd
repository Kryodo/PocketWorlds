extends Node

func _ready() -> void:
	_test_projection_round_trip()
	_test_grid_footprints()
	print("WORLD FOUNDATION REGRESSION PASS")
	get_tree().quit()

func _test_projection_round_trip() -> void:
	var projection := GridProjection.new()
	for y in range(32):
		for x in range(32):
			var expected := Vector2i(x, y)
			var world_center := projection.cell_center(expected)
			var actual := projection.world_to_grid(world_center)
			assert(actual == expected, "Grid projection failed round-trip at %s." % expected)
	var bounds := projection.get_map_bounds(Vector2i(32, 32))
	assert(bounds.size.x > 0.0 and bounds.size.y > 0.0, "Projection returned invalid map bounds.")

func _test_grid_footprints() -> void:
	var grid := WorldGridData.new()
	grid.configure(Vector2i(8, 8))
	var oak_footprint: Array[Vector2i] = [
		Vector2i.ZERO,
		Vector2i(1, 0),
		Vector2i(0, 1),
		Vector2i(1, 1)
	]
	assert(grid.can_place(Vector2i(2, 2), oak_footprint), "An empty 2x2 footprint should be placeable.")
	assert(grid.occupy(&"oak_test", Vector2i(2, 2), oak_footprint), "The oak footprint should occupy successfully.")
	assert(not grid.can_place(Vector2i(3, 3), [Vector2i.ZERO]), "An occupied cell should reject another object.")
	assert(grid.can_place(Vector2i(2, 2), oak_footprint, &"oak_test"), "An object should be allowed to validate its own current footprint.")
	assert(not grid.can_place(Vector2i(7, 7), oak_footprint), "A footprint extending beyond the map should be rejected.")
	grid.release(&"oak_test")
	assert(grid.can_place(Vector2i(2, 2), oak_footprint), "Released cells should become available again.")

	var irregular_footprint: Array[Vector2i] = [
		Vector2i.ZERO,
		Vector2i(1, 0),
		Vector2i(0, 1)
	]
	assert(grid.occupy(&"stone_test", Vector2i(4, 4), irregular_footprint), "An irregular footprint should occupy successfully.")
	assert(grid.get_occupant(Vector2i(5, 4)) == &"stone_test", "Irregular footprint cells should be tracked.")
	assert(grid.get_occupant(Vector2i(5, 5)).is_empty(), "Unused cells inside the irregular footprint bounding box should remain free.")
