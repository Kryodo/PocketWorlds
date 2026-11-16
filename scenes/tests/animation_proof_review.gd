extends Node2D

# Isolated 128x64 Ground Cell Unit review. The live project projection remains unchanged.
const VIEWPORT_SIZE := Vector2(1280.0, 720.0)
const CELL_AXIS_A := Vector2(64.0, 32.0)
const CELL_AXIS_B := Vector2(-64.0, 32.0)
const CELL_SIZE := Vector2(128.0, 64.0)
const MAP_SIZE := Vector2i(7, 5)
const MAP_ORIGIN := Vector2(576.0, 168.0)
const GROUND_SCALE := Vector2(0.125, 0.125)

const GRASS_PATH := "res://art_inbox/ground/Grass_Base_1024x512.png"
const GRASS_DIRT_PATH := "res://art_inbox/ground/Grass_Dirt_1024x512.png"
const TREE_PATH := "res://art_inbox/vegetation/Tree_01_1024.png"
const DRAKE_STATIC_PATH := "res://art_inbox/creatures/ForestDrake_Static_1024.png"
const DRAKE_IDLE_SHEET_PATH := "res://art_inbox/creatures/ForestDrake_Idle_Sheet_1024.png"

const TILE_DIRT_CELL := Vector2i(3, 2)
const TREE_CELL := Vector2i(1, 2)
const DRAKE_CELL := Vector2i(5, 3)
const TREE_TARGET_HEIGHT_GCU := 4.2
const DRAKE_TARGET_HEIGHT_GCU := 1.75
const DEFAULT_IDLE_FPS := 4.0

var _sorted_world: Node2D
var _animated_drake: AnimatedSprite2D
var _static_drake: Sprite2D
var _status_label: Label
var _current_fps := DEFAULT_IDLE_FPS
var _show_animation := true


func _ready() -> void:
	_sorted_world = Node2D.new()
	_sorted_world.name = "YSortedWorld"
	_sorted_world.y_sort_enabled = true
	add_child(_sorted_world)

	_build_ground()
	_build_tree()
	_build_drake()
	_build_overlay()

	print("ANIMATION PROOF V1 READY")
	print("Ground: 7x5 candidate grid, 128x64 GCU, 1024x512 source tiles at 0.125 scale.")
	print("Drake idle: 4 frames, 2x2 sheet, %.1f FPS." % DEFAULT_IDLE_FPS)
	print("Controls: SPACE = toggle static/idle, 1 = 2 FPS, 2 = 4 FPS, 3 = 6 FPS, R = restart idle.")


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, VIEWPORT_SIZE), Color("#26372f"), true)
	draw_rect(Rect2(Vector2(12.0, 12.0), VIEWPORT_SIZE - Vector2(24.0, 24.0)), Color("#536456"), false, 1.0)


func _grid_to_world(cell: Vector2i) -> Vector2:
	return MAP_ORIGIN + CELL_AXIS_A * float(cell.x) + CELL_AXIS_B * float(cell.y)


func _cell_center(cell: Vector2i) -> Vector2:
	return _grid_to_world(cell) + Vector2(0.0, CELL_SIZE.y * 0.5)


func _build_ground() -> void:
	var grass_image := _load_png_image(GRASS_PATH, "Grass base", false)
	var dirt_image := _load_png_image(GRASS_DIRT_PATH, "Grass + dirt", false)
	if grass_image == null or dirt_image == null:
		return

	if grass_image.get_size() != Vector2i(1024, 512):
		push_warning("Grass base is %s; expected 1024x512." % str(grass_image.get_size()))
	if dirt_image.get_size() != Vector2i(1024, 512):
		push_warning("Grass + dirt is %s; expected 1024x512." % str(dirt_image.get_size()))

	if grass_image.detect_alpha() == Image.ALPHA_NONE:
		push_warning("Grass base has no transparent alpha. Inspect its corners in the running scene.")
	if dirt_image.detect_alpha() == Image.ALPHA_NONE:
		push_warning("Grass + dirt has no transparent alpha. Inspect its corners in the running scene.")

	var grass_texture := ImageTexture.create_from_image(grass_image)
	var dirt_texture := ImageTexture.create_from_image(dirt_image)

	for y in range(MAP_SIZE.y):
		for x in range(MAP_SIZE.x):
			var cell := Vector2i(x, y)
			var sprite := Sprite2D.new()
			sprite.name = "GrassDirt_%d_%d" % [x, y] if cell == TILE_DIRT_CELL else "Grass_%d_%d" % [x, y]
			sprite.texture = dirt_texture if cell == TILE_DIRT_CELL else grass_texture
			sprite.centered = true
			sprite.position = _cell_center(cell)
			sprite.scale = GROUND_SCALE
			sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
			_sorted_world.add_child(sprite)


func _build_tree() -> void:
	var tree_image := _load_png_image(TREE_PATH, "Tree 01", true)
	if tree_image == null:
		return

	var visible_bounds := _get_visible_bounds(tree_image)
	if visible_bounds.size == tree_image.get_size():
		# Fallback bounds for the supplied 1024px tree canvas if its matte could not be keyed.
		visible_bounds = Rect2i(Vector2i(150, 85), Vector2i(730, 840))
		push_warning("Tree alpha bounds fill the canvas; using estimated tree bounds. Check the tree matte in the scene.")

	var anchor := Vector2(
		float(visible_bounds.position.x) + float(visible_bounds.size.x) * 0.5,
		float(visible_bounds.position.y + visible_bounds.size.y)
	)
	var target_height := TREE_TARGET_HEIGHT_GCU * CELL_SIZE.y
	var display_scale := target_height / maxf(float(visible_bounds.size.y), 1.0)

	var sprite := Sprite2D.new()
	sprite.name = "Tree_01"
	sprite.texture = ImageTexture.create_from_image(tree_image)
	sprite.centered = true
	sprite.offset = Vector2(tree_image.get_width() * 0.5, tree_image.get_height() * 0.5) - anchor
	sprite.scale = Vector2.ONE * display_scale
	sprite.position = _cell_center(TREE_CELL)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_sorted_world.add_child(sprite)

	print("Tree display: %.2f GCU tall (target %.1f), scale %.3f, anchor %s." % [
		float(visible_bounds.size.y) * display_scale / CELL_SIZE.y,
		TREE_TARGET_HEIGHT_GCU,
		display_scale,
		str(anchor)
	])


func _build_drake() -> void:
	var sheet := _load_png_image(DRAKE_IDLE_SHEET_PATH, "Forest Drake idle sheet", false)
	if sheet == null:
		return
	if sheet.get_size() != Vector2i(1024, 1024):
		push_error("Forest Drake idle sheet must be 1024x1024 for the expected 2x2 layout.")
		return

	var sprite_frames := SpriteFrames.new()
	sprite_frames.clear_all()
	sprite_frames.add_animation(&"idle")
	sprite_frames.set_animation_loop_mode(&"idle", SpriteFrames.LOOP_LINEAR)
	sprite_frames.set_animation_speed(&"idle", DEFAULT_IDLE_FPS)

	var bounds_per_frame: Array[Rect2i] = []
	for frame_index in range(4):
		var column := frame_index % 2
		var row := int(frame_index / 2)
		var region := Rect2i(column * 512, row * 512, 512, 512)
		var frame_image := sheet.get_region(region)

		var matte_removed := _remove_uniform_corner_matte(frame_image, "Drake idle frame %d" % (frame_index + 1))
		var frame_bounds := _get_visible_bounds(frame_image)
		if frame_bounds.size == Vector2i(512, 512):
			# Estimated character bounds keep the display scale useful if stray opaque pixels remain.
			frame_bounds = Rect2i(Vector2i(55, 65), Vector2i(405, 390))
			if not matte_removed and frame_image.detect_alpha() == Image.ALPHA_NONE:
				push_warning("Drake frame %d has an opaque, non-uniform background. It may need another Photoshop matte pass." % (frame_index + 1))

		bounds_per_frame.append(frame_bounds)
		_report_image("Drake frame %d (matte removed: %s)" % [frame_index + 1, str(matte_removed)], frame_image)
		sprite_frames.add_frame(&"idle", ImageTexture.create_from_image(frame_image))

	var average_anchor := Vector2.ZERO
	var average_height := 0.0
	for frame_bounds in bounds_per_frame:
		average_anchor += Vector2(
			float(frame_bounds.position.x) + float(frame_bounds.size.x) * 0.5,
			float(frame_bounds.position.y + frame_bounds.size.y)
		)
		average_height += float(frame_bounds.size.y)

	average_anchor /= float(bounds_per_frame.size())
	average_height /= float(bounds_per_frame.size())

	var target_height := DRAKE_TARGET_HEIGHT_GCU * CELL_SIZE.y
	var display_scale := target_height / maxf(average_height, 1.0)
	var frame_offset := Vector2(256.0, 256.0) - average_anchor

	_animated_drake = AnimatedSprite2D.new()
	_animated_drake.name = "ForestDrake_Idle"
	_animated_drake.sprite_frames = sprite_frames
	_animated_drake.animation = &"idle"
	_animated_drake.centered = true
	_animated_drake.offset = frame_offset
	_animated_drake.scale = Vector2.ONE * display_scale
	_animated_drake.position = _cell_center(DRAKE_CELL)
	_animated_drake.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_animated_drake.play(&"idle")
	_sorted_world.add_child(_animated_drake)

	var static_image := _load_png_image(DRAKE_STATIC_PATH, "Forest Drake static", true)
	if static_image != null:
		var static_bounds := _get_visible_bounds(static_image)
		if static_bounds.size == static_image.get_size():
			static_bounds = Rect2i(Vector2i(210, 175), Vector2i(650, 675))
			push_warning("Static Drake alpha bounds fill the canvas; using estimated character bounds.")
		var static_anchor := Vector2(
			float(static_bounds.position.x) + float(static_bounds.size.x) * 0.5,
			float(static_bounds.position.y + static_bounds.size.y)
		)
		var static_scale := target_height / maxf(float(static_bounds.size.y), 1.0)

		_static_drake = Sprite2D.new()
		_static_drake.name = "ForestDrake_Static_Comparison"
		_static_drake.texture = ImageTexture.create_from_image(static_image)
		_static_drake.centered = true
		_static_drake.offset = Vector2(static_image.get_width() * 0.5, static_image.get_height() * 0.5) - static_anchor
		_static_drake.scale = Vector2.ONE * static_scale
		_static_drake.position = _cell_center(DRAKE_CELL)
		_static_drake.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		_static_drake.visible = false
		_sorted_world.add_child(_static_drake)

	print("Drake display: %.2f GCU tall (target %.2f), scale %.3f, shared frame anchor %s." % [
		average_height * display_scale / CELL_SIZE.y,
		DRAKE_TARGET_HEIGHT_GCU,
		display_scale,
		str(average_anchor)
	])


func _load_png_image(path: String, label: String, try_corner_matte: bool) -> Image:
	var texture := load(path) as Texture2D
	if texture == null:
		push_error("Animation Proof could not load texture: %s" % path)
		return null

	var source_image := texture.get_image()
	if source_image == null or source_image.is_empty():
		push_error("Animation Proof received an empty image: %s" % path)
		return null

	var image: Image = source_image.duplicate()
	if image.is_compressed():
		var decompress_error := image.decompress()
		if decompress_error != OK:
			push_error("Could not decompress image: %s" % path)
			return null
	image.convert(Image.FORMAT_RGBA8)

	var matte_removed := false
	if try_corner_matte:
		matte_removed = _remove_uniform_corner_matte(image, label)
	_report_image("%s (corner matte removed: %s)" % [label, str(matte_removed)], image)
	return image


func _remove_uniform_corner_matte(image: Image, label: String) -> bool:
	var width := image.get_width()
	var height := image.get_height()
	if width < 8 or height < 8:
		return false

	var inset := 3
	var points: Array[Vector2i] = [
		Vector2i(inset, inset),
		Vector2i(width - inset - 1, inset),
		Vector2i(inset, height - inset - 1),
		Vector2i(width - inset - 1, height - inset - 1)
	]
	var samples: Array[Color] = []
	var key := Color(0.0, 0.0, 0.0, 0.0)
	for point in points:
		var sample := image.get_pixelv(point)
		if sample.a < 0.98:
			return false
		samples.append(sample)
		key.r += sample.r
		key.g += sample.g
		key.b += sample.b
	key.r /= float(samples.size())
	key.g /= float(samples.size())
	key.b /= float(samples.size())

	var maximum_corner_distance := 0.0
	for sample in samples:
		maximum_corner_distance = maxf(maximum_corner_distance, _rgb_distance(sample, key))
	if maximum_corner_distance > 0.075:
		return false

	var hard_threshold := 0.075
	var soft_threshold := 0.22
	for y in range(height):
		for x in range(width):
			var pixel := image.get_pixel(x, y)
			var distance := _rgb_distance(pixel, key)
			if distance <= hard_threshold:
				pixel.a = 0.0
				image.set_pixel(x, y, pixel)
			elif distance < soft_threshold:
				pixel.a *= clampf(inverse_lerp(hard_threshold, soft_threshold, distance), 0.0, 1.0)
				image.set_pixel(x, y, pixel)

	image.fix_alpha_edges()
	print("[AnimationProof] Removed uniform corner matte from %s (key %s)." % [label, str(key)])
	return true


func _rgb_distance(a: Color, b: Color) -> float:
	return (Vector3(a.r, a.g, a.b) - Vector3(b.r, b.g, b.b)).length()


func _get_visible_bounds(image: Image) -> Rect2i:
	var width := image.get_width()
	var height := image.get_height()
	var min_x := width
	var min_y := height
	var max_x := -1
	var max_y := -1

	# Ignore isolated one- or two-pixel matte specks when finding the visual bounds.
	for y in range(height):
		var visible_in_row := 0
		for x in range(width):
			if image.get_pixel(x, y).a > 0.08:
				visible_in_row += 1
		if visible_in_row >= 3:
			min_y = mini(min_y, y)
			max_y = maxi(max_y, y)

	for x in range(width):
		var visible_in_column := 0
		for y in range(height):
			if image.get_pixel(x, y).a > 0.08:
				visible_in_column += 1
		if visible_in_column >= 3:
			min_x = mini(min_x, x)
			max_x = maxi(max_x, x)

	if max_x < min_x or max_y < min_y:
		return Rect2i(Vector2i.ZERO, Vector2i.ZERO)
	return Rect2i(Vector2i(min_x, min_y), Vector2i(max_x - min_x + 1, max_y - min_y + 1))


func _report_image(label: String, image: Image) -> void:
	var alpha_name := "NONE"
	match image.detect_alpha():
		Image.ALPHA_BIT:
			alpha_name = "BIT"
		Image.ALPHA_BLEND:
			alpha_name = "BLEND"
	var used := _get_visible_bounds(image)
	print("[AnimationProof] %s | %dx%d | alpha=%s | visible_bounds=%s" % [
		label,
		image.get_width(),
		image.get_height(),
		alpha_name,
		str(used)
	])


func _build_overlay() -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "ReviewHUD"
	canvas.layer = 10
	add_child(canvas)

	var title := Label.new()
	title.position = Vector2(24.0, 16.0)
	title.text = "POCKET WORLDS  |  ANIMATION PROOF V1"
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color("#f3eddc"))
	canvas.add_child(title)

	_status_label = Label.new()
	_status_label.position = Vector2(24.0, 46.0)
	_status_label.add_theme_font_size_override("font_size", 15)
	_status_label.add_theme_color_override("font_color", Color("#d4ddc8"))
	canvas.add_child(_status_label)
	_update_status()

	var controls := Label.new()
	controls.position = Vector2(24.0, 682.0)
	controls.text = "SPACE  Static / Idle     1  2 FPS     2  4 FPS     3  6 FPS     R  Restart"
	controls.add_theme_font_size_override("font_size", 15)
	controls.add_theme_color_override("font_color", Color("#f3eddc"))
	canvas.add_child(controls)


func _update_status() -> void:
	if _status_label == null:
		return
	if _show_animation:
		_status_label.text = "FOREST DRAKE  •  IDLE ANIMATION  •  %.1f FPS" % _current_fps
	else:
		_status_label.text = "FOREST DRAKE  •  STATIC REFERENCE"


func _set_idle_speed(next_fps: float) -> void:
	_current_fps = next_fps
	if _animated_drake != null and _animated_drake.sprite_frames != null:
		_animated_drake.sprite_frames.set_animation_speed(&"idle", _current_fps)
		_animated_drake.play(&"idle")
	_update_status()


func _toggle_static_animation() -> void:
	_show_animation = not _show_animation
	if _animated_drake != null:
		_animated_drake.visible = _show_animation
		if _show_animation:
			_animated_drake.play(&"idle")
		else:
			_animated_drake.stop()
	if _static_drake != null:
		_static_drake.visible = not _show_animation
	_update_status()


func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return

	match key_event.keycode:
		KEY_SPACE:
			_toggle_static_animation()
		KEY_1:
			_set_idle_speed(2.0)
		KEY_2:
			_set_idle_speed(4.0)
		KEY_3:
			_set_idle_speed(6.0)
		KEY_R:
			if _animated_drake != null:
				_animated_drake.play(&"idle")
