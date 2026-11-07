extends Node2D

const MAP_SIZE := Vector2i(7, 5)
const PANEL_GAP := 120.0
const GENERATOR := preload("res://scripts/world/artistic_validation_asset_generator.gd")

func _ready() -> void:
	var generation: Dictionary = GENERATOR.generate_all_assets()
	var generation_errors: Array = generation.get("errors", [])
	if not generation_errors.is_empty():
		for error in generation_errors:
			push_error(String(error))
		return

	var projection := GridProjection.new()
	var map_bounds := projection.get_map_bounds(MAP_SIZE)
	var validation_offset := Vector2(map_bounds.size.x + PANEL_GAP, 0.0)

	_build_current_panel(projection)
	_build_validation_panel(projection, map_bounds, validation_offset)
	_build_camera(map_bounds, validation_offset)
	_build_overlay(validation_offset)
	print("ARTISTIC VALIDATION ASSETS READY")

func _build_current_panel(projection: GridProjection) -> void:
	var panel := Node2D.new()
	panel.name = "CurrentBaseline"
	add_child(panel)

	var ground := WorldGroundTiles.new()
	ground.name = "CurrentGroundTiles"
	panel.add_child(ground)
	ground.configure(projection, MAP_SIZE, "sanctuary")

	var objects_root := Node2D.new()
	objects_root.name = "CurrentObjects"
	objects_root.y_sort_enabled = true
	panel.add_child(objects_root)

	_add_existing_asset(objects_root, projection, "old_oak", Vector2i(2, 1), Vector2i(2, 2))
	_add_existing_asset(objects_root, projection, "moonpetal_plant", Vector2i(5, 1), Vector2i.ONE)
	_add_existing_asset(objects_root, projection, "mossy_rock", Vector2i(5, 3), Vector2i.ONE)

func _build_validation_panel(
	projection: GridProjection,
	map_bounds: Rect2,
	panel_offset: Vector2
) -> void:
	var panel := Node2D.new()
	panel.name = "PixelClusterStudy"
	panel.position = panel_offset
	add_child(panel)

	var ground_image := _load_or_create_image(
		"res://assets/sprites/validation_ground_patch.png",
		GENERATOR.create_ground_patch_image(MAP_SIZE)
	)
	var ground_texture := ImageTexture.create_from_image(ground_image)
	var ground_sprite := Sprite2D.new()
	ground_sprite.name = "ContinuousGroundPatch"
	ground_sprite.texture = ground_texture
	ground_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	ground_sprite.position = map_bounds.get_center()
	ground_sprite.z_index = -100
	panel.add_child(ground_sprite)

	var objects_root := Node2D.new()
	objects_root.name = "ValidationObjects"
	objects_root.y_sort_enabled = true
	panel.add_child(objects_root)

	_add_validation_asset(objects_root, projection, "validation_oak", Vector2i(2, 1))
	_add_validation_asset(objects_root, projection, "validation_plant", Vector2i(5, 1))
	_add_validation_asset(objects_root, projection, "validation_rock", Vector2i(5, 3))

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
	entity.configure(definition, StringName(asset_id), cell, Vector2(120.0, 120.0))
	entity.set_ground_position(_get_ground_position(projection, cell, footprint))
	parent.add_child(entity)

func _add_validation_asset(
	parent: Node2D,
	projection: GridProjection,
	asset_id: String,
	cell: Vector2i
) -> void:
	var definition_path := "res://assets/definitions/%s.tres" % asset_id
	var definition := load(definition_path) as PWAssetDefinition
	assert(definition != null, "Validation definition was not generated: %s" % asset_id)

	var image_path := "res://assets/sprites/%s.png" % asset_id
	var image := _load_or_create_image(image_path, GENERATOR.create_asset_image(asset_id))
	var texture := ImageTexture.create_from_image(image)

	var object_root := Node2D.new()
	object_root.name = asset_id
	object_root.position = _get_ground_position(projection, cell, definition.footprint_size)
	object_root.z_index = definition.sort_z_index

	var sprite := Sprite2D.new()
	sprite.name = "Artwork"
	sprite.texture = texture
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = definition.sprite_scale
	sprite.position = (
		Vector2(definition.texture_size_px) * 0.5 - definition.ground_anchor_px
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

func _load_or_create_image(path: String, fallback: Image) -> Image:
	var image := Image.new()
	var error := image.load(ProjectSettings.globalize_path(path))
	if error == OK and not image.is_empty():
		return image
	return fallback

func _build_camera(map_bounds: Rect2, panel_offset: Vector2) -> void:
	var combined_left := map_bounds.position.x
	var combined_right := panel_offset.x + map_bounds.end.x
	var center_x := (combined_left + combined_right) * 0.5
	var center_y := -40.0

	var camera := Camera2D.new()
	camera.name = "ArtisticValidationCamera"
	camera.position = Vector2(center_x, center_y)
	camera.zoom = Vector2.ONE * 0.86
	add_child(camera)
	camera.make_current()

func _build_overlay(panel_offset: Vector2) -> void:
	var overlay := CanvasLayer.new()
	overlay.name = "ReviewOverlay"
	add_child(overlay)

	var title := _make_label("ART DIRECTION VALIDATION", Vector2(24, 14), 25, Color("f4ead5"))
	overlay.add_child(title)

	var baseline_label := _make_label("CURRENT BASELINE", Vector2(24, 52), 19, Color("e9d8b8"))
	overlay.add_child(baseline_label)

	var study_label := _make_label(
		"PIXEL-CLUSTER STUDY",
		Vector2(665, 52),
		19,
		Color("c6ed9c")
	)
	overlay.add_child(study_label)

	var baseline_note := _make_label(
		"Original sprites + individual diamond ground tiles",
		Vector2(24, 77),
		13,
		Color("c4c5b7")
	)
	overlay.add_child(baseline_note)

	var study_note := _make_label(
		"Rebuilt clusters + continuous ground surface",
		Vector2(665, 77),
		13,
		Color("c4d6b8")
	)
	overlay.add_child(study_note)

	var divider := ColorRect.new()
	divider.position = Vector2(638, 112)
	divider.size = Vector2(2, 500)
	divider.color = Color(0.75, 0.80, 0.68, 0.42)
	overlay.add_child(divider)

	var footer := _make_label(
		"SAME 7 × 5 WORLD GRID  ·  SAME OBJECT FOOTPRINTS  ·  ORIGINAL ASSETS PRESERVED",
		Vector2(24, 680),
		14,
		Color("e5dfcf")
	)
	overlay.add_child(footer)

func _make_label(
	text_value: String,
	label_position: Vector2,
	font_size: int,
	font_color: Color
) -> Label:
	var label := Label.new()
	label.text = text_value
	label.position = label_position
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", font_color)
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.85))
	label.add_theme_constant_override("shadow_size", 3)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label
