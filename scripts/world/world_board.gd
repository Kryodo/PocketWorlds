class_name WorldBoard
extends Control

signal object_selected(object_id: String)
signal empty_tile_selected(cell: Vector2i)

const GRID_WIDTH := 9
const GRID_HEIGHT := 9
const TILE_SIZE := 54.0
const MIN_ZOOM := 0.72
const MAX_ZOOM := 1.55

const WORLD_OBJECTS := {
	"sanctuary": [
		{"id": "old_oak", "name": "Old Oak", "x": 1, "y": 2, "kind": "tree"},
		{"id": "berry_bush", "name": "Berry Bush", "x": 6, "y": 2, "kind": "bush"},
		{"id": "pond", "name": "Quiet Pond", "x": 5, "y": 4, "kind": "pond"},
		{"id": "fallen_log", "name": "Fallen Log", "x": 2, "y": 6, "kind": "log"},
		{"id": "garden_bed", "name": "Garden Bed", "x": 6, "y": 6, "kind": "garden"},
		{"id": "home_door", "name": "Little Home", "x": 4, "y": 7, "kind": "home"},
		{"id": "lantern_slot", "name": "Lantern Clearing", "x": 7, "y": 4, "kind": "lantern_slot"}
	],
	"whispering_woods": [
		{"id": "ancient_marker", "name": "Ancient Marker", "x": 4, "y": 2, "kind": "marker"},
		{"id": "moonseed_patch", "name": "Moonpetal Patch", "x": 2, "y": 6, "kind": "flowers"},
		{"id": "crystal_cache", "name": "Crystal Cache", "x": 6, "y": 6, "kind": "crystal"},
		{"id": "mossy_stone", "name": "Mossy Stone", "x": 6, "y": 3, "kind": "stone"}
	]
}

var world_id: String = "sanctuary"
var _zoom: float = 1.0
var _pan_offset: Vector2 = Vector2.ZERO
var _mouse_down := false
var _mouse_dragged := false
var _mouse_start := Vector2.ZERO
var _touch_points: Dictionary = {}
var _touch_dragged := false
var _pinching := false
var _selected_cell := Vector2i(-1, -1)

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(0, 540)
	GameState.state_changed.connect(_on_game_state_changed)
	queue_redraw()

func set_world(next_world_id: String) -> void:
	world_id = next_world_id if WORLD_OBJECTS.has(next_world_id) else "sanctuary"
	_selected_cell = Vector2i(-1, -1)
	_pan_offset = Vector2.ZERO
	_zoom = 1.0
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("172a2d"))
	var board_origin := _get_board_origin()
	var scaled_tile := TILE_SIZE * _zoom
	var board_size := Vector2(GRID_WIDTH, GRID_HEIGHT) * scaled_tile
	draw_rect(Rect2(board_origin - Vector2(9, 9), board_size + Vector2(18, 18)), Color("263b37"))

	for y in range(GRID_HEIGHT):
		for x in range(GRID_WIDTH):
			var cell := Vector2i(x, y)
			var tile_rect := Rect2(board_origin + Vector2(x, y) * scaled_tile, Vector2.ONE * scaled_tile)
			var tile_color := _get_tile_color(cell)
			draw_rect(tile_rect, tile_color)
			_draw_tile_detail(tile_rect, cell)
			if cell == _selected_cell:
				draw_rect(tile_rect.grow(-2.0 * _zoom), Color("f4d78e"), false, maxf(1.0, 2.0 * _zoom))

	for item in _get_objects_for_world():
		_draw_object(item, board_origin, scaled_tile)

func _get_tile_color(cell: Vector2i) -> Color:
	var variation := posmod(cell.x * 7 + cell.y * 11 + cell.x * cell.y, 5)
	if world_id == "whispering_woods":
		var woods_colors := [Color("345342"), Color("385a47"), Color("3b6049"), Color("31503f"), Color("3e5b49")]
		return woods_colors[variation]
	var sanctuary_colors := [Color("41664d"), Color("456d50"), Color("3d6149"), Color("496f53"), Color("42684c")]
	return sanctuary_colors[variation]

func _draw_tile_detail(tile_rect: Rect2, cell: Vector2i) -> void:
	var tile_size := tile_rect.size.x
	if world_id == "sanctuary" and ((cell.y == 4 and cell.x >= 3 and cell.x <= 6) or (cell.x == 4 and cell.y >= 4 and cell.y <= 7)):
		draw_rect(Rect2(tile_rect.position + Vector2(3, 3) * _zoom, tile_rect.size - Vector2(6, 6) * _zoom), Color("806f54"))
		draw_rect(Rect2(tile_rect.position + Vector2(5, 5) * _zoom, tile_rect.size - Vector2(10, 10) * _zoom), Color("9a8463"))
	else:
		var speckle := posmod(cell.x * 13 + cell.y * 17, 4)
		var offset := Vector2(10 + speckle * 5, 11 + posmod(cell.x + cell.y, 3) * 7) * _zoom
		draw_rect(Rect2(tile_rect.position + offset, Vector2(4, 3) * _zoom), Color("6f8b5a", 0.35))
		if posmod(cell.x * 3 + cell.y * 5, 6) == 0:
			draw_rect(Rect2(tile_rect.position + Vector2(tile_size - 14, tile_size - 15) * _zoom, Vector2(4, 4) * _zoom), Color("273f36", 0.35))
	draw_rect(tile_rect, Color("213a32", 0.22), false, maxf(1.0, _zoom))

func _get_objects_for_world() -> Array:
	return WORLD_OBJECTS.get(world_id, []).duplicate(true)

func _draw_object(item: Dictionary, board_origin: Vector2, scaled_tile: float) -> void:
	var cell := Vector2i(int(item.get("x", 0)), int(item.get("y", 0)))
	var center := board_origin + (Vector2(cell) + Vector2(0.5, 0.5)) * scaled_tile
	var s := _zoom
	var object_id := String(item.get("id", ""))
	match String(item.get("kind", "")):
		"tree":
			_draw_tree(center, s)
		"bush":
			_draw_bush(center, s)
		"pond":
			_draw_pond(center, s)
		"log":
			_draw_log(center, s)
		"garden":
			_draw_garden(center, s)
		"home":
			_draw_home(center, s)
		"lantern_slot":
			if not GameState.has_flag("lantern_placed"):
				_draw_empty_marker(center, s)
		"lantern":
			_draw_lantern(center, s)
		"marker":
			_draw_marker(center, s)
		"flowers":
			_draw_flower_patch(center, s)
		"crystal":
			_draw_crystal(center, s)
		"stone":
			_draw_stone(center, s)
	if object_id == "garden_bed" and int(GameState.get_flag("moonpetal_stage", 0)) > 0:
		_draw_moonpetal(center, s, int(GameState.get_flag("moonpetal_stage", 0)))
	if object_id == "lantern_slot" and GameState.has_flag("lantern_placed"):
		_draw_lantern(center, s)

func _on_game_state_changed() -> void:
	queue_redraw()

func _draw_tree(center: Vector2, s: float) -> void:
	draw_rect(Rect2(center + Vector2(-4, 3) * s, Vector2(8, 19) * s), Color("76503a"))
	draw_rect(Rect2(center + Vector2(-23, -24) * s, Vector2(22, 26) * s), Color("2a573e"))
	draw_rect(Rect2(center + Vector2(-11, -35) * s, Vector2(31, 30) * s), Color("356c47"))
	draw_rect(Rect2(center + Vector2(5, -25) * s, Vector2(20, 24) * s), Color("2e6041"))
	draw_rect(Rect2(center + Vector2(-3, -29) * s, Vector2(10, 8) * s), Color("638b50"))
	draw_rect(Rect2(center + Vector2(10, -18) * s, Vector2(6, 5) * s), Color("78a45a"))
	draw_rect(Rect2(center + Vector2(-18, -15) * s, Vector2(7, 6) * s), Color("49784b"))

func _draw_bush(center: Vector2, s: float) -> void:
	draw_rect(Rect2(center + Vector2(-23, -7) * s, Vector2(46, 23) * s), Color("28553e"))
	draw_rect(Rect2(center + Vector2(-17, -16) * s, Vector2(35, 25) * s), Color("3a7049"))
	draw_rect(Rect2(center + Vector2(-7, -20) * s, Vector2(22, 14) * s), Color("4b8050"))
	for berry_offset in [Vector2(-12, -2), Vector2(3, -8), Vector2(13, 2)]:
		draw_rect(Rect2(center + berry_offset * s, Vector2(5, 5) * s), Color("b95358"))

func _draw_pond(center: Vector2, s: float) -> void:
	draw_rect(Rect2(center + Vector2(-25, -15) * s, Vector2(50, 31) * s), Color("7c9c73"))
	draw_rect(Rect2(center + Vector2(-21, -12) * s, Vector2(42, 25) * s), Color("477f88"))
	draw_rect(Rect2(center + Vector2(-12, -7) * s, Vector2(14, 3) * s), Color("a2c6b1"))
	draw_rect(Rect2(center + Vector2(7, 2) * s, Vector2(8, 3) * s), Color("78a9a0"))

func _draw_log(center: Vector2, s: float) -> void:
	draw_rect(Rect2(center + Vector2(-22, -7) * s, Vector2(44, 16) * s), Color("6e4b36"))
	draw_rect(Rect2(center + Vector2(-18, -10) * s, Vector2(35, 7) * s), Color("916443"))
	draw_rect(Rect2(center + Vector2(14, -8) * s, Vector2(7, 14) * s), Color("c39a69"))
	draw_rect(Rect2(center + Vector2(-10, -5) * s, Vector2(8, 3) * s), Color("b98a5d"))

func _draw_garden(center: Vector2, s: float) -> void:
	draw_rect(Rect2(center + Vector2(-24, -15) * s, Vector2(48, 31) * s), Color("513c30"))
	draw_rect(Rect2(center + Vector2(-20, -11) * s, Vector2(40, 23) * s), Color("78543b"))
	for row in range(3):
		draw_rect(Rect2(center + Vector2(-15, -7 + row * 7) * s, Vector2(30, 2) * s), Color("a17a4d"))

func _draw_home(center: Vector2, s: float) -> void:
	draw_rect(Rect2(center + Vector2(-25, -12) * s, Vector2(50, 34) * s), Color("b28a5c"))
	draw_colored_polygon(PackedVector2Array([
		center + Vector2(-30, -12) * s,
		center + Vector2(0, -34) * s,
		center + Vector2(30, -12) * s
	]), Color("74483d"))
	draw_rect(Rect2(center + Vector2(-5, 3) * s, Vector2(11, 19) * s), Color("543b32"))
	draw_rect(Rect2(center + Vector2(-19, -5) * s, Vector2(8, 8) * s), Color("d9c58b"))
	draw_rect(Rect2(center + Vector2(11, -5) * s, Vector2(8, 8) * s), Color("d9c58b"))

func _draw_empty_marker(center: Vector2, s: float) -> void:
	draw_rect(Rect2(center + Vector2(-13, -13) * s, Vector2(26, 26) * s), Color("e3d2a1", 0.18), false, maxf(1.0, 2.0 * s))
	draw_rect(Rect2(center + Vector2(-2, -8) * s, Vector2(4, 16) * s), Color("e6d6a6"))
	draw_rect(Rect2(center + Vector2(-8, -2) * s, Vector2(16, 4) * s), Color("e6d6a6"))

func _draw_lantern(center: Vector2, s: float) -> void:
	draw_rect(Rect2(center + Vector2(-4, -17) * s, Vector2(8, 30) * s), Color("58483b"))
	draw_rect(Rect2(center + Vector2(-10, -23) * s, Vector2(20, 13) * s), Color("8b6748"))
	draw_rect(Rect2(center + Vector2(-6, -20) * s, Vector2(12, 8) * s), Color("f0cf79"))
	draw_rect(Rect2(center + Vector2(-2, -18) * s, Vector2(4, 4) * s), Color("fff0ae"))

func _draw_marker(center: Vector2, s: float) -> void:
	draw_rect(Rect2(center + Vector2(-16, -19) * s, Vector2(32, 37) * s), Color("68746b"))
	draw_rect(Rect2(center + Vector2(-11, -25) * s, Vector2(22, 10) * s), Color("879188"))
	draw_rect(Rect2(center + Vector2(-3, -13) * s, Vector2(6, 21) * s), Color("d5c58a"))
	draw_rect(Rect2(center + Vector2(-9, -6) * s, Vector2(18, 4) * s), Color("d5c58a"))
	if GameState.has_flag("marker_activated"):
		draw_rect(Rect2(center + Vector2(-4, -22) * s, Vector2(8, 3) * s), Color("a6d6c6"))

func _draw_flower_patch(center: Vector2, s: float) -> void:
	for offset in [Vector2(-13, 1), Vector2(0, -12), Vector2(14, 3)]:
		draw_rect(Rect2(center + offset * s, Vector2(5, 13) * s), Color("477449"))
		draw_rect(Rect2(center + (offset + Vector2(-3, -5)) * s, Vector2(11, 7) * s), Color("d8c3dd"))
		draw_rect(Rect2(center + (offset + Vector2(0, -3)) * s, Vector2(4, 4) * s), Color("ebd58d"))

func _draw_crystal(center: Vector2, s: float) -> void:
	draw_colored_polygon(PackedVector2Array([
		center + Vector2(0, -27) * s,
		center + Vector2(16, -4) * s,
		center + Vector2(8, 18) * s,
		center + Vector2(-11, 18) * s,
		center + Vector2(-18, -5) * s
	]), Color("8277b8"))
	draw_colored_polygon(PackedVector2Array([
		center + Vector2(0, -27) * s,
		center + Vector2(2, -3) * s,
		center + Vector2(-11, 18) * s,
		center + Vector2(-18, -5) * s
	]), Color("b0a5dc"))
	draw_rect(Rect2(center + Vector2(-2, -18) * s, Vector2(4, 10) * s), Color("e4def8"))

func _draw_stone(center: Vector2, s: float) -> void:
	draw_rect(Rect2(center + Vector2(-18, -12) * s, Vector2(36, 24) * s), Color("67746c"))
	draw_rect(Rect2(center + Vector2(-10, -18) * s, Vector2(20, 9) * s), Color("849187"))
	draw_rect(Rect2(center + Vector2(-12, 5) * s, Vector2(8, 4) * s), Color("3c5946"))

func _draw_moonpetal(center: Vector2, s: float, stage: int) -> void:
	draw_rect(Rect2(center + Vector2(-2, -25) * s, Vector2(4, 28) * s), Color("548b58"))
	draw_rect(Rect2(center + Vector2(-12, -12) * s, Vector2(11, 5) * s), Color("76a86a"))
	draw_rect(Rect2(center + Vector2(2, -17) * s, Vector2(10, 5) * s), Color("76a86a"))
	if stage >= 2:
		draw_rect(Rect2(center + Vector2(-9, -35) * s, Vector2(18, 11) * s), Color("caa6db"))
		draw_rect(Rect2(center + Vector2(-4, -32) * s, Vector2(8, 7) * s), Color("f0d18c"))

func _get_board_origin() -> Vector2:
	var board_size := Vector2(GRID_WIDTH, GRID_HEIGHT) * TILE_SIZE * _zoom
	return (size - board_size) * 0.5 + _pan_offset

func _handle_tap(position: Vector2) -> void:
	var board_origin := _get_board_origin()
	var scaled_tile := TILE_SIZE * _zoom
	var local_position := position - board_origin
	var cell := Vector2i(floori(local_position.x / scaled_tile), floori(local_position.y / scaled_tile))
	if cell.x < 0 or cell.y < 0 or cell.x >= GRID_WIDTH or cell.y >= GRID_HEIGHT:
		return
	_selected_cell = cell
	var objects := _get_objects_for_world()
	for index in range(objects.size() - 1, -1, -1):
		var item: Dictionary = objects[index]
		if _get_object_hit_rect(item, board_origin, scaled_tile).has_point(position):
			_selected_cell = Vector2i(int(item.get("x", 0)), int(item.get("y", 0)))
			object_selected.emit(String(item.get("id", "")))
			queue_redraw()
			return
	empty_tile_selected.emit(cell)
	queue_redraw()

func _get_object_hit_rect(item: Dictionary, board_origin: Vector2, scaled_tile: float) -> Rect2:
	var cell := Vector2(int(item.get("x", 0)), int(item.get("y", 0)))
	var center := board_origin + (cell + Vector2(0.5, 0.5)) * scaled_tile
	var scale_factor := scaled_tile / TILE_SIZE
	var kind := String(item.get("kind", ""))
	var bounds := Rect2(Vector2(-24, -30), Vector2(48, 54))
	match kind:
		"tree":
			bounds = Rect2(Vector2(-29, -43), Vector2(58, 69))
		"bush", "flowers":
			bounds = Rect2(Vector2(-27, -25), Vector2(54, 42))
		"pond":
			bounds = Rect2(Vector2(-29, -20), Vector2(58, 41))
		"log", "garden", "stone":
			bounds = Rect2(Vector2(-27, -22), Vector2(54, 44))
		"home":
			bounds = Rect2(Vector2(-34, -42), Vector2(68, 72))
		"marker":
			bounds = Rect2(Vector2(-23, -34), Vector2(46, 62))
		"crystal":
			bounds = Rect2(Vector2(-23, -34), Vector2(46, 58))
		"lantern", "lantern_slot":
			bounds = Rect2(Vector2(-20, -32), Vector2(40, 55))
	return Rect2(center + bounds.position * scale_factor, bounds.size * scale_factor)

func _zoom_at(screen_position: Vector2, factor: float) -> void:
	var old_zoom := _zoom
	var new_zoom := clampf(old_zoom * factor, MIN_ZOOM, MAX_ZOOM)
	if is_equal_approx(old_zoom, new_zoom):
		return
	var relative_to_center := screen_position - size * 0.5 - _pan_offset
	var world_point := relative_to_center / old_zoom
	_zoom = new_zoom
	_pan_offset = screen_position - size * 0.5 - world_point * _zoom
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_zoom_at(event.position, 1.12)
			accept_event()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_zoom_at(event.position, 0.89)
			accept_event()
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_mouse_down = true
				_mouse_dragged = false
				_mouse_start = event.position
			else:
				if _mouse_down and not _mouse_dragged:
					_handle_tap(event.position)
				_mouse_down = false
			accept_event()
	elif event is InputEventMouseMotion and _mouse_down:
		if event.position.distance_to(_mouse_start) > 7.0:
			_mouse_dragged = true
		if _mouse_dragged:
			_pan_offset += event.relative
			queue_redraw()
		accept_event()
	elif event is InputEventScreenTouch:
		if event.pressed:
			_touch_points[event.index] = event.position
			if _touch_points.size() == 1:
				_touch_dragged = false
				_pinching = false
			elif _touch_points.size() == 2:
				_pinching = true
				_touch_dragged = true
		else:
			if _touch_points.has(event.index) and _touch_points.size() == 1 and not _touch_dragged and not _pinching:
				_handle_tap(event.position)
			_touch_points.erase(event.index)
			if _touch_points.is_empty():
				_pinching = false
				_touch_dragged = false
		accept_event()
	elif event is InputEventScreenDrag:
		if _touch_points.has(event.index):
			if _touch_points.size() >= 2:
				var points_before: Array = _touch_points.values()
				var old_point_a: Vector2 = points_before[0]
				var old_point_b: Vector2 = points_before[1]
				var old_distance: float = old_point_a.distance_to(old_point_b)
				_touch_points[event.index] = event.position
				var points_after: Array = _touch_points.values()
				var new_point_a: Vector2 = points_after[0]
				var new_point_b: Vector2 = points_after[1]
				var new_distance: float = new_point_a.distance_to(new_point_b)
				if old_distance > 1.0 and new_distance > 1.0:
					_zoom_at((points_after[0] + points_after[1]) * 0.5, new_distance / old_distance)
				_pinching = true
				_touch_dragged = true
			else:
				_touch_points[event.index] = event.position
				_pan_offset += event.relative
				_touch_dragged = true
				queue_redraw()
		accept_event()
