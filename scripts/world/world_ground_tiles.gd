class_name WorldGroundTiles
extends Node2D

const TILE_GENERATOR := preload("res://scripts/world/forest_ground_tile_generator.gd")

var projection: GridProjection
var map_size: Vector2i = Vector2i(32, 32)
var world_id: String = "sanctuary"
var selected_cell: Vector2i = Vector2i(-1, -1)

var _terrain_root: Node2D
var _selection_outline: Line2D
var _texture_cache: Dictionary = {}

func configure(next_projection: GridProjection, next_map_size: Vector2i, next_world_id: String) -> void:
	projection = next_projection
	map_size = next_map_size
	world_id = next_world_id
	_rebuild_tiles()
	_update_selection_outline()

func set_selected_cell(cell: Vector2i) -> void:
	selected_cell = cell
	_update_selection_outline()

func _ensure_render_nodes() -> void:
	if not is_instance_valid(_terrain_root):
		_terrain_root = Node2D.new()
		_terrain_root.name = "TerrainSprites"
		_terrain_root.z_index = -100
		add_child(_terrain_root)
	if not is_instance_valid(_selection_outline):
		_selection_outline = Line2D.new()
		_selection_outline.name = "SelectedCellOutline"
		_selection_outline.width = 2.0
		_selection_outline.default_color = Color("f2d58a")
		_selection_outline.z_index = 100
		add_child(_selection_outline)

func _rebuild_tiles() -> void:
	if projection == null:
		return
	_ensure_render_nodes()
	for child in _terrain_root.get_children():
		child.queue_free()
	for y in range(map_size.y):
		for x in range(map_size.x):
			var cell := Vector2i(x, y)
			var asset_id := _get_tile_asset_id(cell)
			var sprite := Sprite2D.new()
			sprite.name = "%s_%d_%d" % [asset_id, x, y]
			sprite.texture = _get_tile_texture(asset_id)
			sprite.position = projection.cell_center(cell)
			sprite.scale = Vector2(0.5, 0.5)
			sprite.centered = true
			sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			sprite.z_index = 0
			_terrain_root.add_child(sprite)

func _get_tile_texture(asset_id: String) -> Texture2D:
	if _texture_cache.has(asset_id):
		return _texture_cache[asset_id] as Texture2D
	var texture_path := "res://assets/sprites/%s.png" % asset_id
	var texture: Texture2D
	if ResourceLoader.exists(texture_path):
		texture = load(texture_path) as Texture2D
	if texture == null:
		texture = ImageTexture.create_from_image(TILE_GENERATOR.create_image(asset_id))
	_texture_cache[asset_id] = texture
	return texture

func _get_tile_asset_id(cell: Vector2i) -> String:
	var variation := posmod(cell.x * 7 + cell.y * 11 + cell.x * cell.y, 100)
	if _is_path_cell(cell):
		return "forest_dirt_path_bare" if variation % 3 == 0 else "forest_dirt_path"
	if world_id == "whispering_woods":
		if variation % 17 == 0:
			return "forest_rocky_ground"
		if variation % 9 == 0:
			return "forest_wildflowers"
		if variation % 5 == 0:
			return "forest_grass_flowers"
		return "forest_grass"
	if variation % 19 == 0:
		return "forest_rocky_ground"
	if variation % 11 == 0:
		return "forest_grass_flowers"
	return "forest_grass"

func _is_path_cell(cell: Vector2i) -> bool:
	var margin := maxi(1, int(floor(float(map_size.y) * 0.12)))
	if cell.y < margin or cell.y > map_size.y - margin - 1:
		return false
	var center_x := int(roundf(float(cell.y) * 0.56 + float(map_size.x) * 0.18))
	return absi(cell.x - center_x) <= 1

func _update_selection_outline() -> void:
	if projection == null:
		return
	_ensure_render_nodes()
	if selected_cell.x < 0 or selected_cell.y < 0 or selected_cell.x >= map_size.x or selected_cell.y >= map_size.y:
		_selection_outline.clear_points()
		return
	var points := projection.get_cell_polygon(selected_cell)
	points.append(points[0])
	_selection_outline.points = points


