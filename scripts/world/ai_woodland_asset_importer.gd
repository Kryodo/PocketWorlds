class_name AIWoodlandAssetImporter
extends RefCounted

const SOURCE_SHEET := "res://art_inbox/woodland_asset_set_01.jpg"
const SOURCE_SHEET_SIZE := Vector2i(1264, 848)
const ASSET_DEFINITION_SCRIPT := preload("res://scripts/world/pw_asset_definition.gd")

const ASSET_SPECS: Array[Dictionary] = [
	{
		"id": "ai_woodland_oak",
		"name": "Woodland Oak",
		"category": &"tree",
		"crop": Rect2i(40, 40, 510, 510),
		"anchor": Vector2(300, 475),
		"footprint": Vector2i(2, 2),
		"scale": Vector2(0.42, 0.42)
	},
	{
		"id": "ai_woodland_bush",
		"name": "Leafy Bush",
		"category": &"bush",
		"crop": Rect2i(585, 160, 300, 280),
		"anchor": Vector2(150, 245),
		"footprint": Vector2i.ONE,
		"scale": Vector2(0.36, 0.36)
	},
	{
		"id": "ai_woodland_flowering_plant",
		"name": "Flowering Plant",
		"category": &"plant",
		"crop": Rect2i(970, 220, 190, 210),
		"anchor": Vector2(90, 185),
		"footprint": Vector2i.ONE,
		"scale": Vector2(0.40, 0.40)
	},
	{
		"id": "ai_woodland_leafy_plant",
		"name": "Leafy Plant",
		"category": &"plant",
		"crop": Rect2i(205, 560, 230, 220),
		"anchor": Vector2(115, 210),
		"footprint": Vector2i.ONE,
		"scale": Vector2(0.38, 0.38)
	},
	{
		"id": "ai_woodland_mossy_boulder",
		"name": "Mossy Boulder",
		"category": &"rock",
		"crop": Rect2i(515, 550, 260, 225),
		"anchor": Vector2(130, 215),
		"footprint": Vector2i.ONE,
		"scale": Vector2(0.34, 0.34)
	},
	{
		"id": "ai_woodland_fallen_log",
		"name": "Fallen Log",
		"category": &"log",
		"crop": Rect2i(850, 495, 370, 280),
		"anchor": Vector2(190, 255),
		"footprint": Vector2i(2, 1),
		"scale": Vector2(0.38, 0.38)
	}
]

const KEY_MIN_DISTANCE := 0.055
const KEY_MAX_DISTANCE := 1.12

static func generate_all_assets(overwrite_existing: bool = false) -> Dictionary:
	var result := {"generated": [], "skipped": [], "errors": []}
	var source := Image.new()
	var load_error := source.load(ProjectSettings.globalize_path(SOURCE_SHEET))
	if load_error != OK or source.is_empty():
		result["errors"].append("Could not load source JPG: %s (error %d)" % [SOURCE_SHEET, load_error])
		return result

	if source.get_width() != SOURCE_SHEET_SIZE.x or source.get_height() != SOURCE_SHEET_SIZE.y:
		result["errors"].append(
			"Unexpected source dimensions: %s; expected %s" % [
				str(source.get_size()),
				str(SOURCE_SHEET_SIZE)
			]
		)
		return result

	var key_color := _sample_background_color(source)
	_ensure_directory("res://assets/sprites")
	_ensure_directory("res://assets/definitions")

	for spec in ASSET_SPECS:
		var asset_id := String(spec["id"])
		var texture_path := "res://assets/sprites/%s.png" % asset_id
		var definition_path := "res://assets/definitions/%s.tres" % asset_id
		var source_root := "res://assets/source_art/%s" % asset_id
		var can_skip := (
			not overwrite_existing
			and _file_exists(texture_path)
			and _file_exists(definition_path)
			and _file_exists(source_root + "/document.json")
		)
		if can_skip:
			result["skipped"].append(asset_id)
			continue

		var crop_rect: Rect2i = spec["crop"]
		if not _rect_is_inside_image(crop_rect, source.get_size()):
			result["errors"].append("%s crop rectangle is outside the source JPG" % asset_id)
			continue

		var extracted := _extract_crop(source, crop_rect, key_color)
		var png_error := extracted.save_png(ProjectSettings.globalize_path(texture_path))
		if png_error != OK:
			result["errors"].append("%s PNG save failed: %d" % [asset_id, png_error])
			continue

		var definition_error := _save_definition(spec, texture_path, extracted.get_size(), definition_path)
		if definition_error != OK:
			result["errors"].append("%s definition save failed: %d" % [asset_id, definition_error])
			continue

		var source_error := _save_source_document(spec, extracted, source_root, key_color)
		if source_error != OK:
			result["errors"].append("%s source document save failed: %d" % [asset_id, source_error])
			continue

		result["generated"].append(asset_id)

	return result

static func get_asset_specs() -> Array[Dictionary]:
	return ASSET_SPECS

static func load_generated_image(asset_id: String) -> Image:
	var path := "res://assets/sprites/%s.png" % asset_id
	var image := Image.new()
	var error := image.load(ProjectSettings.globalize_path(path))
	if error == OK and not image.is_empty():
		return image
	return Image.create(1, 1, false, Image.FORMAT_RGBA8)

static func _sample_background_color(source: Image) -> Color:
	var samples: Array[Color] = [
		source.get_pixel(2, 2),
		source.get_pixel(source.get_width() - 3, 2),
		source.get_pixel(2, source.get_height() - 3),
		source.get_pixel(source.get_width() - 3, source.get_height() - 3)
	]
	var red_total := 0.0
	var green_total := 0.0
	var blue_total := 0.0
	for sample in samples:
		red_total += sample.r
		green_total += sample.g
		blue_total += sample.b
	return Color(red_total / 4.0, green_total / 4.0, blue_total / 4.0, 1.0)

static func _extract_crop(source: Image, crop_rect: Rect2i, key_color: Color) -> Image:
	var extracted := source.get_region(crop_rect)
	for y in range(extracted.get_height()):
		for x in range(extracted.get_width()):
			var pixel := extracted.get_pixel(x, y)
			var cyan_like := (
				pixel.b > pixel.g * 1.10
				and pixel.r < maxf(0.14, pixel.g * 0.62)
				and pixel.g > 0.12
			)
			if not cyan_like:
				continue

			var delta := Vector3(
				pixel.r - key_color.r,
				pixel.g - key_color.g,
				pixel.b - key_color.b
			)
			var distance := delta.length()
			if distance <= KEY_MIN_DISTANCE:
				extracted.set_pixel(x, y, Color(0.0, 0.0, 0.0, 0.0))
				continue

			if distance >= KEY_MAX_DISTANCE:
				continue

			var alpha := clampf(
				(distance - KEY_MIN_DISTANCE) / (KEY_MAX_DISTANCE - KEY_MIN_DISTANCE),
				0.0,
				1.0
			)
			if alpha <= 0.025:
				extracted.set_pixel(x, y, Color(0.0, 0.0, 0.0, 0.0))
				continue

			var inverse_alpha := 1.0 / alpha
			var foreground_red := clampf((pixel.r - key_color.r * (1.0 - alpha)) * inverse_alpha, 0.0, 1.0)
			var foreground_green := clampf((pixel.g - key_color.g * (1.0 - alpha)) * inverse_alpha, 0.0, 1.0)
			var foreground_blue := clampf((pixel.b - key_color.b * (1.0 - alpha)) * inverse_alpha, 0.0, 1.0)
			extracted.set_pixel(x, y, Color(foreground_red, foreground_green, foreground_blue, alpha))

	return extracted

static func _rect_is_inside_image(rect: Rect2i, image_size: Vector2i) -> bool:
	return (
		rect.position.x >= 0
		and rect.position.y >= 0
		and rect.size.x > 0
		and rect.size.y > 0
		and rect.position.x + rect.size.x <= image_size.x
		and rect.position.y + rect.size.y <= image_size.y
	)

static func _save_definition(
	spec: Dictionary,
	texture_path: String,
	texture_size: Vector2i,
	definition_path: String
) -> Error:
	var definition = ASSET_DEFINITION_SCRIPT.new()
	definition.asset_id = StringName(spec["id"])
	definition.display_name = String(spec["name"])
	definition.category = spec["category"]
	var tags: Array[StringName] = [
		&"ai_imported",
		&"woodland",
		StringName(spec["category"]),
		&"casual_toon"
	]
	definition.tags = tags
	definition.texture_path = texture_path
	definition.texture_size_px = texture_size
	definition.ground_anchor_px = spec["anchor"]
	definition.footprint_size = spec["footprint"]
	definition.asset_role = PWAssetDefinition.AssetRole.WORLD_OBJECT
	definition.sprite_scale = spec["scale"]
	definition.texture_filter_mode = PWAssetDefinition.TextureFilterMode.LINEAR
	return ResourceSaver.save(definition, definition_path)

static func _save_source_document(
	spec: Dictionary,
	extracted: Image,
	source_root: String,
	key_color: Color
) -> Error:
	_ensure_directory(source_root + "/layers")
	var original_path := source_root + "/layers/layer_00.png"
	var cleanup_path := source_root + "/layers/layer_01.png"
	var original_error := extracted.save_png(ProjectSettings.globalize_path(original_path))
	if original_error != OK:
		return original_error

	var cleanup := Image.create(extracted.get_width(), extracted.get_height(), false, Image.FORMAT_RGBA8)
	cleanup.fill(Color(0.0, 0.0, 0.0, 0.0))
	var cleanup_error := cleanup.save_png(ProjectSettings.globalize_path(cleanup_path))
	if cleanup_error != OK:
		return cleanup_error

	var crop_rect: Rect2i = spec["crop"]
	var anchor: Vector2 = spec["anchor"]
	var footprint: Vector2i = spec["footprint"]
	var document := {
		"version": 1,
		"asset_id": String(spec["id"]),
		"source_sheet": SOURCE_SHEET,
		"source_sheet_dimensions": [SOURCE_SHEET_SIZE.x, SOURCE_SHEET_SIZE.y],
		"source_crop_rect": [crop_rect.position.x, crop_rect.position.y, crop_rect.size.x, crop_rect.size.y],
		"background_key_rgb": [
			roundi(key_color.r * 255.0),
			roundi(key_color.g * 255.0),
			roundi(key_color.b * 255.0)
		],
		"size": [extracted.get_width(), extracted.get_height()],
		"ground_anchor_px": [anchor.x, anchor.y],
		"footprint_size": [footprint.x, footprint.y],
		"layers": [
			{"name": "Original Extracted Artwork", "file": "layer_00.png"},
			{"name": "Manual Cleanup", "file": "layer_01.png"}
		],
		"notes": "The original sheet is flattened. The extracted artwork layer includes the original contact shadow; Manual Cleanup is an empty transparent layer for corrections."
	}

	var file := FileAccess.open(ProjectSettings.globalize_path(source_root + "/document.json"), FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(document, "\t"))
	file.close()
	return OK

static func _file_exists(path: String) -> bool:
	return FileAccess.file_exists(ProjectSettings.globalize_path(path))

static func _ensure_directory(path: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path))
