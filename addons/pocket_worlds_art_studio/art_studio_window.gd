@tool
extends Window

const CANVAS_SCRIPT := preload("res://addons/pocket_worlds_art_studio/art_canvas.gd")
const ASSET_DEFINITION_SCRIPT := preload("res://scripts/world/pw_asset_definition.gd")
const FOREST_GROUND_GENERATOR := preload("res://scripts/world/forest_ground_tile_generator.gd")
var _document_size: Vector2i = Vector2i(128, 128)

signal filesystem_changed

const PALETTE := [
	Color("1e352b"),
	Color("2c4d39"),
	Color("3f6b49"),
	Color("5d8955"),
	Color("85aa69"),
	Color("c0d28a"),
	Color("694832"),
	Color("a77b50"),
	Color("6d8580"),
	Color("6ca4a3"),
	Color("b2d7c6"),
	Color("e6cf8f"),
	Color("d1a8d8"),
	Color("f1e8ce")
]

var _layers: Array[Dictionary] = []
var _active_layer_index: int = 0
var _active_tool: String = "brush"
var _active_color: Color = Color("3f6b49")

var _canvas
var _layer_list: ItemList
var _asset_id_input: LineEdit
var _anchor_x: SpinBox
var _anchor_y: SpinBox
var _footprint_x: SpinBox
var _footprint_y: SpinBox
var _size_x: SpinBox
var _size_y: SpinBox
var _status_label: Label
var _color_preview: ColorRect

func _ready() -> void:
	title = "Pocket Worlds Art Studio"
	min_size = Vector2i(900, 680)
	size = Vector2i(1180, 820)
	close_requested.connect(hide)
	_create_default_layers()
	_build_interface()
	_refresh_preview()
	_refresh_layer_list()

func _create_default_layers() -> void:
	_layers.clear()
	_add_layer_data("Shadow")
	_add_layer_data("Main")
	_add_layer_data("Highlights")
	_active_layer_index = 1

func _add_layer_data(layer_name: String) -> void:
	var image := Image.create(_document_size.x, _document_size.y, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	_layers.append({"name": layer_name, "image": image})

func _build_interface() -> void:
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 8)
	root.add_theme_constant_override("margin_left", 10)
	root.add_theme_constant_override("margin_right", 10)
	root.add_theme_constant_override("margin_top", 10)
	root.add_theme_constant_override("margin_bottom", 10)
	add_child(root)

	var toolbar := HBoxContainer.new()
	toolbar.add_theme_constant_override("separation", 6)
	root.add_child(toolbar)
	toolbar.add_child(_make_button("Brush", func() -> void: _set_tool("brush")))
	toolbar.add_child(_make_button("Eraser", func() -> void: _set_tool("eraser")))
	toolbar.add_child(_make_button("Eyedropper", func() -> void: _set_tool("eyedropper")))
	toolbar.add_child(_make_button("New", _new_document))
	toolbar.add_child(_make_button("Load", _load_source))
	toolbar.add_child(_make_button("Save Source", _save_source))
	toolbar.add_child(_make_button("Export PNG", _export_asset, true))
	toolbar.add_child(_make_button("Generate Ground PNGs", _generate_ground_assets))

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 8)
	root.add_child(body)

	var layers_panel := _make_panel("LAYERS")
	layers_panel.custom_minimum_size = Vector2(176, 0)
	body.add_child(layers_panel)
	var layer_box := layers_panel.get_child(0) as VBoxContainer
	_layer_list = ItemList.new()
	_layer_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_layer_list.item_selected.connect(_on_layer_selected)
	layer_box.add_child(_layer_list)
	layer_box.add_child(_make_button("Add Layer", _add_layer))
	layer_box.add_child(_make_button("Remove Layer", _remove_layer))

	_canvas = CANVAS_SCRIPT.new()
	_canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_canvas.custom_minimum_size = Vector2(500, 500)
	_canvas.pixel_requested.connect(_on_pixel_requested)
	body.add_child(_canvas)

	var settings_panel := _make_panel("ASSET")
	settings_panel.custom_minimum_size = Vector2(210, 0)
	body.add_child(settings_panel)
	var settings := settings_panel.get_child(0) as VBoxContainer

	settings.add_child(_make_label("Asset ID", 12))
	_asset_id_input = LineEdit.new()
	_asset_id_input.text = "first_sprite"
	settings.add_child(_asset_id_input)

	settings.add_child(_make_label("Canvas size (px)", 12))
	_size_x = _make_spinbox(16, 2048, 128)
	_size_y = _make_spinbox(16, 2048, 128)
	_size_x.value_changed.connect(_on_document_size_changed)
	_size_y.value_changed.connect(_on_document_size_changed)
	settings.add_child(_make_label("Width", 10))
	settings.add_child(_size_x)
	settings.add_child(_make_label("Height", 10))
	settings.add_child(_size_y)

	settings.add_child(_make_label("Ground anchor (px)", 12))
	_anchor_x = _make_spinbox(0, 127, 64)
	_anchor_y = _make_spinbox(0, 127, 120)
	settings.add_child(_anchor_x)
	settings.add_child(_anchor_y)

	settings.add_child(_make_label("Footprint (cells)", 12))
	_footprint_x = _make_spinbox(1, 16, 1)
	_footprint_y = _make_spinbox(1, 16, 1)
	settings.add_child(_footprint_x)
	settings.add_child(_footprint_y)

	settings.add_child(_make_label("Palette", 12))
	_color_preview = ColorRect.new()
	_color_preview.custom_minimum_size = Vector2(0, 24)
	_color_preview.color = _active_color
	settings.add_child(_color_preview)
	var palette_grid := GridContainer.new()
	palette_grid.columns = 4
	palette_grid.add_theme_constant_override("h_separation", 4)
	palette_grid.add_theme_constant_override("v_separation", 4)
	settings.add_child(palette_grid)
	for color in PALETTE:
		var swatch := Button.new()
		swatch.custom_minimum_size = Vector2(34, 34)
		swatch.tooltip_text = color.to_html()
		var style := StyleBoxFlat.new()
		style.bg_color = color
		style.set_corner_radius_all(4)
		swatch.add_theme_stylebox_override("normal", style)
		swatch.add_theme_stylebox_override("hover", style)
		swatch.pressed.connect(_set_active_color.bind(color))
		palette_grid.add_child(swatch)

	_status_label = _make_label("128 × 128 transparent canvas · brush selected", 11)
	root.add_child(_status_label)

func _make_panel(heading: String) -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color("293a34")
	style.border_color = Color("526b5a")
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", style)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	panel.add_child(box)
	box.add_child(_make_label(heading, 13))
	return panel

func _make_label(value: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color("e9e2d2"))
	return label

func _make_button(value: String, action: Callable, primary: bool = false) -> Button:
	var button := Button.new()
	button.text = value
	button.custom_minimum_size = Vector2(0, 38)
	button.pressed.connect(action)
	if primary:
		button.modulate = Color("f1d99f")
	return button

func _make_spinbox(minimum: float, maximum: float, initial: float) -> SpinBox:
	var spin := SpinBox.new()
	spin.min_value = minimum
	spin.max_value = maximum
	spin.value = initial
	spin.step = 1.0
	spin.rounded = true
	return spin

func _on_document_size_changed(_value: float = 0.0) -> void:
	if _size_x == null or _size_y == null:
		return
	var next_size := Vector2i(int(_size_x.value), int(_size_y.value))
	if next_size == _document_size:
		return
	for index in range(_layers.size()):
		var old_image: Image = _layers[index]["image"]
		var resized := Image.create(next_size.x, next_size.y, false, Image.FORMAT_RGBA8)
		resized.fill(Color(0, 0, 0, 0))
		var copy_size := Vector2i(mini(old_image.get_width(), next_size.x), mini(old_image.get_height(), next_size.y))
		resized.blit_rect(old_image, Rect2i(Vector2i.ZERO, copy_size), Vector2i.ZERO)
		_layers[index]["image"] = resized
	_document_size = next_size
	_anchor_x.max_value = float(next_size.x - 1)
	_anchor_y.max_value = float(next_size.y - 1)
	_anchor_x.value = clampf(_anchor_x.value, 0.0, _anchor_x.max_value)
	_anchor_y.value = clampf(_anchor_y.value, 0.0, _anchor_y.max_value)
	_refresh_preview()
	_status_label.text = "Canvas resized to %d × %d px." % [next_size.x, next_size.y]

func _set_tool(tool_name: String) -> void:
	_active_tool = tool_name
	_status_label.text = "Tool: %s" % tool_name.capitalize()

func _set_active_color(color: Color) -> void:
	_active_color = color
	_color_preview.color = color
	_set_tool("brush")

func _on_pixel_requested(pixel: Vector2i) -> void:
	if _layers.is_empty() or _active_layer_index < 0 or _active_layer_index >= _layers.size():
		return
	var image: Image = _layers[_active_layer_index]["image"]
	if _active_tool == "eyedropper":
		var sampled := _build_composite().get_pixelv(pixel)
		if sampled.a > 0.0:
			_set_active_color(sampled)
		return
	if _active_tool == "eraser":
		image.set_pixelv(pixel, Color(0, 0, 0, 0))
	else:
		image.set_pixelv(pixel, _active_color)
	_refresh_preview()

func _add_layer() -> void:
	_add_layer_data("Layer %d" % (_layers.size() + 1))
	_active_layer_index = _layers.size() - 1
	_refresh_layer_list()
	_refresh_preview()

func _remove_layer() -> void:
	if _layers.size() <= 1:
		_status_label.text = "A document must contain at least one layer."
		return
	_layers.remove_at(_active_layer_index)
	_active_layer_index = clampi(_active_layer_index, 0, _layers.size() - 1)
	_refresh_layer_list()
	_refresh_preview()

func _new_document() -> void:
	_document_size = Vector2i(int(_size_x.value), int(_size_y.value))
	_anchor_x.max_value = float(_document_size.x - 1)
	_anchor_y.max_value = float(_document_size.y - 1)
	_create_default_layers()
	_refresh_layer_list()
	_refresh_preview()
	_status_label.text = "New transparent %d × %d document." % [_document_size.x, _document_size.y]

func _on_layer_selected(index: int) -> void:
	_active_layer_index = index

func _refresh_layer_list() -> void:
	if _layer_list == null:
		return
	_layer_list.clear()
	for layer in _layers:
		_layer_list.add_item(String(layer["name"]))
	if not _layers.is_empty():
		_layer_list.select(_active_layer_index)

func _build_composite() -> Image:
	var composite := Image.create(_document_size.x, _document_size.y, false, Image.FORMAT_RGBA8)
	composite.fill(Color(0, 0, 0, 0))
	for layer in _layers:
		var image: Image = layer["image"]
		composite.blend_rect(image, Rect2i(Vector2i.ZERO, _document_size), Vector2i.ZERO)
	return composite

func _refresh_preview() -> void:
	if _canvas == null:
		return
	_canvas.set_preview_image(_build_composite())

func _safe_asset_id() -> String:
	var value := _asset_id_input.text.strip_edges().to_lower()
	value = value.replace(" ", "_").replace("/", "_").replace("\\", "_")
	return value if not value.is_empty() else "untitled_sprite"

func _ensure_directory(res_path: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(res_path))

func _save_source() -> bool:
	var asset_id := _safe_asset_id()
	var base_path := "res://assets/source_art/%s" % asset_id
	var layer_directory := base_path + "/layers"
	_ensure_directory(layer_directory)

	var layer_entries: Array[Dictionary] = []
	for index in range(_layers.size()):
		var filename := "layer_%02d.png" % index
		var resource_path := layer_directory + "/" + filename
		var image: Image = _layers[index]["image"]
		var error := image.save_png(ProjectSettings.globalize_path(resource_path))
		if error != OK:
			_status_label.text = "Could not save layer %s (error %d)." % [filename, error]
			return false
		layer_entries.append({
			"name": String(_layers[index]["name"]),
			"file": filename
		})

	var document := {
		"version": 1,
		"asset_id": asset_id,
		"size": [_document_size.x, _document_size.y],
		"ground_anchor_px": [int(_anchor_x.value), int(_anchor_y.value)],
		"footprint_size": [int(_footprint_x.value), int(_footprint_y.value)],
		"layers": layer_entries
	}
	var document_path := base_path + "/document.json"
	var file := FileAccess.open(ProjectSettings.globalize_path(document_path), FileAccess.WRITE)
	if file == null:
		_status_label.text = "Could not write source document."
		return false
	file.store_string(JSON.stringify(document, "\t"))
	file.close()
	filesystem_changed.emit()
	_status_label.text = "Editable source saved: %s" % document_path
	return true

func _load_source() -> void:
	var asset_id := _safe_asset_id()
	var base_path := "res://assets/source_art/%s" % asset_id
	var document_path := ProjectSettings.globalize_path(base_path + "/document.json")
	if not FileAccess.file_exists(document_path):
		_status_label.text = "No saved source found for %s." % asset_id
		return
	var file := FileAccess.open(document_path, FileAccess.READ)
	if file == null:
		_status_label.text = "Could not read source document."
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Dictionary:
		_status_label.text = "Source document is invalid."
		return

	var document: Dictionary = parsed
	var saved_size: Array = document.get("size", [128, 128])
	_document_size = Vector2i(maxi(16, int(saved_size[0])), maxi(16, int(saved_size[1])))
	_size_x.set_value_no_signal(_document_size.x)
	_size_y.set_value_no_signal(_document_size.y)
	_anchor_x.max_value = float(_document_size.x - 1)
	_anchor_y.max_value = float(_document_size.y - 1)
	var next_layers: Array[Dictionary] = []
	for entry_value in document.get("layers", []):
		if not entry_value is Dictionary:
			continue
		var entry: Dictionary = entry_value
		var image := Image.new()
		var image_path := ProjectSettings.globalize_path(base_path + "/layers/" + String(entry.get("file", "")))
		if image.load(image_path) != OK:
			_status_label.text = "Could not load source layer."
			return
		next_layers.append({
			"name": String(entry.get("name", "Layer")),
			"image": image
		})
	if next_layers.is_empty():
		_status_label.text = "Source document contains no layers."
		return

	_layers = next_layers
	var anchor: Array = document.get("ground_anchor_px", [_document_size.x / 2, _document_size.y - 8])
	var footprint: Array = document.get("footprint_size", [1, 1])
	_anchor_x.value = clampf(float(anchor[0]), 0.0, _anchor_x.max_value)
	_anchor_y.value = clampf(float(anchor[1]), 0.0, _anchor_y.max_value)
	_footprint_x.value = int(footprint[0])
	_footprint_y.value = int(footprint[1])
	_active_layer_index = mini(1, _layers.size() - 1)
	_refresh_layer_list()
	_refresh_preview()
	_status_label.text = "Loaded editable source: %s" % asset_id

func _generate_ground_assets() -> void:
	var result: Dictionary = FOREST_GROUND_GENERATOR.generate_all_assets()
	var errors: Array = result.get("errors", [])
	if not errors.is_empty():
		_status_label.text = "Ground generation reported errors: %s" % String(errors[0])
		push_error(_status_label.text)
		return
	filesystem_changed.emit()
	var generated: Array = result.get("generated", [])
	var skipped: Array = result.get("skipped", [])
	_status_label.text = "Ground PNGs generated: %d · Existing assets preserved: %d" % [generated.size(), skipped.size()]

func _export_asset() -> void:
	if not _save_source():
		return
	var asset_id := _safe_asset_id()
	var sprite_directory := "res://assets/sprites"
	var definition_directory := "res://assets/definitions"
	_ensure_directory(sprite_directory)
	_ensure_directory(definition_directory)

	var texture_path := "%s/%s.png" % [sprite_directory, asset_id]
	var error := _build_composite().save_png(ProjectSettings.globalize_path(texture_path))
	if error != OK:
		_status_label.text = "PNG export failed (error %d)." % error
		return

	var definition := ASSET_DEFINITION_SCRIPT.new()
	definition.asset_id = StringName(asset_id)
	definition.display_name = asset_id.replace("_", " ").capitalize()
	definition.category = &"custom"
	definition.texture_path = texture_path
	definition.texture_size_px = _document_size
	definition.ground_anchor_px = Vector2(_anchor_x.value, _anchor_y.value)
	definition.footprint_size = Vector2i(int(_footprint_x.value), int(_footprint_y.value))
	var definition_path := "%s/%s.tres" % [definition_directory, asset_id]
	var save_error := ResourceSaver.save(definition, definition_path)
	if save_error != OK:
		_status_label.text = "PNG created, but asset definition failed (error %d)." % save_error
		return
	filesystem_changed.emit()
	_status_label.text = "Exported PNG and definition: %s" % asset_id

