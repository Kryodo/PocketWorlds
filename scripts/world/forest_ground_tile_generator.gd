@tool
class_name ForestGroundTileGenerator
extends RefCounted

const TILE_SIZE := Vector2i(192, 96)
const ASSET_DEFINITION_SCRIPT := preload("res://scripts/world/pw_asset_definition.gd")
const ASSET_IDS: Array[String] = [
	"forest_grass",
	"forest_grass_flowers",
	"forest_wildflowers",
	"forest_dirt_path",
	"forest_dirt_path_bare",
	"forest_rocky_ground"
]

static func generate_all_assets(overwrite_existing: bool = false) -> Dictionary:
	var result := {"generated": [], "skipped": [], "errors": []}
	_ensure_directory("res://assets/sprites")
	_ensure_directory("res://assets/definitions")
	for asset_id in ASSET_IDS:
		var texture_path := "res://assets/sprites/%s.png" % asset_id
		var definition_path := "res://assets/definitions/%s.tres" % asset_id
		var source_root := "res://assets/source_art/%s" % asset_id
		if not overwrite_existing and FileAccess.file_exists(ProjectSettings.globalize_path(texture_path)) and ResourceLoader.exists(definition_path):
			result["skipped"].append(asset_id)
			continue
		var image := create_image(asset_id)
		var save_error := image.save_png(ProjectSettings.globalize_path(texture_path))
		if save_error != OK:
			result["errors"].append("%s PNG save failed: %d" % [asset_id, save_error])
			continue
		var definition = ASSET_DEFINITION_SCRIPT.new()
		definition.asset_id = StringName(asset_id)
		definition.display_name = _display_name(asset_id)
		definition.category = &"ground"
		definition.tags = [ &"ground", &"terrain", &"forest" ]
		definition.texture_path = texture_path
		definition.texture_size_px = TILE_SIZE
		definition.ground_anchor_px = Vector2(TILE_SIZE) * 0.5
		definition.footprint_size = Vector2i.ONE
		definition.asset_role = 1
		definition.sprite_scale = Vector2(0.5, 0.5)
		var resource_error := ResourceSaver.save(definition, definition_path)
		if resource_error != OK:
			result["errors"].append("%s definition save failed: %d" % [asset_id, resource_error])
			continue
		var source_error := _save_source_layers(asset_id, image, source_root)
		if source_error != OK:
			result["errors"].append("%s source save failed: %d" % [asset_id, source_error])
			continue
		result["generated"].append(asset_id)
	return result

static func create_image(asset_id: String) -> Image:
	var image := Image.create(TILE_SIZE.x, TILE_SIZE.y, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.0, 0.0, 0.0, 0.0))
	var seed := absi(asset_id.hash()) % 997
	var palette := _palette_for(asset_id)
	for y in range(TILE_SIZE.y):
		for x in range(TILE_SIZE.x):
			var diamond_distance := absf(float(x) - 95.5) / 95.5 + absf(float(y) - 47.5) / 47.5
			if diamond_distance > 1.0:
				continue
			var variation := posmod(x * 17 + y * 31 + seed * 13 + x * y, 13)
			var color: Color = palette[variation % palette.size()]
			if (asset_id.begins_with("forest_dirt") and variation == 2) or (asset_id == "forest_rocky_ground" and variation == 4):
				color = palette[0].darkened(0.12)
			image.set_pixel(x, y, color)
	_add_terrain_details(image, asset_id, seed, palette)
	return image

static func _palette_for(asset_id: String) -> Array[Color]:
	if asset_id.begins_with("forest_dirt"):
		if asset_id == "forest_dirt_path_bare":
			return [Color("78583e"), Color("856244"), Color("906b49"), Color("9b7650"), Color("a9845a"), Color("6f5039")]
		return [Color("4e6944"), Color("6e7049"), Color("846b4a"), Color("927650"), Color("a1845d"), Color("5f7047")]
	if asset_id == "forest_rocky_ground":
		return [Color("59695a"), Color("667567"), Color("74806c"), Color("858776"), Color("989583"), Color("4d5e51")]
	if asset_id == "forest_wildflowers":
		return [Color("315b3d"), Color("3a6842"), Color("46754a"), Color("54804f"), Color("648b58"), Color("426b45")]
	return [Color("315c3c"), Color("386743"), Color("427049"), Color("4b7850"), Color("568253"), Color("628a59")]

static func _add_terrain_details(image: Image, asset_id: String, seed: int, palette: Array[Color]) -> void:
	if asset_id.begins_with("forest_dirt"):
		for index in range(54):
			var px := 12 + posmod(index * 37 + seed, 168)
			var py := 5 + posmod(index * 19 + seed * 3, 86)
			if _inside_diamond(px, py):
				var tone: Color = palette[posmod(index, palette.size())]
				_paint_pixel(image, px, py, tone.lightened(0.10 if index % 3 == 0 else 0.0))
		return
	if asset_id == "forest_rocky_ground":
		for index in range(26):
			var px := 10 + posmod(index * 43 + seed, 172)
			var py := 4 + posmod(index * 23 + seed * 5, 88)
			if _inside_diamond(px, py):
				var stone := Color("b0aa96") if index % 4 == 0 else Color("46564d")
				_paint_cluster(image, px, py, stone, 1 if index % 3 == 0 else 2)
		return
	for index in range(42):
		var px := 8 + posmod(index * 41 + seed, 176)
		var py := 3 + posmod(index * 29 + seed * 7, 90)
		if not _inside_diamond(px, py):
			continue
		var blade := Color("8ca96a") if index % 4 == 0 else Color("294d35")
		_paint_pixel(image, px, py, blade)
		if index % 5 == 0 and _inside_diamond(px + 1, py - 1):
			_paint_pixel(image, px + 1, py - 1, blade.lightened(0.08))
	if asset_id == "forest_grass_flowers" or asset_id == "forest_wildflowers":
		var flower_count := 8 if asset_id == "forest_grass_flowers" else 18
		for index in range(flower_count):
			var px := 12 + posmod(index * 53 + seed, 168)
			var py := 4 + posmod(index * 31 + seed * 11, 88)
			if _inside_diamond(px, py):
				var flower := Color("f0d78a") if index % 3 == 0 else (Color("e7b9d3") if index % 3 == 1 else Color("eee7c9"))
				_paint_cluster(image, px, py, flower, 1)

static func _inside_diamond(x: int, y: int) -> bool:
	return absf(float(x) - 95.5) / 95.5 + absf(float(y) - 47.5) / 47.5 <= 1.0

static func _paint_pixel(image: Image, x: int, y: int, color: Color) -> void:
	if x >= 0 and y >= 0 and x < TILE_SIZE.x and y < TILE_SIZE.y and _inside_diamond(x, y):
		image.set_pixel(x, y, color)

static func _paint_cluster(image: Image, x: int, y: int, color: Color, radius: int) -> void:
	for oy in range(-radius, radius + 1):
		for ox in range(-radius, radius + 1):
			if abs(ox) + abs(oy) <= radius + 1:
				_paint_pixel(image, x + ox, y + oy, color)

static func _save_source_layers(asset_id: String, composite: Image, source_root: String) -> Error:
	_ensure_directory(source_root + "/layers")
	var transparent := Image.create(TILE_SIZE.x, TILE_SIZE.y, false, Image.FORMAT_RGBA8)
	transparent.fill(Color(0.0, 0.0, 0.0, 0.0))
	var layers := [
		{"name": "Shadow Paintover", "file": "layer_00.png", "image": transparent},
		{"name": "Base Art", "file": "layer_01.png", "image": composite},
		{"name": "Highlight Paintover", "file": "layer_02.png", "image": transparent}
	]
	for layer in layers:
		var image: Image = layer["image"]
		var error := image.save_png(ProjectSettings.globalize_path(source_root + "/layers/" + layer["file"]))
		if error != OK:
			return error
	var document := {
		"version": 1,
		"asset_id": asset_id,
		"size": [TILE_SIZE.x, TILE_SIZE.y],
		"ground_anchor_px": [TILE_SIZE.x / 2, TILE_SIZE.y / 2],
		"footprint_size": [1, 1],
		"layers": [
			{"name": "Shadow Paintover", "file": "layer_00.png"},
			{"name": "Base Art", "file": "layer_01.png"},
			{"name": "Highlight Paintover", "file": "layer_02.png"}
		]
	}
	var file := FileAccess.open(ProjectSettings.globalize_path(source_root + "/document.json"), FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(document, "\t"))
	file.close()
	return OK

static func _ensure_directory(res_path: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(res_path))

static func _display_name(asset_id: String) -> String:
	var readable := asset_id.trim_prefix("forest_").replace("_", " ")
	return readable.capitalize()
