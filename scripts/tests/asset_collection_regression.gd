extends Node

const ASSET_IDS: Array[String] = ["old_oak", "moonpetal_plant", "mossy_rock"]
const GROUND_ASSET_IDS: Array[String] = [
	"forest_grass",
	"forest_grass_flowers",
	"forest_wildflowers",
	"forest_dirt_path",
	"forest_dirt_path_bare",
	"forest_rocky_ground"
]

func _ready() -> void:
	var generation: Dictionary = ForestGroundTileGenerator.generate_all_assets()
	var generation_errors: Array = generation.get("errors", [])
	assert(generation_errors.is_empty(), "Ground tile generation reported errors: %s" % generation_errors)
	for asset_id in ASSET_IDS:
		_test_object_asset(asset_id)
	for asset_id in GROUND_ASSET_IDS:
		_test_ground_asset(asset_id)
	_test_ground_renderer()
	print("ASSET + GROUND REGRESSION PASS")
	get_tree().quit()

func _test_object_asset(asset_id: String) -> void:
	var definition_path := "res://assets/definitions/%s.tres" % asset_id
	assert(ResourceLoader.exists(definition_path), "Missing asset definition: %s" % definition_path)
	var definition := load(definition_path) as PWAssetDefinition
	assert(definition != null, "Could not load PWAssetDefinition: %s" % asset_id)
	assert(String(definition.asset_id) == asset_id, "Definition ID mismatch: %s" % asset_id)
	assert(definition.texture_size_px == Vector2i(128, 128), "Unexpected texture dimensions: %s" % asset_id)
	assert(definition.ground_anchor_px.x >= 0.0 and definition.ground_anchor_px.x < 128.0, "Ground anchor X is outside texture: %s" % asset_id)
	assert(definition.ground_anchor_px.y >= 0.0 and definition.ground_anchor_px.y < 128.0, "Ground anchor Y is outside texture: %s" % asset_id)
	assert(definition.get_footprint_cells(Vector2i.ZERO).size() == definition.footprint_size.x * definition.footprint_size.y, "Footprint metadata mismatch: %s" % asset_id)

	var texture := definition.load_texture()
	assert(texture != null, "Runtime texture could not be loaded: %s" % asset_id)
	assert(texture.get_width() == 128 and texture.get_height() == 128, "Runtime texture size mismatch: %s" % asset_id)
	var image := texture.get_image()
	assert(image != null and not image.is_empty(), "Runtime texture image is empty: %s" % asset_id)
	var transparent_pixels := 0
	var visible_pixels := 0
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var alpha := image.get_pixel(x, y).a
			if alpha < 0.01:
				transparent_pixels += 1
			elif alpha > 0.9:
				visible_pixels += 1
	assert(transparent_pixels > 0, "Sprite must retain transparent background: %s" % asset_id)
	assert(visible_pixels > 0, "Sprite contains no visible pixels: %s" % asset_id)

	_test_source_document("res://assets/source_art/%s" % asset_id, asset_id, Vector2i(128, 128), 3)

	var entity := WorldEntity.new()
	entity.configure(definition, StringName(asset_id), Vector2i(3, 4), Vector2(90.0, 100.0))
	entity.set_ground_position(Vector2(120.0, 240.0))
	assert(entity.position.is_equal_approx(Vector2(120.0, 240.0)), "WorldEntity ground anchor position mismatch: %s" % asset_id)
	assert(entity.get_child_count() == 1 and entity.get_child(0) is Sprite2D, "WorldEntity did not create an asset-backed Sprite2D: %s" % asset_id)
	var sprite := entity.get_child(0) as Sprite2D
	assert(sprite.scale.is_equal_approx(definition.sprite_scale), "WorldEntity did not apply metadata sprite scale: %s" % asset_id)
	entity.free()

func _test_ground_asset(asset_id: String) -> void:
	var definition_path := "res://assets/definitions/%s.tres" % asset_id
	assert(ResourceLoader.exists(definition_path), "Missing ground definition: %s" % asset_id)
	var definition := load(definition_path) as PWAssetDefinition
	assert(definition != null, "Could not load ground definition: %s" % asset_id)
	assert(String(definition.asset_id) == asset_id, "Ground definition ID mismatch: %s" % asset_id)
	assert(definition.asset_role == PWAssetDefinition.AssetRole.GROUND_TILE, "Ground asset role mismatch: %s" % asset_id)
	assert(definition.texture_size_px == Vector2i(192, 96), "Ground source dimensions mismatch: %s" % asset_id)
	assert(definition.ground_anchor_px.is_equal_approx(Vector2(96, 48)), "Ground anchor mismatch: %s" % asset_id)
	assert(definition.sprite_scale.is_equal_approx(Vector2(0.5, 0.5)), "Ground display scale mismatch: %s" % asset_id)

	var image := Image.new()
	var image_path := ProjectSettings.globalize_path("res://assets/sprites/%s.png" % asset_id)
	assert(image.load(image_path) == OK, "Could not read generated ground PNG: %s" % asset_id)
	assert(image.get_width() == 192 and image.get_height() == 96, "Ground PNG dimensions mismatch: %s" % asset_id)
	assert(image.get_pixel(0, 0).a < 0.01, "Ground tile should have transparent corners: %s" % asset_id)
	assert(image.get_pixel(96, 48).a > 0.9, "Ground tile diamond center should be opaque: %s" % asset_id)
	_test_source_document("res://assets/source_art/%s" % asset_id, asset_id, Vector2i(192, 96), 3)

func _test_source_document(source_root: String, asset_id: String, expected_size: Vector2i, expected_layers: int) -> void:
	var document_path := ProjectSettings.globalize_path(source_root + "/document.json")
	assert(FileAccess.file_exists(document_path), "Missing editable source document: %s" % asset_id)
	var file := FileAccess.open(document_path, FileAccess.READ)
	assert(file != null, "Could not open source document: %s" % asset_id)
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	assert(parsed is Dictionary, "Source document is invalid: %s" % asset_id)
	var document: Dictionary = parsed
	assert(document.get("asset_id", "") == asset_id, "Source document ID mismatch: %s" % asset_id)
	var size: Array = document.get("size", [])
	assert(size.size() == 2 and int(size[0]) == expected_size.x and int(size[1]) == expected_size.y, "Source document dimensions mismatch: %s" % asset_id)
	var layers: Array = document.get("layers", [])
	assert(layers.size() == expected_layers, "Unexpected editable layer count: %s" % asset_id)
	for layer_value in layers:
		assert(layer_value is Dictionary, "Invalid layer entry: %s" % asset_id)
		var layer: Dictionary = layer_value
		var layer_path := ProjectSettings.globalize_path(source_root + "/layers/" + String(layer.get("file", "")))
		assert(FileAccess.file_exists(layer_path), "Missing source layer PNG: %s" % layer_path)

func _test_ground_renderer() -> void:
	var ground := WorldGroundTiles.new()
	ground.configure(GridProjection.new(), Vector2i(10, 8), "sanctuary")
	assert(ground.get_child_count() == 2, "Ground renderer should create terrain and selection nodes")
	var terrain_root := ground.get_node("TerrainSprites") as Node2D
	assert(terrain_root.get_child_count() == 80, "Terrain renderer did not create one tile per map cell")
	var path_tile_found := false
	for child in terrain_root.get_children():
		if String(child.name).begins_with("forest_dirt_path"):
			path_tile_found = true
			break
	assert(path_tile_found, "Review terrain did not include a path tile")
	ground.free()

