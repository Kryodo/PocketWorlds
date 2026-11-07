extends Node2D

const MAP_SIZE := Vector2i(10, 8)

func _ready() -> void:
	var generation: Dictionary = ForestGroundTileGenerator.generate_all_assets()
	var errors: Array = generation.get("errors", [])
	if not errors.is_empty():
		for error in errors:
			push_error(String(error))
		return

	var projection := GridProjection.new()
	var ground := WorldGroundTiles.new()
	ground.name = "GroundTiles"
	add_child(ground)
	ground.configure(projection, MAP_SIZE, "sanctuary")

	var objects_root := Node2D.new()
	objects_root.name = "WorldObjects"
	objects_root.y_sort_enabled = true
	add_child(objects_root)
	_add_asset(objects_root, projection, "old_oak", Vector2i(2, 1), Vector2i(2, 2), Vector2(214, 220))
	_add_asset(objects_root, projection, "moonpetal_plant", Vector2i(5, 2), Vector2i.ONE, Vector2(92, 100))
	_add_asset(objects_root, projection, "mossy_rock", Vector2i(7, 4), Vector2i.ONE, Vector2(118, 108))

	var camera := Camera2D.new()
	camera.name = "ReviewCamera"
	camera.position = projection.get_map_bounds(MAP_SIZE).get_center()
	camera.zoom = Vector2.ONE * 0.88
	add_child(camera)
	camera.make_current()

	var overlay := CanvasLayer.new()
	add_child(overlay)
	var title := Label.new()
	title.text = "FOREST ASSET + GROUND REVIEW"
	title.position = Vector2(24, 20)
	title.add_theme_color_override("font_color", Color("f2ead4"))
	title.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.8))
	title.add_theme_constant_override("shadow_size", 4)
	overlay.add_child(title)
	var hint := Label.new()
	hint.text = "192 × 96 SOURCE TILES  ·  96 × 48 WORLD CELLS  ·  0.5 DISPLAY SCALE"
	hint.position = Vector2(24, 48)
	hint.add_theme_color_override("font_color", Color("d6ddc9"))
	overlay.add_child(hint)

func _add_asset(
	parent: Node2D,
	projection: GridProjection,
	asset_id: String,
	cell: Vector2i,
	footprint: Vector2i,
	selection_size: Vector2
) -> void:
	var definition_path := "res://assets/definitions/%s.tres" % asset_id
	assert(ResourceLoader.exists(definition_path), "Missing review object definition: %s" % asset_id)
	var definition := load(definition_path) as PWAssetDefinition
	assert(definition != null, "Could not load review object definition: %s" % asset_id)
	var entity := WorldEntity.new()
	entity.name = asset_id
	entity.configure(definition, StringName(asset_id), cell, selection_size)
	var ground_position := projection.grid_to_world(cell)
	ground_position += projection.get_axis_a() * float(footprint.x) * 0.5
	ground_position += projection.get_axis_b() * float(footprint.y) * 0.5
	entity.set_ground_position(ground_position)
	parent.add_child(entity)

