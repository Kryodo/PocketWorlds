extends Node

const ASSET_IDS := ["old_oak", "moonpetal_plant", "mossy_rock"]

func _ready() -> void:
	for asset_id in ASSET_IDS:
		_test_asset(asset_id)
	print("ASSET COLLECTION REGRESSION PASS")
	get_tree().quit()

func _test_asset(asset_id: String) -> void:
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

	var source_root := "res://assets/source_art/%s" % asset_id
	var document_path := source_root + "/document.json"
	assert(FileAccess.file_exists(document_path), "Missing editable source document: %s" % asset_id)
	var source_file := FileAccess.open(document_path, FileAccess.READ)
	assert(source_file != null, "Could not open source document: %s" % asset_id)
	var parsed: Variant = JSON.parse_string(source_file.get_as_text())
	source_file.close()
	assert(parsed is Dictionary, "Source document is invalid: %s" % asset_id)
	var document: Dictionary = parsed
	assert(document.get("asset_id", "") == asset_id, "Source document ID mismatch: %s" % asset_id)
	var layers: Array = document.get("layers", [])
	assert(layers.size() == 3, "Each starter asset should have three editable layers: %s" % asset_id)
	for layer_value in layers:
		assert(layer_value is Dictionary, "Invalid layer entry: %s" % asset_id)
		var layer_entry: Dictionary = layer_value
		var layer_path := source_root + "/layers/" + String(layer_entry.get("file", ""))
		assert(FileAccess.file_exists(layer_path), "Missing source layer PNG: %s" % layer_path)

	var entity := WorldEntity.new()
	entity.configure(definition, StringName(asset_id), Vector2i(3, 4), Vector2(90.0, 100.0))
	entity.set_ground_position(Vector2(120.0, 240.0))
	assert(entity.position.is_equal_approx(Vector2(120.0, 240.0)), "WorldEntity ground anchor position mismatch: %s" % asset_id)
	assert(entity.get_child_count() == 1 and entity.get_child(0) is Sprite2D, "WorldEntity did not create an asset-backed Sprite2D: %s" % asset_id)
	entity.free()
