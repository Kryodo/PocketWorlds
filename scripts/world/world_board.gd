class_name WorldBoard
extends Control

signal object_selected(object_id: String)
signal empty_tile_selected(cell: Vector2i)

const MAP_SIZE := Vector2i(32, 32)
const MIN_ZOOM := 0.45
const MAX_ZOOM := 1.65

const WORLD_OBJECTS := {
	"sanctuary": [
		{"id": "old_oak", "name": "Old Oak", "x": 8, "y": 7, "asset_id": "old_oak", "kind": "tree", "footprint_size": Vector2i(2, 2), "selection_size": Vector2(214, 220), "visual_scale": 1.45},
		{"id": "berry_bush", "name": "Berry Bush", "x": 19, "y": 7, "kind": "bush", "footprint_size": Vector2i(2, 2), "selection_size": Vector2(82, 62), "visual_scale": 1.2},
		{"id": "moonpetal_plant", "name": "Moonpetal Plant", "x": 24, "y": 14, "asset_id": "moonpetal_plant", "kind": "plant", "footprint_size": Vector2i(1, 1), "selection_size": Vector2(92, 100)},
		{"id": "pond", "name": "Quiet Pond", "x": 15, "y": 15, "kind": "pond", "footprint_size": Vector2i(3, 2), "selection_size": Vector2(128, 74)},
		{"id": "fallen_log", "name": "Fallen Log", "x": 7, "y": 22, "kind": "log", "footprint_size": Vector2i(2, 1), "selection_size": Vector2(82, 42)},
		{"id": "garden_bed", "name": "Garden Bed", "x": 19, "y": 22, "kind": "garden", "footprint_size": Vector2i(2, 2), "selection_size": Vector2(76, 54)},
		{"id": "home_door", "name": "Little Home", "x": 12, "y": 27, "kind": "home", "footprint_size": Vector2i(3, 2), "selection_size": Vector2(104, 124)},
		{"id": "lantern_slot", "name": "Lantern Clearing", "x": 24, "y": 18, "kind": "lantern_slot", "footprint_size": Vector2i(1, 1), "selection_size": Vector2(54, 70)}
	],
	"whispering_woods": [
		{"id": "ancient_marker", "name": "Ancient Marker", "x": 16, "y": 7, "kind": "marker", "footprint_size": Vector2i(1, 1), "selection_size": Vector2(76, 90)},
		{"id": "moonseed_patch", "name": "Moonpetal Patch", "x": 8, "y": 22, "kind": "flowers", "footprint_size": Vector2i(2, 2), "selection_size": Vector2(94, 66)},
		{"id": "crystal_cache", "name": "Crystal Cache", "x": 22, "y": 22, "kind": "crystal", "footprint_size": Vector2i(1, 1), "selection_size": Vector2(70, 86)},
		{"id": "mossy_stone", "name": "Mossy Stone", "x": 22, "y": 12, "asset_id": "mossy_rock", "kind": "stone", "footprint_size": Vector2i(1, 1), "selection_size": Vector2(118, 108)}
	]
}

var world_id: String = "sanctuary"
var _projection: GridProjection
var _grid_data: WorldGridData
var _world_viewport: SubViewport
var _camera: Camera2D
var _camera_controller: WorldCameraController
var _ground: WorldGroundTiles
var _objects_root: Node2D
var _input_overlay: Control
var _projection_label: Label
var _entity_nodes: Array[Node2D] = []
var _selected_cell: Vector2i = Vector2i(-1, -1)
var _touch_points: Dictionary = {}
var _mouse_down: bool = false
var _mouse_dragged: bool = false
var _mouse_start: Vector2 = Vector2.ZERO
var _touch_had_multi: bool = false

func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_projection = GridProjection.new()
	_grid_data = WorldGridData.new()
	_grid_data.configure(MAP_SIZE)
	_build_world_viewport()
	_build_input_overlay()
	_apply_world()
	if not GameState.state_changed.is_connected(_on_game_state_changed):
		GameState.state_changed.connect(_on_game_state_changed)

func _build_world_viewport() -> void:
	var viewport_container := SubViewportContainer.new()
	viewport_container.name = "WorldViewportContainer"
	viewport_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	viewport_container.stretch = true
	viewport_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(viewport_container)

	_world_viewport = SubViewport.new()
	_world_viewport.name = "WorldViewport"
	_world_viewport.size = Vector2i(1280, 720)
	_world_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_world_viewport.transparent_bg = false
	viewport_container.add_child(_world_viewport)

	var world_root := Node2D.new()
	world_root.name = "WorldRoot"
	_world_viewport.add_child(world_root)

	_ground = WorldGroundTiles.new()
	_ground.name = "GroundTiles"
	world_root.add_child(_ground)

	_objects_root = Node2D.new()
	_objects_root.name = "WorldEntities"
	_objects_root.y_sort_enabled = true
	world_root.add_child(_objects_root)

	_camera = Camera2D.new()
	_camera.name = "WorldCamera"
	_camera.enabled = true
	_camera.zoom = Vector2.ONE * 0.9
	_world_viewport.add_child(_camera)
	_camera.make_current()

	_camera_controller = WorldCameraController.new()
	_camera_controller.configure(_camera, _world_viewport, MIN_ZOOM, MAX_ZOOM)

func _build_input_overlay() -> void:
	_input_overlay = Control.new()
	_input_overlay.name = "InputOverlay"
	_input_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_input_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_input_overlay.gui_input.connect(_on_gui_input)
	add_child(_input_overlay)

	_projection_label = Label.new()
	_projection_label.text = "3/4 TOP-DOWN · 32 × 32 FOREST WORLD"
	_projection_label.position = Vector2(14, 66)
	_projection_label.add_theme_color_override("font_color", Color("f2ead4"))
	_projection_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.75))
	_projection_label.add_theme_constant_override("shadow_size", 4)
	_projection_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_input_overlay.add_child(_projection_label)

	var hint := Label.new()
	hint.text = "DRAG TO PAN  ·  PINCH / WHEEL TO ZOOM  ·  TAP TO INSPECT"
	hint.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	hint.position = Vector2(-350, -30)
	hint.add_theme_color_override("font_color", Color("e9dfc9"))
	hint.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	hint.add_theme_constant_override("shadow_size", 4)
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_input_overlay.add_child(hint)

func set_world(next_world_id: String) -> void:
	world_id = next_world_id if WORLD_OBJECTS.has(next_world_id) else "sanctuary"
	_selected_cell = Vector2i(-1, -1)
	_apply_world()
	_center_camera()

func _apply_world() -> void:
	if _projection == null or _ground == null:
		return
	_ground.configure(_projection, MAP_SIZE, world_id)
	_rebuild_entities()
	var bounds := _projection.get_map_bounds(MAP_SIZE)
	_camera_controller.set_world_limits(bounds, 110.0)

func _rebuild_entities() -> void:
	for child in _objects_root.get_children():
		child.queue_free()
	_entity_nodes.clear()
	_grid_data.configure(MAP_SIZE)
	var objects: Array = WORLD_OBJECTS.get(world_id, []).duplicate(true)
	for data in objects:
		var item: Dictionary = data
		if String(item.get("id", "")) == "lantern_slot" and GameState.has_flag("lantern_placed"):
			item["kind"] = "lantern"

		var object_id := String(item.get("id", "WorldObject"))
		var cell := Vector2i(int(item.get("x", 0)), int(item.get("y", 0)))
		var definition: PWAssetDefinition = null
		var asset_id := String(item.get("asset_id", ""))
		if not asset_id.is_empty():
			var definition_path := "res://assets/definitions/%s.tres" % asset_id
			if ResourceLoader.exists(definition_path):
				definition = load(definition_path) as PWAssetDefinition

		var footprint_size: Vector2i = item.get("footprint_size", Vector2i.ONE)
		if definition != null:
			footprint_size = definition.footprint_size
		var footprint_offsets: Array[Vector2i] = []
		if definition != null and not definition.footprint_offsets.is_empty():
			for offset in definition.footprint_offsets:
				footprint_offsets.append(offset)
		else:
			for footprint_y in range(maxi(1, footprint_size.y)):
				for footprint_x in range(maxi(1, footprint_size.x)):
					footprint_offsets.append(Vector2i(footprint_x, footprint_y))
		if not _grid_data.occupy(StringName(object_id), cell, footprint_offsets):
			push_warning("World object footprint could not be occupied: %s" % object_id)

		var ground_position := _get_footprint_ground_position(cell, footprint_size)
		var selection_size: Vector2 = item.get("selection_size", Vector2(80.0, 90.0))
		if definition != null:
			var entity := WorldEntity.new()
			entity.name = object_id
			entity.configure(definition, StringName(object_id), cell, selection_size)
			entity.set_ground_position(ground_position)
			_objects_root.add_child(entity)
			_entity_nodes.append(entity)
		else:
			var debug_entity := WorldDebugObject.new()
			debug_entity.name = object_id
			debug_entity.configure(item)
			debug_entity.position = ground_position
			_objects_root.add_child(debug_entity)
			_entity_nodes.append(debug_entity)

func _get_footprint_ground_position(cell: Vector2i, footprint_size: Vector2i) -> Vector2:
	var width := float(maxi(1, footprint_size.x))
	var height := float(maxi(1, footprint_size.y))
	return (
		_projection.grid_to_world(cell)
		+ _projection.get_axis_a() * width * 0.5
		+ _projection.get_axis_b() * height * 0.5
	)

func _center_camera() -> void:
	if _camera == null:
		return
	var bounds := _projection.get_map_bounds(MAP_SIZE)
	_camera_controller.center_on(bounds.get_center())
	_camera_controller.reset_zoom(0.9)

func _screen_to_world(screen_position: Vector2) -> Vector2:
	return _camera_controller.screen_to_world(screen_position)

func _handle_tap(screen_position: Vector2) -> void:
	var world_position := _screen_to_world(screen_position)
	for index in range(_entity_nodes.size() - 1, -1, -1):
		var entity := _entity_nodes[index]
		if entity is WorldEntity:
			var asset_entity := entity as WorldEntity
			if not asset_entity.interactable:
				continue
			if asset_entity.get_selection_rect().has_point(asset_entity.to_local(world_position)):
				_select_entity(asset_entity)
				return
		elif entity is WorldDebugObject:
			var debug_entity := entity as WorldDebugObject
			if not debug_entity.interactable:
				continue
			if debug_entity.get_selection_rect().has_point(debug_entity.to_local(world_position)):
				_select_entity(debug_entity)
				return

	var cell := _projection.world_to_grid(world_position)
	if not _grid_data.is_cell_inside(cell):
		return
	_selected_cell = cell
	for entity in _entity_nodes:
		if entity is WorldEntity:
			(entity as WorldEntity).selected = false
		elif entity is WorldDebugObject:
			(entity as WorldDebugObject).selected = false
		entity.queue_redraw()
	_ground.set_selected_cell(cell)
	empty_tile_selected.emit(cell)

func _select_entity(entity: Node2D) -> void:
	for item in _entity_nodes:
		if item is WorldEntity:
			(item as WorldEntity).selected = item == entity
		elif item is WorldDebugObject:
			(item as WorldDebugObject).selected = item == entity
		item.queue_redraw()
	_selected_cell = Vector2i(-1, -1)
	_ground.set_selected_cell(_selected_cell)
	var object_id := ""
	if entity is WorldEntity:
		object_id = (entity as WorldEntity).object_id
	elif entity is WorldDebugObject:
		object_id = (entity as WorldDebugObject).object_id
	object_selected.emit(object_id)

func _on_game_state_changed() -> void:
	if world_id == "sanctuary":
		_rebuild_entities()

func _zoom_at(screen_position: Vector2, factor: float) -> void:
	_camera_controller.zoom_at(screen_position, factor)

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_zoom_at(event.position, 1.12)
			_input_overlay.accept_event()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_zoom_at(event.position, 0.89)
			_input_overlay.accept_event()
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_mouse_down = true
				_mouse_dragged = false
				_mouse_start = event.position
			else:
				if _mouse_down and not _mouse_dragged:
					_handle_tap(event.position)
				_mouse_down = false
			_input_overlay.accept_event()
	elif event is InputEventMouseMotion and _mouse_down:
		if event.position.distance_to(_mouse_start) > 7.0:
			_mouse_dragged = true
		if _mouse_dragged:
			_camera_controller.pan_by_screen_delta(event.relative)
		_input_overlay.accept_event()
	elif event is InputEventScreenTouch:
		if event.pressed:
			_touch_points[event.index] = event.position
			if _touch_points.size() >= 2:
				_touch_had_multi = true
		else:
			if _touch_points.size() == 1 and not _touch_had_multi:
				if _touch_points.has(event.index):
					_handle_tap(event.position)
			_touch_points.erase(event.index)
			if _touch_points.is_empty():
				_touch_had_multi = false
		_input_overlay.accept_event()
	elif event is InputEventScreenDrag:
		if _touch_points.has(event.index):
			var touch_ids: Array = _touch_points.keys()
			touch_ids.sort()
			if touch_ids.size() >= 2:
				var old_a: Vector2 = _touch_points[touch_ids[0]]
				var old_b: Vector2 = _touch_points[touch_ids[1]]
				var old_midpoint := (old_a + old_b) * 0.5
				var old_distance := old_a.distance_to(old_b)
				_touch_points[event.index] = event.position
				var new_a: Vector2 = _touch_points[touch_ids[0]]
				var new_b: Vector2 = _touch_points[touch_ids[1]]
				var new_midpoint := (new_a + new_b) * 0.5
				var new_distance := new_a.distance_to(new_b)
				_camera_controller.pan_by_screen_delta(new_midpoint - old_midpoint)
				if old_distance > 1.0 and new_distance > 1.0:
					_zoom_at(new_midpoint, new_distance / old_distance)
			else:
				_touch_points[event.index] = event.position
				_camera_controller.pan_by_screen_delta(event.relative)
			_touch_had_multi = _touch_had_multi or touch_ids.size() >= 2
		_input_overlay.accept_event()
