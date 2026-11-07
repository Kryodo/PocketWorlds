class_name WorldGridData
extends RefCounted

var map_size: Vector2i = Vector2i(32, 32)
var _occupancy: Dictionary = {}

func configure(next_map_size: Vector2i) -> void:
	map_size = Vector2i(maxi(1, next_map_size.x), maxi(1, next_map_size.y))
	_occupancy.clear()

func get_footprint_cells(anchor: Vector2i, footprint_offsets: Array[Vector2i]) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	if footprint_offsets.is_empty():
		result.append(anchor)
		return result
	for offset in footprint_offsets:
		result.append(anchor + offset)
	return result

func can_place(anchor: Vector2i, footprint_offsets: Array[Vector2i], ignore_instance_id: StringName = &"") -> bool:
	for cell in get_footprint_cells(anchor, footprint_offsets):
		if cell.x < 0 or cell.y < 0 or cell.x >= map_size.x or cell.y >= map_size.y:
			return false
		var occupant := StringName(_occupancy.get(cell, &""))
		if not occupant.is_empty() and occupant != ignore_instance_id:
			return false
	return true

func occupy(instance_id: StringName, anchor: Vector2i, footprint_offsets: Array[Vector2i]) -> bool:
	if instance_id.is_empty() or not can_place(anchor, footprint_offsets):
		return false
	for cell in get_footprint_cells(anchor, footprint_offsets):
		_occupancy[cell] = instance_id
	return true

func release(instance_id: StringName) -> void:
	var cells_to_clear: Array[Vector2i] = []
	for cell in _occupancy.keys():
		if StringName(_occupancy[cell]) == instance_id:
			cells_to_clear.append(cell)
	for cell in cells_to_clear:
		_occupancy.erase(cell)

func get_occupant(cell: Vector2i) -> StringName:
	return StringName(_occupancy.get(cell, &""))

func is_cell_inside(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < map_size.x and cell.y < map_size.y
