extends Control

const WORLD_BOARD_SCENE := preload("res://scenes/world/world_board.tscn")
const HOME_INTERIOR_SCENE := preload("res://scenes/interior/home_interior.tscn")
const ACCENT := Color("d7bb7d")
const TEXT_MAIN := Color("f3ead4")
const TEXT_MUTED := Color("b6c2a8")

var _current_view: String = "sanctuary"
var _selected_object_id: String = ""
var _book_page: int = 0
var _brew_step: int = 0

var _header_level: Label
var _header_inventory: Label
var _view_title: Label
var _view_subtitle: Label
var _screen_slot: VBoxContainer
var _context_panel: PanelContainer
var _context_title: Label
var _context_description: Label
var _context_action: Button
var _toast_label: Label

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	GameState.state_changed.connect(_on_game_state_changed)
	GameState.toast_requested.connect(_show_toast)
	_build_shell()
	_show_view("sanctuary")

func _build_shell() -> void:
	var background := ColorRect.new()
	background.color = Color("17252a")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 8)
	margin.add_child(layout)

	var header := _make_panel(Color("253a37"), Color("526b5a"), 12)
	header.custom_minimum_size = Vector2(0, 64)
	layout.add_child(header)
	var header_row := HBoxContainer.new()
	header_row.add_theme_constant_override("separation", 12)
	header.add_child(header_row)

	var title_column := VBoxContainer.new()
	title_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_column.alignment = BoxContainer.ALIGNMENT_CENTER
	header_row.add_child(title_column)
	title_column.add_child(_make_label("POCKET WORLDS", 21, TEXT_MAIN, true))
	_header_level = _make_label("SANCTUARY LEVEL 1 · 0 XP", 11, TEXT_MUTED, false)
	title_column.add_child(_header_level)
	_header_inventory = _make_label("COIN 24   DEW 2   WOOD 0", 12, ACCENT, true)
	_header_inventory.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_header_inventory.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header_row.add_child(_header_inventory)

	var view_heading := HBoxContainer.new()
	view_heading.add_theme_constant_override("separation", 12)
	layout.add_child(view_heading)
	_view_title = _make_label("YOUR SANCTUARY", 18, TEXT_MAIN, true)
	view_heading.add_child(_view_title)
	_view_subtitle = _make_label("A little world waiting to be shaped.", 12, TEXT_MUTED, false)
	_view_subtitle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_view_subtitle.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_view_subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	view_heading.add_child(_view_subtitle)

	_toast_label = _make_label("", 12, Color("f2d58a"), true)
	_toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast_label.visible = false
	layout.add_child(_toast_label)

	var body := HBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 10)
	layout.add_child(body)

	_screen_slot = VBoxContainer.new()
	_screen_slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_screen_slot.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_screen_slot.add_theme_constant_override("separation", 6)
	body.add_child(_screen_slot)

	_context_panel = _make_panel(Color("263a37"), Color("6a8068"), 12)
	_context_panel.custom_minimum_size = Vector2(232, 0)
	_context_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_context_panel.visible = false
	body.add_child(_context_panel)
	var context_box := VBoxContainer.new()
	context_box.add_theme_constant_override("separation", 8)
	_context_panel.add_child(context_box)
	_context_title = _make_label("", 17, TEXT_MAIN, true)
	context_box.add_child(_context_title)
	_context_description = _make_label("", 12, TEXT_MUTED, false)
	_context_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	context_box.add_child(_context_description)
	var context_spacer := Control.new()
	context_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	context_box.add_child(context_spacer)
	_context_action = _make_button("Interact", _perform_selected_action, true)
	_context_action.custom_minimum_size = Vector2(0, 48)
	context_box.add_child(_context_action)

	var navigation := HBoxContainer.new()
	navigation.add_theme_constant_override("separation", 8)
	layout.add_child(navigation)
	navigation.add_child(_make_button("WORLD", func() -> void: _show_view("sanctuary")))
	navigation.add_child(_make_button("EXPLORE", func() -> void: _show_view("discovery")))
	navigation.add_child(_make_button("HOME", func() -> void: _show_view("interior")))
	navigation.add_child(_make_button("JOURNAL", func() -> void: _show_view("journal")))
	_refresh_header()

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
	if bold:
		label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.35))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	return label

func _make_button(text_value: String, action: Callable, primary: bool = false) -> Button:
	var button := Button.new()
	button.text = text_value
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.custom_minimum_size = Vector2(0, 48)
	button.add_theme_font_size_override("font_size", 14)
	button.add_theme_color_override("font_color", Color("26342e") if primary else TEXT_MAIN)
	button.add_theme_color_override("font_hover_color", Color("1d2b27") if primary else Color("fff5dc"))
	button.add_theme_color_override("font_pressed_color", Color("1d2b27"))
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
	button.pressed.connect(action)
	return button

func _clear_screen_slot() -> void:
	for child in _screen_slot.get_children():
		child.queue_free()
	_selected_object_id = ""
	_context_panel.visible = false

func _show_view(view_id: String) -> void:
	_current_view = view_id
	_clear_screen_slot()
	match view_id:
		"sanctuary":
			_view_title.text = "YOUR SANCTUARY"
			_view_subtitle.text = "A little world waiting to be shaped. Swipe to move, pinch to zoom, tap to interact."
			_add_world_board("sanctuary")
		"discovery":
			_view_title.text = "WHISPERING WOODS"
			_view_subtitle.text = "A quiet place with a few secrets still waiting to be found."
			_add_world_board("whispering_woods")
		"interior":
			_view_title.text = "YOUR HOME"
			_view_subtitle.text = "A place for knowledge, experiments and making things."
			_build_interior()
		"journal":
			_view_title.text = "FIELD JOURNAL"
			_view_subtitle.text = "Everything you have learned and discovered so far."
			_build_journal()
	_refresh_header()

func _add_world_board(target_world: String) -> void:
	var board := WORLD_BOARD_SCENE.instantiate() as WorldBoard
	board.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	board.size_flags_vertical = Control.SIZE_EXPAND_FILL
	board.object_selected.connect(_on_object_selected)
	board.empty_tile_selected.connect(_on_empty_tile_selected)
	_screen_slot.add_child(board)
	board.set_world(target_world)
	var hint := _make_label("TIP  ·  Select a glowing or unusual object to inspect it.", 11, TEXT_MUTED, false)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_screen_slot.add_child(hint)

func _build_interior() -> void:
	var interior := HOME_INTERIOR_SCENE.instantiate() as HomeInteriorView
	interior.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	interior.size_flags_vertical = Control.SIZE_EXPAND_FILL
	interior.station_requested.connect(_open_hub)
	interior.return_to_sanctuary_requested.connect(func() -> void: _show_view("sanctuary"))
	_screen_slot.add_child(interior)

func _open_hub(hub_id: String) -> void:
	if hub_id == "brew":
		_brew_step = int(GameState.get_flag("brew_step", 0))
	_refresh_hub_content(hub_id)

func _refresh_hub_content(hub_id: String) -> void:
	for child in _screen_slot.get_children():
		child.queue_free()
	var back_button := _make_button("← HOME", func() -> void: _show_view("interior"))
	_screen_slot.add_child(back_button)
	match hub_id:
		"book":
			_build_book_hub()
		"brew":
			_build_brew_hub()
		"workshop":
			_build_workshop_hub()
		"creatures":
			_build_creature_hub()

func _build_book_hub() -> void:
	_screen_slot.add_child(_make_label("THE FIELD GUIDE", 20, TEXT_MAIN, true))
	var book_panel := _make_panel(Color("e0d2ac"), Color("9b8057"), 12)
	book_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_screen_slot.add_child(book_panel)
	var book_content := VBoxContainer.new()
	book_content.add_theme_constant_override("separation", 14)
	book_panel.add_child(book_content)
	var page_indicator := _make_label("PAGE %d / 3" % (_book_page + 1), 11, Color("6f604b"), true)
	page_indicator.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	book_content.add_child(page_indicator)
	var page_title := _make_label(_get_book_page_title(), 19, Color("493f32"), true)
	book_content.add_child(page_title)
	var page_text := _make_label(_get_book_page_text(), 15, Color("514735"), false)
	page_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	page_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	book_content.add_child(page_text)
	var page_controls := HBoxContainer.new()
	book_content.add_child(page_controls)
	var previous_action := func() -> void:
		_book_page = maxi(0, _book_page - 1)
		_refresh_hub_content("book")
	var previous_button := _make_button("PREVIOUS", previous_action)
	previous_button.disabled = _book_page == 0
	page_controls.add_child(previous_button)
	var next_action := func() -> void:
		_book_page = mini(2, _book_page + 1)
		_refresh_hub_content("book")
	var next_button := _make_button("NEXT", next_action)
	next_button.disabled = _book_page == 2
	page_controls.add_child(next_button)
	if _book_page == 1:
		var notes_learned := GameState.has_flag("moonpetal_knowledge")
		var notes_action := func() -> void:
			GameState.set_flag("moonpetal_knowledge", true)
			GameState.add_experience(5)
			GameState.unlock_discovery("moonpetal_notes", "Moonpetal Field Notes", "Moonpetal prefers calm freshwater and soft evening light.")
			_show_toast("Moonpetal notes added to your journal.")
			_refresh_hub_content("book")
		var notes_button := _make_button("NOTES LEARNED" if notes_learned else "STUDY MOONPETAL", notes_action, true)
		notes_button.disabled = notes_learned
		book_content.add_child(notes_button)
	elif _book_page == 2:
		var learned := GameState.has_flag("moonpetal_recipe_learned")
		var study_action := func() -> void:
			GameState.set_flag("moonpetal_recipe_learned", true)
			GameState.add_experience(5)
			GameState.unlock_discovery("moonpetal_recipe", "Moonpetal Essence Recipe", "One Moonpetal Seed and one Dew, stirred twice, create a gentle essence.")
			_show_toast("A new recipe has been learned.")
			_refresh_hub_content("book")
		var study_button := _make_button("RECIPE LEARNED" if learned else "STUDY BREWING RECIPE", study_action, true)
		study_button.disabled = learned
		book_content.add_child(study_button)

func _get_book_page_title() -> String:
	match _book_page:
		0:
			return "Welcome, Keeper"
		1:
			return "Moonpetal"
		_:
			return "A Gentle Essence"

func _get_book_page_text() -> String:
	match _book_page:
		0:
			return "Every small world has its own quiet wonders. Observe carefully, collect what you find and let your Sanctuary grow at its own pace. This guide will record the knowledge you uncover."
		1:
			return "Moonpetal prefers calm freshwater and soft evening light. Its seeds are often hidden in sheltered woodland patches. A mature flower can be harvested and used in simple alchemy."
		_:
			return "A Moonpetal Seed and one measure of Dew can create a gentle essence. Add the ingredients, stir twice and finish the brew. The result may help reveal delicate traces of magic."

func _build_brew_hub() -> void:
	_screen_slot.add_child(_make_label("THE ALCHEMY TABLE", 20, TEXT_MAIN, true))
	var panel := _make_panel(Color("2b403e"), Color("6c8270"), 12)
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_screen_slot.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)
	box.add_child(_make_label("MOONPETAL ESSENCE", 16, ACCENT, true))
	var ingredients := _make_label("Moonpetal Seeds: %d     Dew: %d" % [GameState.get_item_count("moonpetal_seed"), GameState.get_item_count("dew")], 13, TEXT_MUTED, false)
	box.add_child(ingredients)
	var instruction := ""
	var action_text := ""
	var action_callable := Callable()
	var available := true
	match _brew_step:
		0:
			instruction = "Begin by adding one Moonpetal Seed and one measure of Dew."
			action_text = "ADD INGREDIENTS"
			available = GameState.has_flag("moonpetal_recipe_learned") and GameState.get_item_count("moonpetal_seed") >= 1 and GameState.get_item_count("dew") >= 1
			action_callable = func() -> void:
				if GameState.consume_item("moonpetal_seed", 1) and GameState.consume_item("dew", 1):
					_brew_step = 1
					GameState.set_flag("brew_step", _brew_step)
					_refresh_hub_content("brew")
		1:
			instruction = "The mixture is ready. Give it a slow, steady stir."
			action_text = "STIR MIXTURE · 1 / 2"
			action_callable = func() -> void:
				_brew_step = 2
				GameState.set_flag("brew_step", _brew_step)
				_refresh_hub_content("brew")
		2:
			instruction = "The essence is beginning to shimmer. One more careful stir."
			action_text = "STIR MIXTURE · 2 / 2"
			action_callable = func() -> void:
				_brew_step = 3
				GameState.set_flag("brew_step", _brew_step)
				_refresh_hub_content("brew")
		3:
			instruction = "The brew is ready. Complete the process and collect your essence."
			action_text = "FINISH BREW"
			action_callable = func() -> void:
				GameState.add_item("moonpetal_essence", 1)
				GameState.add_experience(12)
				_brew_step = 0
				GameState.set_flag("brew_step", _brew_step)
				GameState.unlock_discovery("moonpetal_essence", "Moonpetal Essence", "A gentle alchemical essence brewed from a Moonpetal Seed and Dew.")
				_refresh_hub_content("brew")
	var instruction_label := _make_label(instruction, 14, TEXT_MAIN, false)
	instruction_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(instruction_label)
	var action_button := _make_button(action_text, action_callable, true)
	action_button.disabled = not available
	box.add_child(action_button)
	if _brew_step == 0 and not GameState.has_flag("moonpetal_recipe_learned"):
		box.add_child(_make_label("Read and study the final page of the Field Guide to learn this recipe.", 11, Color("e2bd83"), false))
	elif _brew_step == 0 and not available:
		box.add_child(_make_label("You need one Moonpetal Seed and one Dew.", 11, Color("e2bd83"), false))
	box.add_child(_make_label("A short, simple touch-based brewing activity. More recipes can use this same hub later.", 11, TEXT_MUTED, false))

func _build_workshop_hub() -> void:
	_screen_slot.add_child(_make_label("THE WORKBENCH", 20, TEXT_MAIN, true))
	var panel := _make_panel(Color("2b403e"), Color("6c8270"), 12)
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_screen_slot.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)
	box.add_child(_make_label("RUNE LANTERN", 17, ACCENT, true))
	box.add_child(_make_label("A small lantern that can be placed in your Sanctuary.", 13, TEXT_MAIN, false))
	box.add_child(_make_label("Required: 2 Wood · 1 Moonstone", 12, TEXT_MUTED, false))
	var can_craft := GameState.get_item_count("wood") >= 2 and GameState.get_item_count("moonstone") >= 1
	var craft_action := func() -> void:
		if GameState.consume_item("wood", 2) and GameState.consume_item("moonstone", 1):
			GameState.add_item("rune_lantern", 1)
			GameState.add_experience(10)
			GameState.unlock_discovery("rune_lantern", "Rune Lantern", "A hand-crafted lantern ready to illuminate a quiet corner of your Sanctuary.")
			_show_toast("Rune Lantern crafted. Place it outside!")
			_refresh_hub_content("workshop")
	var craft_button := _make_button("CRAFT RUNE LANTERN", craft_action, true)
	craft_button.disabled = not can_craft
	box.add_child(craft_button)
	if not can_craft:
		box.add_child(_make_label("Gather wood in your Sanctuary and find a Moonstone in Whispering Woods.", 11, Color("e2bd83"), false))

func _build_creature_hub() -> void:
	_screen_slot.add_child(_make_label("CREATURE NOOK", 20, TEXT_MAIN, true))
	var panel := _make_panel(Color("2b403e"), Color("6c8270"), 12)
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_screen_slot.add_child(panel)
	var box := VBoxContainer.new()
	panel.add_child(box)
	box.add_child(_make_label("A quiet corner for future companions.", 15, TEXT_MAIN, true))
	box.add_child(_make_label("Creature discovery, nurturing and growth will be added after the first world-interaction loop is proven.", 13, TEXT_MUTED, false))

func _build_journal() -> void:
	var intro := _make_panel(Color("2b403e"), Color("5a7461"))
	_screen_slot.add_child(intro)
	var intro_box := VBoxContainer.new()
	intro.add_child(intro_box)
	intro_box.add_child(_make_label("DISCOVERIES  ·  %d" % GameState.discoveries.size(), 16, TEXT_MAIN, true))
	intro_box.add_child(_make_label("A record of places, objects and knowledge you have uncovered.", 12, TEXT_MUTED, false))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_screen_slot.add_child(scroll)
	var entries := VBoxContainer.new()
	entries.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(entries)
	for discovery_id in GameState.discoveries.keys():
		var entry: Dictionary = GameState.discoveries[discovery_id]
		var card := _make_panel(Color("293c37"), Color("506858"), 9)
		entries.add_child(card)
		var entry_box := VBoxContainer.new()
		card.add_child(entry_box)
		entry_box.add_child(_make_label(String(entry.get("title", discovery_id)), 14, ACCENT, true))
		var description := _make_label(String(entry.get("description", "")), 11, TEXT_MUTED, false)
		description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		entry_box.add_child(description)
	var inventory_card := _make_panel(Color("293c37"), Color("506858"), 9)
	entries.add_child(inventory_card)
	var inventory_box := VBoxContainer.new()
	inventory_card.add_child(inventory_box)
	inventory_box.add_child(_make_label("INVENTORY", 14, TEXT_MAIN, true))
	inventory_box.add_child(_make_label("Coins %d  ·  Dew %d  ·  Wood %d  ·  Berries %d" % [GameState.get_item_count("coins"), GameState.get_item_count("dew"), GameState.get_item_count("wood"), GameState.get_item_count("berries")], 11, TEXT_MUTED, false))
	inventory_box.add_child(_make_label("Seeds %d  ·  Moonstone %d  ·  Essence %d  ·  Lanterns %d" % [GameState.get_item_count("moonpetal_seed"), GameState.get_item_count("moonstone"), GameState.get_item_count("moonpetal_essence"), GameState.get_item_count("rune_lantern")], 11, TEXT_MUTED, false))

func _on_object_selected(object_id: String) -> void:
	_selected_object_id = object_id
	var info := _get_object_action_info(object_id)
	_context_title.text = String(info.get("title", "Unknown object"))
	_context_description.text = String(info.get("description", ""))
	_context_action.text = String(info.get("action", "Inspect"))
	_context_action.disabled = bool(info.get("disabled", false))
	_context_panel.visible = true

func _on_empty_tile_selected(cell: Vector2i) -> void:
	_selected_object_id = ""
	_context_title.text = "Open ground · %d, %d" % [cell.x + 1, cell.y + 1]
	_context_description.text = "This space is available for future decoration and placement."
	_context_action.text = "NOTHING TO DO"
	_context_action.disabled = true
	_context_panel.visible = true

func _get_object_action_info(object_id: String) -> Dictionary:
	match object_id:
		"old_oak":
			var listened := GameState.has_flag("old_oak_inspected")
			return {"title": "Old Oak", "description": "A sturdy old tree. Tiny motes drift around its roots." if not listened else "The old tree hums softly in the breeze.", "action": "LISTEN" if not listened else "ALREADY LISTENED", "disabled": listened}
		"moonpetal_plant":
			return {"title": "Moonpetal Plant", "description": "A small woodland plant with pale violet blossoms. Its leaves catch the light.", "action": "INSPECT"}
		"berry_bush":
			var picked := GameState.has_flag("berries_harvested")
			return {"title": "Berry Bush", "description": "A few ripe berries are ready to collect." if not picked else "The bush needs a little time before it bears fruit again.", "action": "HARVEST BERRIES" if not picked else "ALREADY HARVESTED", "disabled": picked}
		"pond":
			return {"title": "Quiet Pond", "description": "Clear water gathers here. The air feels cool and still.", "action": "LISTEN TO THE WATER"}
		"fallen_log":
			var gathered := GameState.has_flag("wood_collected")
			return {"title": "Fallen Log", "description": "A dry fallen branch that can provide a little wood." if not gathered else "There is no more useful wood here.", "action": "COLLECT WOOD" if not gathered else "CLEARED", "disabled": gathered}
		"garden_bed":
			var stage := int(GameState.get_flag("moonpetal_stage", 0))
			if stage == 0:
				var has_seed := GameState.get_item_count("moonpetal_seed") > 0
				return {"title": "Garden Bed", "description": "A small patch of prepared soil. Plant a Moonpetal Seed here." if has_seed else "Prepared soil, ready for a seed when you find one.", "action": "PLANT MOONPETAL" if has_seed else "NEED A SEED", "disabled": not has_seed}
			if stage == 1:
				return {"title": "Moonpetal Sprout", "description": "A tiny sprout is taking root. Give it a little care.", "action": "TEND THE SPROUT"}
			return {"title": "Moonpetal", "description": "The flower has opened. Its petals hold a faint evening glow.", "action": "HARVEST MOONPETAL"}
		"home_door":
			return {"title": "Little Home", "description": "Your library, alchemy table and workbench are inside.", "action": "ENTER HOME"}
		"lantern_slot":
			var placed := GameState.has_flag("lantern_placed")
			var has_lantern := GameState.get_item_count("rune_lantern") > 0
			return {"title": "Lantern Clearing", "description": "A quiet spot beside the path." if not placed else "Your Rune Lantern softly illuminates the clearing.", "action": "PLACE RUNE LANTERN" if has_lantern and not placed else ("ALREADY PLACED" if placed else "NEED A LANTERN"), "disabled": placed or not has_lantern}
		"placed_lantern":
			return {"title": "Rune Lantern", "description": "A small handmade lantern with a gentle magical glow.", "action": "INSPECT"}
		"ancient_marker":
			var activated := GameState.has_flag("marker_activated")
			return {"title": "Ancient Marker", "description": "Three worn symbols are carved into the stone." if not activated else "The marker hums softly. Its symbols are now recorded in your journal.", "action": "ACTIVATE MARKER" if not activated else "READ INSCRIPTION", "disabled": activated}
		"moonseed_patch":
			var collected := GameState.has_flag("seeds_collected")
			return {"title": "Moonpetal Patch", "description": "Pale flowers grow in the shelter of the old trees." if not collected else "You have gathered the seeds from this patch.", "action": "GATHER SEEDS" if not collected else "ALREADY GATHERED", "disabled": collected}
		"crystal_cache":
			var opened := GameState.has_flag("crystal_cache_opened")
			return {"title": "Crystal Cache", "description": "A small violet crystal rests between the stones." if not opened else "The cache is empty, but the Moonstone is safely yours.", "action": "COLLECT MOONSTONE" if not opened else "EMPTY", "disabled": opened}
		"mossy_stone":
			return {"title": "Mossy Stone", "description": "The stone is covered in soft green moss. Nothing seems to move.", "action": "INSPECT"}
	return {"title": "Unknown object", "description": "There is nothing to do here.", "action": "CLOSE", "disabled": true}

func _perform_selected_action() -> void:
	if _selected_object_id.is_empty():
		return
	match _selected_object_id:
		"old_oak":
			if not GameState.has_flag("old_oak_inspected"):
				GameState.set_flag("old_oak_inspected", true)
				GameState.unlock_discovery("old_oak_motes", "Motes Beneath the Oak", "Tiny lights gather around the roots of the Old Oak.")
				GameState.add_experience(3)
				_show_toast("You pause and listen to the old tree.")
		"moonpetal_plant":
			_show_toast("The tiny blossoms sway softly.")
		"berry_bush":
			if not GameState.has_flag("berries_harvested"):
				GameState.set_flag("berries_harvested", true)
				GameState.add_item("berries", 3)
				GameState.add_experience(5)
				_show_toast("Collected 3 berries.")
		"pond":
			_show_toast("The pond ripples softly.")
		"fallen_log":
			if not GameState.has_flag("wood_collected"):
				GameState.set_flag("wood_collected", true)
				GameState.add_item("wood", 2)
				GameState.add_experience(5)
				_show_toast("Collected 2 wood.")
		"garden_bed":
			var stage := int(GameState.get_flag("moonpetal_stage", 0))
			if stage == 0 and GameState.consume_item("moonpetal_seed", 1):
				GameState.set_flag("moonpetal_stage", 1)
				GameState.add_experience(5)
				_show_toast("Moonpetal planted.")
			elif stage == 1:
				GameState.set_flag("moonpetal_stage", 2)
				GameState.add_experience(5)
				_show_toast("The Moonpetal opens in the evening light.")
			elif stage >= 2:
				GameState.add_item("moonpetal", 1)
				GameState.set_flag("moonpetal_stage", 1)
				GameState.add_experience(4)
				GameState.unlock_discovery("moonpetal_in_bloom", "Moonpetal in Bloom", "A cultivated Moonpetal now grows in your Sanctuary.")
				_show_toast("Collected a Moonpetal.")
		"home_door":
			_show_view("interior")
		"lantern_slot":
			if GameState.consume_item("rune_lantern", 1):
				GameState.set_flag("lantern_placed", true)
				GameState.add_experience(6)
				_show_toast("Rune Lantern placed.")
		"placed_lantern", "mossy_stone":
			_show_toast("You take a closer look.")
		"ancient_marker":
			if not GameState.has_flag("marker_activated"):
				GameState.set_flag("marker_activated", true)
				GameState.unlock_discovery("ancient_marker", "The Threefold Marker", "An ancient marker responds to your touch. Its symbols have been added to the journal.")
				GameState.add_experience(10)
				_show_toast("The marker awakens with a soft pulse.")
		"moonseed_patch":
			if not GameState.has_flag("seeds_collected"):
				GameState.set_flag("seeds_collected", true)
				GameState.add_item("moonpetal_seed", 2)
				GameState.add_experience(8)
				GameState.unlock_discovery("moonpetal_seed", "Moonpetal Seeds", "A pair of seeds from a pale woodland flower. The Field Guide may explain how to grow them.")
				_show_toast("Found 2 Moonpetal Seeds.")
		"crystal_cache":
			if not GameState.has_flag("crystal_cache_opened"):
				GameState.set_flag("crystal_cache_opened", true)
				GameState.add_item("moonstone", 1)
				GameState.add_experience(8)
				GameState.unlock_discovery("moonstone", "Moonstone", "A small violet mineral with a cool inner glow.")
				_show_toast("Found a Moonstone.")
	_update_context_after_action()

func _update_context_after_action() -> void:
	if _selected_object_id.is_empty():
		return
	var info := _get_object_action_info(_selected_object_id)
	_context_title.text = String(info.get("title", ""))
	_context_description.text = String(info.get("description", ""))
	_context_action.text = String(info.get("action", ""))
	_context_action.disabled = bool(info.get("disabled", false))
	_refresh_header()

func _on_game_state_changed() -> void:
	_refresh_header()
	if _current_view == "journal":
		_clear_screen_slot()
		_build_journal()
	if _context_panel != null and _context_panel.visible and not _selected_object_id.is_empty():
		_update_context_after_action()

func _refresh_header() -> void:
	if not is_instance_valid(_header_level):
		return
	_header_level.text = "SANCTUARY LEVEL %d  ·  %d / %d XP" % [GameState.level, GameState.experience, GameState.experience_to_next_level()]
	_header_inventory.text = "COIN %d   DEW %d   WOOD %d" % [GameState.get_item_count("coins"), GameState.get_item_count("dew"), GameState.get_item_count("wood")]

func _show_toast(message: String) -> void:
	if not is_instance_valid(_toast_label):
		return
	_toast_label.text = message
	_toast_label.visible = true
	get_tree().create_timer(2.2).timeout.connect(func() -> void:
		if is_instance_valid(_toast_label) and _toast_label.text == message:
			_toast_label.visible = false
	)
