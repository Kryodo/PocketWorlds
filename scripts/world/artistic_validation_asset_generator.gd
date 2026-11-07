@tool
class_name ArtisticValidationAssetGenerator
extends RefCounted

const TILE_STEP := 4
const ASSET_DEFINITION_SCRIPT := preload("res://scripts/world/pw_asset_definition.gd")
const OBJECT_ASSET_IDS: Array[String] = [
	"validation_oak",
	"validation_plant",
	"validation_rock"
]

static func generate_all_assets(overwrite_existing: bool = false) -> Dictionary:
	var result := {"generated": [], "skipped": [], "errors": []}
	_ensure_directory("res://assets/sprites")
	_ensure_directory("res://assets/definitions")
	_ensure_directory("res://assets/source_art")

	for asset_id in OBJECT_ASSET_IDS:
		var spec: Dictionary = _get_asset_spec(asset_id)
		var texture_path := "res://assets/sprites/%s.png" % asset_id
		var definition_path := "res://assets/definitions/%s.tres" % asset_id
		var source_root := "res://assets/source_art/%s" % asset_id
		var document_path := source_root + "/document.json"
		var can_skip := not overwrite_existing and _file_exists(texture_path) and _file_exists(definition_path) and _file_exists(document_path)
		if can_skip:
			result["skipped"].append(asset_id)
			continue

		var layers: Array[Image] = _create_asset_layers(asset_id)
		var composite := _composite_layers(layers)
		var png_error := composite.save_png(ProjectSettings.globalize_path(texture_path))
		if png_error != OK:
			result["errors"].append("%s PNG save failed: %d" % [asset_id, png_error])
			continue

		var definition_error := _save_asset_definition(asset_id, spec, definition_path)
		if definition_error != OK:
			result["errors"].append("%s definition save failed: %d" % [asset_id, definition_error])
			continue

		var source_error := _save_source_layers(asset_id, layers, spec, source_root)
		if source_error != OK:
			result["errors"].append("%s source save failed: %d" % [asset_id, source_error])
			continue
		result["generated"].append(asset_id)

	var ground_path := "res://assets/sprites/validation_ground_patch.png"
	var ground_root := "res://assets/source_art/validation_ground_patch"
	if overwrite_existing or not _file_exists(ground_path) or not _file_exists(ground_root + "/document.json"):
		var ground_layers: Array[Image] = _create_ground_patch_layers(Vector2i(7, 5))
		var ground_composite := _composite_layers(ground_layers)
		var ground_error := ground_composite.save_png(ProjectSettings.globalize_path(ground_path))
		if ground_error != OK:
			result["errors"].append("Ground patch PNG save failed: %d" % ground_error)
		else:
			var source_error := _save_ground_source_layers(ground_layers, Vector2i(7, 5), ground_root)
			if source_error != OK:
				result["errors"].append("Ground patch source save failed: %d" % source_error)
			else:
				result["generated"].append("validation_ground_patch")
	else:
		result["skipped"].append("validation_ground_patch")

	return result

static func create_asset_image(asset_id: String) -> Image:
	return _composite_layers(_create_asset_layers(asset_id))

static func create_ground_patch_image(map_size: Vector2i) -> Image:
	return _composite_layers(_create_ground_patch_layers(map_size))

static func _get_asset_spec(asset_id: String) -> Dictionary:
	match asset_id:
		"validation_oak":
			return {
				"display_name": "Validation Oak",
				"category": &"tree",
				"size": Vector2i(256, 256),
				"anchor": Vector2(128, 244),
				"footprint": Vector2i(2, 2)
			}
		"validation_plant":
			return {
				"display_name": "Validation Plant",
				"category": &"plant",
				"size": Vector2i(128, 128),
				"anchor": Vector2(64, 122),
				"footprint": Vector2i.ONE
			}
		"validation_rock":
			return {
				"display_name": "Validation Rock",
				"category": &"rock",
				"size": Vector2i(160, 112),
				"anchor": Vector2(80, 102),
				"footprint": Vector2i.ONE
			}
	return {}

static func _create_asset_layers(asset_id: String) -> Array[Image]:
	match asset_id:
		"validation_oak":
			return _create_oak_layers()
		"validation_plant":
			return _create_plant_layers()
		"validation_rock":
			return _create_rock_layers()
	var empty_layers: Array[Image] = []
	return empty_layers

static func _create_oak_layers() -> Array[Image]:
	var size := Vector2i(256, 256)
	var shadow := _transparent_image(size)
	var oak_shadow_rows: Array[Vector3i] = [
		Vector3i(220, 112, 144), Vector3i(224, 88, 168),
		Vector3i(228, 80, 176), Vector3i(232, 84, 180),
		Vector3i(236, 92, 172), Vector3i(240, 104, 160),
		Vector3i(244, 116, 148)
	]
	_draw_row_bands(shadow, oak_shadow_rows, TILE_STEP, Color(0.10, 0.20, 0.12, 0.86))
	_draw_stepped_ellipse(shadow, 128, 240, 24, 6, TILE_STEP, Color(0.07, 0.14, 0.09, 0.80))

	var base := _transparent_image(size)
	_draw_stepped_ellipse(base, 128, 232, 32, 12, TILE_STEP, Color("543321"))
	_draw_trunk(base)
	_draw_stepped_line(base, Vector2(126, 178), Vector2(91, 137), 12, Color("583923"), TILE_STEP)
	_draw_stepped_line(base, Vector2(133, 171), Vector2(166, 132), 12, Color("4c3021"), TILE_STEP)
	_draw_stepped_line(base, Vector2(128, 165), Vector2(129, 119), 12, Color("64412a"), TILE_STEP)

	var crown_outline: Array[Vector3i] = [
		Vector3i(24, 112, 144), Vector3i(32, 96, 160),
		Vector3i(40, 80, 176), Vector3i(48, 72, 184),
		Vector3i(56, 56, 200), Vector3i(64, 48, 208),
		Vector3i(72, 40, 216), Vector3i(80, 32, 224),
		Vector3i(88, 28, 228), Vector3i(96, 28, 228),
		Vector3i(104, 32, 224), Vector3i(112, 36, 220),
		Vector3i(120, 44, 212), Vector3i(128, 52, 204),
		Vector3i(136, 64, 192), Vector3i(144, 76, 180),
		Vector3i(152, 92, 164), Vector3i(160, 108, 148)
	]
	_draw_row_bands(base, crown_outline, 8, Color("1c452e"))

	var crown_main: Array[Vector3i] = [
		Vector3i(32, 112, 144), Vector3i(40, 96, 160),
		Vector3i(48, 88, 168), Vector3i(56, 72, 184),
		Vector3i(64, 64, 192), Vector3i(72, 56, 200),
		Vector3i(80, 48, 208), Vector3i(88, 44, 212),
		Vector3i(96, 44, 212), Vector3i(104, 48, 208),
		Vector3i(112, 52, 204), Vector3i(120, 60, 196),
		Vector3i(128, 68, 188), Vector3i(136, 80, 176),
		Vector3i(144, 92, 164), Vector3i(152, 108, 148)
	]
	_draw_row_bands(base, crown_main, 8, Color("397640"))

	var lower_shadow: Array[Vector3i] = [
		Vector3i(96, 52, 204), Vector3i(104, 44, 212),
		Vector3i(112, 44, 212), Vector3i(120, 52, 204),
		Vector3i(128, 60, 196), Vector3i(136, 76, 180),
		Vector3i(144, 92, 164), Vector3i(152, 108, 148),
		Vector3i(160, 116, 140)
	]
	_draw_row_bands(base, lower_shadow, 8, Color("285a37"))

	var mid_clusters: Image = _transparent_image(size)
	_draw_stepped_ellipse(mid_clusters, 87, 76, 39, 25, 8, Color("4f9142"))
	_draw_stepped_ellipse(mid_clusters, 144, 66, 34, 22, 8, Color("47883e"))
	_draw_stepped_ellipse(mid_clusters, 185, 100, 24, 20, 8, Color("3b783a"))
	_draw_stepped_ellipse(mid_clusters, 78, 118, 27, 19, 8, Color("326d3b"))
	var oak_base_layers: Array[Image] = [base, mid_clusters]
	var merged_base := _composite_layers(oak_base_layers)

	var highlights := _transparent_image(size)
	_draw_stepped_ellipse(highlights, 90, 55, 22, 12, 4, Color("83b951"))
	_draw_stepped_ellipse(highlights, 133, 48, 25, 12, 4, Color("75ae4b"))
	_draw_stepped_ellipse(highlights, 170, 79, 18, 10, 4, Color("69a547"))
	_draw_stepped_ellipse(highlights, 67, 91, 12, 8, 4, Color("92c35c"))
	_draw_stepped_ellipse(highlights, 111, 94, 16, 8, 4, Color("6eaa48"))
	_draw_stepped_ellipse(highlights, 152, 112, 12, 8, 4, Color("4f8c3e"))
	_draw_stepped_ellipse(highlights, 102, 132, 13, 7, 4, Color("477f3d"))
	_draw_stepped_ellipse(highlights, 190, 120, 10, 7, 4, Color("447d3b"))
	var result: Array[Image] = [shadow, merged_base, highlights]
	return result

static func _draw_trunk(image: Image) -> void:
	for y in range(144, 240, 4):
		var progress := float(y - 144) / 96.0
		var half_width := 10 + int(roundf(progress * 8.0))
		var left := 128 - half_width
		var width := half_width * 2
		_fill_rect(image, Rect2i(left, y, width, 4), Color("34271f"))
		_fill_rect(image, Rect2i(left + 4, y, maxi(4, half_width - 2), 4), Color("80502d"))
		_fill_rect(image, Rect2i(128, y, maxi(4, half_width - 4), 4), Color("593821"))
		_fill_rect(image, Rect2i(120, y, 4, 4), Color("b2763d"))
	_draw_stepped_ellipse(image, 128, 229, 30, 10, 4, Color("654027"))
	_draw_stepped_line(image, Vector2(116, 224), Vector2(96, 235), 8, Color("71482b"), 4)
	_draw_stepped_line(image, Vector2(139, 224), Vector2(160, 235), 8, Color("4c3020"), 4)

static func _create_plant_layers() -> Array[Image]:
	var size := Vector2i(128, 128)
	var shadow := _transparent_image(size)
	var plant_shadow_rows: Array[Vector3i] = [
		Vector3i(112, 52, 72), Vector3i(116, 44, 84),
		Vector3i(120, 40, 88), Vector3i(124, 52, 76)
	]
	_draw_row_bands(shadow, plant_shadow_rows, 4, Color(0.10, 0.20, 0.12, 0.82))

	var base := _transparent_image(size)
	_draw_stepped_line(base, Vector2(64, 116), Vector2(43, 56), 5, Color("285738"), 4)
	_draw_stepped_line(base, Vector2(65, 116), Vector2(76, 65), 5, Color("326b3b"), 4)
	_draw_stepped_line(base, Vector2(64, 114), Vector2(63, 48), 5, Color("3a7840"), 4)
	_draw_stepped_ellipse(base, 43, 91, 19, 9, 4, Color("28613b"))
	_draw_stepped_ellipse(base, 49, 79, 13, 7, 4, Color("4c9848"))
	_draw_stepped_ellipse(base, 83, 91, 18, 8, 4, Color("285a37"))
	_draw_stepped_ellipse(base, 78, 78, 13, 7, 4, Color("5b9f4b"))
	_draw_stepped_ellipse(base, 61, 99, 17, 8, 4, Color("28603a"))
	_draw_stepped_ellipse(base, 64, 85, 12, 7, 4, Color("75ad50"))
	_draw_stepped_ellipse(base, 36, 103, 9, 6, 4, Color("3d8541"))
	_draw_stepped_ellipse(base, 91, 103, 10, 6, 4, Color("3d8240"))

	var highlights := _transparent_image(size)
	_draw_flower_head(highlights, Vector2(43, 45), Color("c78be6"), Color("f7dd91"))
	_draw_flower_head(highlights, Vector2(76, 57), Color("e6a6dc"), Color("ffe6a0"))
	_draw_flower_head(highlights, Vector2(62, 32), Color("b995ee"), Color("ffe3a0"))
	_draw_stepped_ellipse(highlights, 46, 84, 7, 4, 4, Color("83c55b"))
	_draw_stepped_ellipse(highlights, 80, 83, 7, 4, 4, Color("86c45a"))
	var result: Array[Image] = [shadow, base, highlights]
	return result

static func _draw_flower_head(image: Image, center: Vector2, petal_color: Color, center_color: Color) -> void:
	var cx := roundi(center.x)
	var cy := roundi(center.y)
	_draw_stepped_ellipse(image, cx - 6, cy, 6, 5, 4, petal_color)
	_draw_stepped_ellipse(image, cx + 6, cy, 6, 5, 4, petal_color)
	_draw_stepped_ellipse(image, cx, cy - 5, 5, 5, 4, petal_color)
	_draw_stepped_ellipse(image, cx, cy + 5, 5, 5, 4, petal_color)
	_draw_stepped_ellipse(image, cx, cy, 3, 3, 4, center_color)

static func _create_rock_layers() -> Array[Image]:
	var size := Vector2i(160, 112)
	var shadow := _transparent_image(size)
	var rock_shadow_rows: Array[Vector3i] = [
		Vector3i(96, 56, 104), Vector3i(100, 36, 128),
		Vector3i(104, 28, 132), Vector3i(108, 44, 116)
	]
	_draw_row_bands(shadow, rock_shadow_rows, 4, Color(0.09, 0.17, 0.13, 0.86))

	var base := _transparent_image(size)
	var outline: Array[Vector3i] = [
		Vector3i(24, 64, 96), Vector3i(32, 48, 112),
		Vector3i(40, 32, 128), Vector3i(48, 24, 136),
		Vector3i(56, 16, 144), Vector3i(64, 12, 148),
		Vector3i(72, 16, 144), Vector3i(80, 24, 136),
		Vector3i(88, 40, 120), Vector3i(96, 56, 104)
	]
	_draw_row_bands(base, outline, 8, Color("303f3a"))
	var body: Array[Vector3i] = [
		Vector3i(32, 64, 96), Vector3i(40, 48, 112),
		Vector3i(48, 40, 120), Vector3i(56, 32, 128),
		Vector3i(64, 28, 132), Vector3i(72, 32, 128),
		Vector3i(80, 40, 120), Vector3i(88, 56, 104)
	]
	_draw_row_bands(base, body, 8, Color("68766e"))

	var shadow_face: Array[Vector3i] = [
		Vector3i(56, 104, 128), Vector3i(64, 112, 132),
		Vector3i(72, 112, 128), Vector3i(80, 104, 120),
		Vector3i(88, 88, 112)
	]
	_draw_row_bands(base, shadow_face, 8, Color("4a5c55"))
	_draw_stepped_ellipse(base, 68, 53, 31, 14, 8, Color("89958a"))
	_draw_stepped_ellipse(base, 104, 61, 21, 12, 8, Color("75867a"))

	var highlights := _transparent_image(size)
	_draw_stepped_ellipse(highlights, 60, 45, 19, 8, 4, Color("b1b79a"))
	_draw_stepped_ellipse(highlights, 91, 42, 13, 7, 4, Color("a1ad91"))
	_draw_stepped_ellipse(highlights, 48, 56, 10, 5, 4, Color("8ea18b"))
	_draw_stepped_ellipse(highlights, 69, 37, 16, 5, 4, Color("638e4c"))
	_draw_stepped_ellipse(highlights, 88, 35, 10, 5, 4, Color("79a653"))
	_draw_stepped_ellipse(highlights, 53, 65, 8, 4, 4, Color("527c44"))
	return [shadow, base, highlights]

static func _create_ground_patch_layers(map_size: Vector2i) -> Array[Image]:
	var projection := GridProjection.new()
	var bounds := projection.get_map_bounds(map_size)
	var size := Vector2i(ceili(bounds.size.x), ceili(bounds.size.y))
	var base := _transparent_image(size)
	var path := _transparent_image(size)
	var details := _transparent_image(size)

	for y in range(0, size.y, TILE_STEP):
		for x in range(0, size.x, TILE_STEP):
			var center := Vector2(float(x) + 2.0, float(y) + 2.0)
			if _is_inside_map_pixel(center, map_size, bounds):
				_fill_rect(base, Rect2i(x, y, TILE_STEP, TILE_STEP), Color("35683d"))

	var rng := RandomNumberGenerator.new()
	rng.seed = 240711
	var grass_colors: Array[Color] = [
		Color("427b43"), Color("2c5937"), Color("4a8447"),
		Color("315f39"), Color("598c4c"), Color("285233")
	]
	for index in range(72):
		var px := rng.randi_range(8, size.x - 8)
		var py := rng.randi_range(8, size.y - 8)
		if not _is_inside_map_pixel(Vector2(px, py), map_size, bounds):
			continue
		var radius_x := rng.randi_range(5, 17)
		var radius_y := rng.randi_range(4, 11)
		var patch_color: Color = grass_colors[rng.randi_range(0, grass_colors.size() - 1)]
		_draw_clipped_stepped_ellipse(base, px, py, radius_x, radius_y, TILE_STEP, patch_color, map_size, bounds)

	var path_points: Array[Vector2] = [
		_grid_to_patch_pixel(Vector2(3.1, 0.0), bounds),
		_grid_to_patch_pixel(Vector2(2.5, 0.9), bounds),
		_grid_to_patch_pixel(Vector2(3.0, 1.9), bounds),
		_grid_to_patch_pixel(Vector2(2.5, 3.0), bounds),
		_grid_to_patch_pixel(Vector2(3.2, 4.9), bounds)
	]
	_draw_ground_stroke(path, path_points, 34, Color("233f2e"), map_size, bounds)
	_draw_ground_stroke(path, path_points, 26, Color("80603d"), map_size, bounds)
	_draw_ground_stroke(path, path_points, 8, Color("a17a4b"), map_size, bounds)

	for index in range(95):
		var px := rng.randi_range(8, size.x - 8)
		var py := rng.randi_range(8, size.y - 8)
		if not _is_inside_map_pixel(Vector2(px, py), map_size, bounds):
			continue
		var blade_color := Color("78a957") if index % 3 == 0 else Color("244d31")
		_draw_clipped_stepped_ellipse(details, px, py, 4, 3, TILE_STEP, blade_color, map_size, bounds)

	for index in range(16):
		var px := rng.randi_range(20, size.x - 20)
		var py := rng.randi_range(12, size.y - 12)
		if not _is_inside_map_pixel(Vector2(px, py), map_size, bounds):
			continue
		var flower_color := Color("f0d17d") if index % 3 == 0 else (Color("e9a9cf") if index % 3 == 1 else Color("e8e4c6"))
		_draw_clipped_stepped_ellipse(details, px, py, 5, 4, TILE_STEP, flower_color, map_size, bounds)
		_draw_clipped_stepped_ellipse(details, px + 4, py - 3, 3, 3, TILE_STEP, flower_color.lightened(0.08), map_size, bounds)

	for index in range(12):
		var px := rng.randi_range(16, size.x - 16)
		var py := rng.randi_range(12, size.y - 12)
		if not _is_inside_map_pixel(Vector2(px, py), map_size, bounds):
			continue
		_draw_clipped_stepped_ellipse(details, px, py, 7, 4, TILE_STEP, Color("879184"), map_size, bounds)
		_draw_clipped_stepped_ellipse(details, px - 3, py - 2, 3, 2, TILE_STEP, Color("b1b49c"), map_size, bounds)

	var result: Array[Image] = [base, path, details]
	return result

static func _draw_ground_stroke(
	image: Image,
	points: Array[Vector2],
	width: int,
	color: Color,
	map_size: Vector2i,
	bounds: Rect2
) -> void:
	for index in range(points.size() - 1):
		var start := points[index]
		var finish := points[index + 1]
		var distance := start.distance_to(finish)
		var count := maxi(1, ceili(distance / float(TILE_STEP)))
		for step_index in range(count + 1):
			var center := start.lerp(finish, float(step_index) / float(count))
			_draw_clipped_stepped_ellipse(
				image,
				roundi(center.x),
				roundi(center.y),
				int(floorf(float(width) * 0.5)),
				int(floorf(float(width) * 0.5)),
				TILE_STEP,
				color,
				map_size,
				bounds
			)

static func _draw_clipped_stepped_ellipse(
	image: Image,
	center_x: int,
	center_y: int,
	radius_x: int,
	radius_y: int,
	step: int,
	color: Color,
	map_size: Vector2i,
	bounds: Rect2
) -> void:
	for y in range(center_y - radius_y, center_y + radius_y + 1, step):
		var dy := ((float(y) + float(step) * 0.5) - float(center_y)) / maxf(1.0, float(radius_y))
		if absf(dy) > 1.0:
			continue
		var half_width := int(floorf(float(radius_x) * sqrt(1.0 - dy * dy) / float(step))) * step
		for x in range(center_x - half_width, center_x + half_width + 1, step):
			var sample := Vector2(float(x) + float(step) * 0.5, float(y) + float(step) * 0.5)
			if _is_inside_map_pixel(sample, map_size, bounds):
				_fill_rect(image, Rect2i(x, y, step, step), color)

static func _grid_to_patch_pixel(grid_position: Vector2, bounds: Rect2) -> Vector2:
	var world_position := Vector2(
		48.0 * grid_position.x - 48.0 * grid_position.y,
		24.0 * grid_position.x + 24.0 * grid_position.y
	)
	return world_position - bounds.position

static func _is_inside_map_pixel(point: Vector2, map_size: Vector2i, bounds: Rect2) -> bool:
	var world_position := point + bounds.position
	var grid_x := (world_position.x + 2.0 * world_position.y) / 96.0
	var grid_y := (2.0 * world_position.y - world_position.x) / 96.0
	return grid_x >= 0.0 and grid_y >= 0.0 and grid_x < float(map_size.x) and grid_y < float(map_size.y)

static func _draw_row_bands(image: Image, rows: Array[Vector3i], block_size: int, color: Color) -> void:
	for row in rows:
		for x in range(row.y, row.z + 1, block_size):
			_fill_rect(image, Rect2i(x, row.x, block_size, block_size), color)

static func _draw_stepped_ellipse(
	image: Image,
	center_x: int,
	center_y: int,
	radius_x: int,
	radius_y: int,
	step: int,
	color: Color
) -> void:
	for y in range(center_y - radius_y, center_y + radius_y + 1, step):
		var dy := ((float(y) + float(step) * 0.5) - float(center_y)) / maxf(1.0, float(radius_y))
		if absf(dy) > 1.0:
			continue
		var half_width := int(floorf(float(radius_x) * sqrt(1.0 - dy * dy) / float(step))) * step
		for x in range(center_x - half_width, center_x + half_width + 1, step):
			_fill_rect(image, Rect2i(x, y, step, step), color)

static func _draw_stepped_line(
	image: Image,
	start: Vector2,
	finish: Vector2,
	width: int,
	color: Color,
	step: int
) -> void:
	var distance := start.distance_to(finish)
	var count := maxi(1, ceili(distance / float(step)))
	for index in range(count + 1):
		var point := start.lerp(finish, float(index) / float(count))
		_draw_stepped_ellipse(
			image,
			roundi(point.x),
			roundi(point.y),
			int(floorf(float(width) * 0.5)),
			int(floorf(float(width) * 0.5)),
			step,
			color
		)

static func _fill_rect(image: Image, rect: Rect2i, color: Color) -> void:
	var left := maxi(0, rect.position.x)
	var top := maxi(0, rect.position.y)
	var right := mini(image.get_width(), rect.position.x + rect.size.x)
	var bottom := mini(image.get_height(), rect.position.y + rect.size.y)
	for y in range(top, bottom):
		for x in range(left, right):
			image.set_pixel(x, y, color)

static func _transparent_image(size: Vector2i) -> Image:
	var image := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.0, 0.0, 0.0, 0.0))
	return image

static func _composite_layers(layers: Array[Image]) -> Image:
	if layers.is_empty():
		return Image.create(1, 1, false, Image.FORMAT_RGBA8)
	var output := _transparent_image(layers[0].get_size())
	for layer in layers:
		for y in range(output.get_height()):
			for x in range(output.get_width()):
				var source := layer.get_pixel(x, y)
				if source.a <= 0.001:
					continue
				var destination := output.get_pixel(x, y)
				var out_alpha := source.a + destination.a * (1.0 - source.a)
				var out_red := (source.r * source.a + destination.r * destination.a * (1.0 - source.a)) / out_alpha
				var out_green := (source.g * source.a + destination.g * destination.a * (1.0 - source.a)) / out_alpha
				var out_blue := (source.b * source.a + destination.b * destination.a * (1.0 - source.a)) / out_alpha
				output.set_pixel(x, y, Color(out_red, out_green, out_blue, out_alpha))
	return output

static func _save_asset_definition(asset_id: String, spec: Dictionary, path: String) -> Error:
	var definition = ASSET_DEFINITION_SCRIPT.new()
	definition.asset_id = StringName(asset_id)
	definition.display_name = String(spec["display_name"])
	definition.category = spec["category"]
	var tags: Array[StringName] = [&"art_validation", StringName(spec["category"]), &"pixel_art"]
	definition.tags = tags
	definition.texture_path = "res://assets/sprites/%s.png" % asset_id
	definition.texture_size_px = spec["size"]
	definition.ground_anchor_px = spec["anchor"]
	definition.footprint_size = spec["footprint"]
	definition.asset_role = 0
	definition.sprite_scale = Vector2.ONE
	return ResourceSaver.save(definition, path)

static func _save_source_layers(
	asset_id: String,
	layers: Array[Image],
	spec: Dictionary,
	source_root: String
) -> Error:
	_ensure_directory(source_root + "/layers")
	var layer_names: Array[String] = ["Ground Shadow", "Base Art", "Directional Highlights"]
	var layer_files: Array[String] = ["layer_00.png", "layer_01.png", "layer_02.png"]
	var layer_entries: Array[Dictionary] = []
	for index in range(layers.size()):
		var error := layers[index].save_png(ProjectSettings.globalize_path(source_root + "/layers/" + layer_files[index]))
		if error != OK:
			return error
		layer_entries.append({"name": layer_names[index], "file": layer_files[index]})
	var document := {
		"version": 1,
		"asset_id": asset_id,
		"size": [spec["size"].x, spec["size"].y],
		"ground_anchor_px": [spec["anchor"].x, spec["anchor"].y],
		"footprint_size": [spec["footprint"].x, spec["footprint"].y],
		"layers": layer_entries
	}
	return _write_document(source_root, document)

static func _save_ground_source_layers(layers: Array[Image], map_size: Vector2i, source_root: String) -> Error:
	_ensure_directory(source_root + "/layers")
	var names: Array[String] = ["Continuous Ground Base", "Winding Dirt Path", "Terrain Details"]
	var files: Array[String] = ["layer_00.png", "layer_01.png", "layer_02.png"]
	var entries: Array[Dictionary] = []
	for index in range(layers.size()):
		var error := layers[index].save_png(ProjectSettings.globalize_path(source_root + "/layers/" + files[index]))
		if error != OK:
			return error
		entries.append({"name": names[index], "file": files[index]})
	var projection := GridProjection.new()
	var bounds := projection.get_map_bounds(map_size)
	var document := {
		"version": 1,
		"asset_id": "validation_ground_patch",
		"size": [ceili(bounds.size.x), ceili(bounds.size.y)],
		"ground_anchor_px": [bounds.size.x * 0.5, bounds.size.y * 0.5],
		"footprint_size": [map_size.x, map_size.y],
		"layers": entries
	}
	return _write_document(source_root, document)

static func _write_document(source_root: String, document: Dictionary) -> Error:
	var file := FileAccess.open(ProjectSettings.globalize_path(source_root + "/document.json"), FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(document, "\t"))
	file.close()
	return OK

static func _file_exists(res_path: String) -> bool:
	return FileAccess.file_exists(ProjectSettings.globalize_path(res_path))

static func _ensure_directory(res_path: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(res_path))
