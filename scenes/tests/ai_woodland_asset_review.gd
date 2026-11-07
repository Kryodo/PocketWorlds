extends Node2D

const MAP_SIZE := Vector2i(7, 5)
const PANEL_GAP := 120.0
const IMPORTER := preload("res://scripts/world/ai_woodland_asset_importer.gd")

func _ready() -> void:
	# Refresh this isolated experiment from the untouched JPG on each review run.
	var result: Dictionary = IMPORTER.generate_all_assets(true)
	var errors: Array = result.get("errors", [])
	if not errors.is_empty():
		for error in errors:
			push_error(String(error))
		return

	var projection := GridProjection.new()
	var bounds := projection.get_map_bounds(MAP_SIZE)
	var right_offset := Vector2(bounds.size.x + PANEL_GAP, 0.0)

	_build_current_panel(projection)
	_build_ai_panel(projection, right_offset)
	_build_camera(bounds, right_offset)
	_build_overlay()

	print(
		"AI WOODLAND ASSET REVIEW READY | generated=%d | skipped=%d" % [
			(result.get("generated", []) as Array).size(),
			(result.get("skipped", []) as Array).size()
		]
	)

func _build_current_panel(projection: GridProjection) -> void:
	var panel := Node2D.new()
	panel.name = "CurrentAssets"
	add_child(panel)

	var ground := WorldGroundTiles.new()
	ground.name = "CurrentGround"
	panel.add_child(ground)
	ground.configure(projection, MAP_SIZE, "sanctuary")

	var objects_root := Node2D.new()
	objects_root.name = "CurrentObjects"
	objects_root.y_sort_enabled = true
	panel.add_child(objects_root)

	_add_existing_asset(objects_root, projection, "old_oak", Vector2i(0, 1), Vector2i(2, 2))
	_add_existing_asset(objects_root, projection, "moonpetal_plant", Vector2i(5, 0), Vector2i.ONE)
	_add_existing_asset(objects_root, projection, "mossy_rock", Vector2i(3, 3), Vector2i.ONE)

func _build_ai_panel(projection: GridProjection, panel_offset: Vector2) -> void:
	var panel := Node2D.new()
	panel.name = "GeminiWoodlandAssets"
	panel.position = panel_offset
	add_child(panel)

	var ground := WorldGroundTiles.new()
	ground.name = "AIComparisonGround"
	panel.add_child(ground)
	ground.configure(projection, MAP_SIZE, "sanctuary")

	var objects_root := Node2D.new()
	objects_root.name = "ImportedObjects"
	objects_root.y_sort_enabled = true
	panel.add_child(objects_root)

	var placements: Dictionary = {
		"ai_woodland_oak": Vector2i(0, 1),
		"ai_woodland_bush": Vector2i(4, 0),
		"ai_woodland_flowering_plant": Vector2i(6, 0),
		"ai_woodland_leafy_plant": Vector2i(6, 3),
		"ai_woodland_mossy_boulder": Vector2i(4, 3),
		"ai_woodland_fallen_log": Vector2i(1, 3)
	}

	for spec in IMPORTER.get_asset_specs():
		var asset_id := String(spec["id"])
		var cell: Vector2i = placements[asset_id]
		_add_imported_asset(objects_root, projection, asset_id, cell)

func _add_existing_asset(
	parent: Node2D,
	projection: GridProjection,
	asset_id: String,
	cell: Vector2i,
	footprint: Vector2i
) -> void:
	var definition_path := "res://assets/definitions/%s.tres" % asset_id
	assert(ResourceLoader.exists(definition_path), "Missing current asset definition: %s" % asset_id)
	var definition := load(definition_path) as PWAssetDefinition
	assert(definition != null, "Could not load current asset definition: %s" % asset_id)

	var entity := WorldEntity.new()
	entity.name = asset_id
	entity.configure(definition, StringName(asset_id), cell, Vector2(150.0, 180.0))
	entity.set_ground_position(_get_ground_position(projection, cell, footprint))
	parent.add_child(entity)

func _add_imported_asset(
	parent: Node2D,
	projection: GridProjection,
	asset_id: String,
	cell: Vector2i
) -> void:
	var definition_path := "res://assets/definitions/%s.tres" % asset_id
	assert(ResourceLoader.exists(definition_path), "Missing imported asset definition: %s" % asset_id)
	var definition := load(definition_path) as PWAssetDefinition
	assert(definition != null, "Could not load imported asset definition: %s" % asset_id)

	var image := IMPORTER.load_generated_image(asset_id)
	assert(image.get_width() > 1 and image.get_height() > 1, "Could not load extracted PNG: %s" % asset_id)
	assert(image.get_pixel(0, 0).a < 0.10, "Cyan background was not removed from asset corner: %s" % asset_id)
	var visible_bounds := image.get_used_rect()
	assert(visible_bounds.size.x > 8 and visible_bounds.size.y > 8, "Extracted artwork has no usable visible bounds: %s" % asset_id)
	assert(
		definition.texture_filter_mode == PWAssetDefinition.TextureFilterMode.LINEAR,
		"Imported toon asset must use LINEAR filtering: %s" % asset_id
	)

	var texture := ImageTexture.create_from_image(image)

	var object_root := Node2D.new()
	object_root.name = asset_id
	object_root.position = _get_ground_position(projection, cell, definition.footprint_size)
	object_root.z_index = definition.sort_z_index

	var sprite := Sprite2D.new()
	sprite.name = "Artwork"
	sprite.texture = texture
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	sprite.scale = definition.sprite_scale
	sprite.position = (
		Vector2(image.get_size()) * 0.5 - definition.ground_anchor_px
	) * definition.sprite_scale + definition.visual_offset
	object_root.add_child(sprite)
	parent.add_child(object_root)

func _get_ground_position(
	projection: GridProjection,
	cell: Vector2i,
	footprint: Vector2i
) -> Vector2:
	return (
		projection.grid_to_world(cell)
		+ projection.get_axis_a() * float(footprint.x) * 0.5
		+ projection.get_axis_b() * float(footprint.y) * 0.5
	)

func _build_camera(bounds: Rect2, panel_offset: Vector2) -> void:
	var combined_left := bounds.position.x
	var combined_right := panel_offset.x + bounds.end.x
	var center_x := (combined_left + combined_right) * 0.5

	var camera := Camera2D.new()
	camera.name = "AssetComparisonCamera"
	camera.position = Vector2(center_x, 80.0)
	camera.zoom = Vector2.ONE * 0.90
	add_child(camera)
	camera.make_current()

func _build_overlay() -> void:
	var layer := CanvasLayer.new()
	layer.name = "ReviewOverlay"
	add_child(layer)

	_add_label(layer, "GEMINI ASSET IMPORT REVIEW", Vector2(24, 14), 24, Color("f4ead5"))
	_add_label(layer, "CURRENT ASSETS", Vector2(24, 54), 19, Color("e9d8b8"))
	_add_label(layer, "GEMINI — EXTRACTED PNGS", Vector2(660, 54), 19, Color("c6ed9c"))
	_add_label(
		layer,
		"Existing sprites + current ground renderer",
		Vector2(24, 80),
		13,
		Color("c4c5b7")
	)
	_add_label(
		layer,
		"6 isolated objects + same ground + linear filtering",
		Vector2(660, 80),
		13,
		Color("c4d6b8")
	)

	var divider := ColorRect.new()
	divider.position = Vector2(638, 112)
	divider.size = Vector2(2, 500)
	divider.color = Color(0.75, 0.80, 0.68, 0.42)
	layer.add_child(divider)

	_add_label(
		layer,
		"SAME 2:1 GRID  ·  ORIGINAL JPG PRESERVED  ·  GENERATED ASSETS ARE ISOLATED",
		Vector2(24, 680),
		13,
		Color("e5dfcf")
	)

func _add_label(
	parent: Node,
	value: String,
	position: Vector2,
	font_size: int,
	color: Color
) -> void:
	var label := Label.new()
	label.text = value
	label.position = position
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.85))
	label.add_theme_constant_override("shadow_size", 3)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
