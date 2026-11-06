class_name HomeInteriorView
extends Control

signal station_requested(station_id: String)
signal return_to_sanctuary_requested

const PANEL_EDGE := Color("64766a")
const ACCENT := Color("d7bb7d")
const TEXT_MAIN := Color("f3ead4")
const TEXT_MUTED := Color("b6c2a8")

func _ready() -> void:
	custom_minimum_size = Vector2(0, 520)
	_build_view()

func _build_view() -> void:
	var layout := VBoxContainer.new()
	layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layout.add_theme_constant_override("separation", 9)
	add_child(layout)

	var intro := _make_panel(Color("2b3938"), PANEL_EDGE)
	layout.add_child(intro)
	var intro_label := _make_label("Your home is where discoveries become useful. Choose a station to read, experiment or make something.", 14, TEXT_MAIN, false)
	intro_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro.add_child(intro_label)

	_add_station_card(layout, "FIELD GUIDE", "Read pages, learn about plants and unlock recipes.", "OPEN BOOK", "book")
	_add_station_card(layout, "ALCHEMY TABLE", "Combine ingredients and experiment with a simple brew.", "START BREWING", "brew")
	_add_station_card(layout, "WORKBENCH", "Turn gathered materials into useful objects.", "OPEN WORKSHOP", "workshop")
	_add_station_card(layout, "CREATURE NOOK", "A quiet corner for the inhabitants you discover.", "INSPECT NOOK", "creatures")

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(spacer)
	var return_button := _make_button("RETURN TO SANCTUARY", true)
	return_button.pressed.connect(func() -> void: return_to_sanctuary_requested.emit())
	layout.add_child(return_button)

func _add_station_card(parent: VBoxContainer, title_text: String, description_text: String, button_text: String, station_id: String) -> void:
	var card := _make_panel(Color("283d38"), Color("566f5d"), 10)
	parent.add_child(card)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	card.add_child(row)

	var text_column := VBoxContainer.new()
	text_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text_column)
	text_column.add_child(_make_label(title_text, 15, TEXT_MAIN, true))
	var description := _make_label(description_text, 11, TEXT_MUTED, false)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_column.add_child(description)

	var button := _make_button(button_text)
	button.custom_minimum_size = Vector2(130, 48)
	button.pressed.connect(func() -> void: station_requested.emit(station_id))
	row.add_child(button)

func _make_panel(fill: Color, edge: Color, radius: int = 12) -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = edge
	style.set_border_width_all(2)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 9
	style.content_margin_bottom = 9
	panel.add_theme_stylebox_override("panel", style)
	return panel

func _make_label(text_value: String, font_size: int, color: Color, bold: bool) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	if bold:
		label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.35))
	return label

func _make_button(text_value: String, primary: bool = false) -> Button:
	var button := Button.new()
	button.text = text_value
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.custom_minimum_size = Vector2(0, 48)
	button.add_theme_font_size_override("font_size", 13)
	button.add_theme_color_override("font_color", Color("26342e") if primary else TEXT_MAIN)
	button.add_theme_color_override("font_hover_color", Color("1d2b27") if primary else Color("fff5dc"))
	var normal := StyleBoxFlat.new()
	normal.bg_color = ACCENT if primary else Color("354b43")
	normal.border_color = Color("f0d59a") if primary else Color("607565")
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(9)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color("ead09a") if primary else Color("40594e")
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color("c3a36b") if primary else Color("2c4039")
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	return button
