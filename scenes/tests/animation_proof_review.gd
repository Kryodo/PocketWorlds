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
const DRAKE_IDLE_SHEET_PATH := "res://art_inbox/creatures/ForestDrake_Idle_Sheet_1024_16_Frames.png"

const TILE_DIRT_CELL := Vector2i(3, 2)
const TREE_CELL := Vector2i(1, 2)
const DRAKE_CELL := Vector2i(5, 3)
const TREE_TARGET_HEIGHT_GCU := 4.2
const DEFAULT_DRAKE_HEIGHT_GCU := 1.25
const FRAME_COLUMNS := 4
const FRAME_ROWS := 4
const FRAME_COUNT := 16
const FRAME_SIZE := Vector2i(256, 256)
const FRAME_DURATION_SECONDS := 0.15
const DEFAULT_IDLE_FPS := 1.0 / FRAME_DURATION_SECONDS
const FALLBACK_FRAME_BOUNDS := Rect2i(Vector2i(12, 8), Vector2i(232, 240))

var _ground_root: Node2D
var _sorted_world: Node2D
var _animated_drake: AnimatedSprite2D
var _static_drake: Sprite2D
var _rigged_drake: Node2D
var _rig_animation_player: AnimationPlayer
var _chest_bone: Bone2D
var _drake_shadow: Sprite2D
var _status_label: Label
var _drake_height_gcu := DEFAULT_DRAKE_HEIGHT_GCU
var _display_mode: StringName = &"rig"
var _animated_drake_source_height := 240.0
var _static_drake_source_height := 675.0
var _rigged_drake_source_height := 675.0


func _ready() -> void:
	_ground_root = Node2D.new()
	_ground_root.name = "GroundTiles"
	# Keep the ground above the root's opaque background draw, but below world objects.
	_ground_root.z_index = 0
	add_child(_ground_root)

	_sorted_world = Node2D.new()
	_sorted_world.name = "YSortedWorld"
	_sorted_world.z_index = 1
	_sorted_world.y_sort_enabled = true
	add_child(_sorted_world)

	_build_ground()
	_build_tree()
	_build_drake()
	_build_overlay()

	print("ANIMATION PROOF V2 READY")
	print("Ground: 7x5 candidate grid, 128x64 GCU, 1024x512 source tiles at 0.125 scale.")
	print("Drake idle: 16 frames, 4x4 sheet, %.1f FPS, target %.2f GCU / %.0f px." % [
		DEFAULT_IDLE_FPS,
		_drake_height_gcu,
		_drake_height_gcu * CELL_SIZE.y
	])
	print("Controls: SPACE cycle RIG/SHEET/STATIC | 4=1.0 GCU 5=1.25 GCU 6=1.5 GCU | R=restart")


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
			_ground_root.add_child(sprite)


func _build_tree() -> void:
	var tree_image := _load_png_image(TREE_PATH, "Tree 01", true)
	if tree_image == null:
		return

	var visible_bounds := _get_visible_bounds(tree_image)
	if visible_bounds.size == tree_image.get_size():
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
	sprite.z_index = 0
	_sorted_world.add_child(sprite)

	print("Tree display: %.2f GCU tall (target %.1f), scale %.3f, anchor %s." % [
		float(visible_bounds.size.y) * display_scale / CELL_SIZE.y,
		TREE_TARGET_HEIGHT_GCU,
		display_scale,
		str(anchor)
	])


func _build_drake() -> void:
	var sheet := _load_png_image(DRAKE_IDLE_SHEET_PATH, "Forest Drake 16-frame idle sheet", false)
	if sheet == null:
		return
	if sheet.get_size() != Vector2i(1024, 1024):
		push_error("Forest Drake 16-frame sheet must be 1024x1024 for the expected 4x4 layout.")
		return

	var sprite_frames := SpriteFrames.new()
	sprite_frames.clear_all()
	sprite_frames.add_animation(&"idle")
	sprite_frames.set_animation_loop_mode(&"idle", SpriteFrames.LOOP_LINEAR)
	sprite_frames.set_animation_speed(&"idle", DEFAULT_IDLE_FPS)

	var bounds_per_frame: Array[Rect2i] = []
	var frames_with_opaque_background := 0

	for frame_index in range(FRAME_COUNT):
		var column := frame_index % FRAME_COLUMNS
		var row := int(frame_index / FRAME_COLUMNS)
		var region := Rect2i(column * FRAME_SIZE.x, row * FRAME_SIZE.y, FRAME_SIZE.x, FRAME_SIZE.y)
		var frame_image := sheet.get_region(region)

		# Only remove a true, uniform corner matte. Never guess at a complex background.
		var matte_removed := _remove_uniform_corner_matte(frame_image, "Drake idle frame %02d" % (frame_index + 1))
		var frame_alpha := frame_image.detect_alpha()
		var frame_bounds := _get_visible_bounds(frame_image)
		if frame_alpha == Image.ALPHA_NONE and not matte_removed:
			frames_with_opaque_background += 1
			frame_bounds = FALLBACK_FRAME_BOUNDS
		elif frame_bounds.size == FRAME_SIZE:
			frame_bounds = FALLBACK_FRAME_BOUNDS

		bounds_per_frame.append(frame_bounds)
		_report_frame("Drake frame %02d" % (frame_index + 1), frame_image, matte_removed)
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
	_animated_drake_source_height = average_height

	if frames_with_opaque_background > 0:
		push_warning("%d of 16 idle frames have no usable alpha and no uniform removable corner matte. The sheet background may remain visible; clean the sheet in Photoshop if this occurs in the preview." % frames_with_opaque_background)

	_animated_drake = AnimatedSprite2D.new()
	_animated_drake.name = "ForestDrake_Idle"
	_animated_drake.sprite_frames = sprite_frames
	_animated_drake.animation = &"idle"
	_animated_drake.centered = true
	_animated_drake.offset = Vector2(FRAME_SIZE) * 0.5 - average_anchor
	_animated_drake.position = _cell_center(DRAKE_CELL)
	_animated_drake.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_animated_drake.z_index = 2
	_sorted_world.add_child(_animated_drake)

	# Static, soft contact shadow independent of the animation frames.
	_drake_shadow = Sprite2D.new()
	_drake_shadow.name = "ForestDrake_ContactShadow"
	_drake_shadow.texture = _create_contact_shadow_texture()
	_drake_shadow.centered = true
	_drake_shadow.position = _cell_center(DRAKE_CELL) + Vector2(0.0, -2.0)
	_drake_shadow.scale = Vector2(0.55, 0.32)
	_drake_shadow.z_index = 1
	_sorted_world.add_child(_drake_shadow)

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
		_static_drake_source_height = float(static_bounds.size.y)

		_static_drake = Sprite2D.new()
		_static_drake.name = "ForestDrake_Static_Comparison"
		_static_drake.texture = ImageTexture.create_from_image(static_image)
		_static_drake.centered = true
		_static_drake.offset = Vector2(static_image.get_width() * 0.5, static_image.get_height() * 0.5) - static_anchor
		_static_drake.position = _cell_center(DRAKE_CELL)
		_static_drake.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		_static_drake.z_index = 2
		_static_drake.visible = false
		_sorted_world.add_child(_static_drake)
		_rigged_drake_source_height = float(static_bounds.size.y)
		_build_drake_rig(static_image, static_bounds)

	_apply_drake_scale()
	_set_display_mode(&"rig")
	_animated_drake.play(&"idle")

	print("Drake idle: %d frames, %dx%d grid, frame size %dx%d, %.1f FPS." % [
		FRAME_COUNT, FRAME_COLUMNS, FRAME_ROWS, FRAME_SIZE.x, FRAME_SIZE.y, DEFAULT_IDLE_FPS
	])


func _build_drake_rig(character_image: Image, visible_bounds: Rect2i) -> void:
	var image_width := character_image.get_width()
	var image_height := character_image.get_height()
	var ground_anchor := Vector2(
		float(visible_bounds.position.x) + float(visible_bounds.size.x) * 0.5,
		float(visible_bounds.position.y + visible_bounds.size.y)
	)

	_rigged_drake = Node2D.new()
	_rigged_drake.name = "ForestDrake_SkeletalRig"
	_rigged_drake.position = _cell_center(DRAKE_CELL)
	_rigged_drake.z_index = 2
	_sorted_world.add_child(_rigged_drake)

	var skeleton := Skeleton2D.new()
	skeleton.name = "Skeleton2D"
	_rigged_drake.add_child(skeleton)

	var root_bone := Bone2D.new()
	root_bone.name = "RootAnchor"
	root_bone.position = Vector2.ZERO
	root_bone.set_autocalculate_length_and_angle(false)
	root_bone.length = 90.0
	skeleton.add_child(root_bone)

	_chest_bone = Bone2D.new()
	_chest_bone.name = "ChestBone"
	_chest_bone.position = Vector2(520.0, 565.0) - ground_anchor
	_chest_bone.set_autocalculate_length_and_angle(false)
	_chest_bone.length = 65.0
	root_bone.add_child(_chest_bone)

	# Store the exact default pose before applying any animation.
	root_bone.rest = root_bone.transform
	_chest_bone.rest = _chest_bone.transform

	# A regular UV grid gives the chest enough internal vertices to deform smoothly.
	const GRID_COLUMNS := 33
	const GRID_ROWS := 33
	var points := PackedVector2Array()
	var uvs := PackedVector2Array()
	var root_weights := PackedFloat32Array()
	var chest_weights := PackedFloat32Array()
	var mesh_polygons: Array = []

	var chest_center := Vector2(520.0, 565.0)
	var chest_radii := Vector2(190.0, 145.0)

	for row in range(GRID_ROWS):
		for column in range(GRID_COLUMNS):
			var source_point := Vector2(
				float(column) * float(image_width) / float(GRID_COLUMNS - 1),
				float(row) * float(image_height) / float(GRID_ROWS - 1)
			)
			points.append(source_point - ground_anchor)
			uvs.append(source_point)

			var normalized_distance := Vector2(
				(source_point.x - chest_center.x) / chest_radii.x,
				(source_point.y - chest_center.y) / chest_radii.y
			).length()
			var transition := clampf((normalized_distance - 0.30) / 0.70, 0.0, 1.0)
			var smooth_transition := transition * transition * (3.0 - 2.0 * transition)
			var chest_weight := 0.82 * (1.0 - smooth_transition)
			chest_weights.append(chest_weight)
			root_weights.append(1.0 - chest_weight)

	for row in range(GRID_ROWS - 1):
		for column in range(GRID_COLUMNS - 1):
			var top_left := row * GRID_COLUMNS + column
			var top_right := top_left + 1
			var bottom_left := top_left + GRID_COLUMNS
			var bottom_right := bottom_left + 1
			mesh_polygons.append(PackedInt32Array([
				top_left,
				top_right,
				bottom_right,
				bottom_left
			]))

	var character_mesh := Polygon2D.new()
	character_mesh.name = "TexturedDeformMesh"
	character_mesh.texture = ImageTexture.create_from_image(character_image)
	character_mesh.polygon = points
	character_mesh.uv = uvs
	character_mesh.polygons = mesh_polygons
	character_mesh.color = Color.WHITE
	character_mesh.antialiased = false
	character_mesh.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_rigged_drake.add_child(character_mesh)

	character_mesh.skeleton = character_mesh.get_path_to(skeleton)
	character_mesh.add_bone(character_mesh.get_path_to(root_bone), root_weights)
	character_mesh.add_bone(character_mesh.get_path_to(_chest_bone), chest_weights)

	_rig_animation_player = AnimationPlayer.new()
	_rig_animation_player.name = "RigAnimationPlayer"
	_rig_animation_player.root_node = NodePath("..")
	_rigged_drake.add_child(_rig_animation_player)

	var idle_animation := Animation.new()
	idle_animation.resource_name = "idle"
	idle_animation.length = 2.4
	idle_animation.loop_mode = Animation.LOOP_LINEAR

	var scale_track := idle_animation.add_track(Animation.TYPE_VALUE)
	idle_animation.track_set_path(
		scale_track,
		NodePath("Skeleton2D/RootAnchor/ChestBone:scale")
	)
	idle_animation.track_set_interpolation_type(scale_track, Animation.INTERPOLATION_CUBIC)
	idle_animation.track_insert_key(scale_track, 0.0, Vector2.ONE)
	idle_animation.track_insert_key(scale_track, 0.6, Vector2(1.012, 1.009))
	idle_animation.track_insert_key(scale_track, 1.2, Vector2(1.035, 1.025))
	idle_animation.track_insert_key(scale_track, 1.8, Vector2(1.012, 1.009))
	idle_animation.track_insert_key(scale_track, 2.4, Vector2.ONE)

	var rotation_track := idle_animation.add_track(Animation.TYPE_VALUE)
	idle_animation.track_set_path(
		rotation_track,
		NodePath("Skeleton2D/RootAnchor/ChestBone:rotation")
	)
	idle_animation.track_set_interpolation_type(rotation_track, Animation.INTERPOLATION_CUBIC)
	idle_animation.track_insert_key(rotation_track, 0.0, 0.0)
	idle_animation.track_insert_key(rotation_track, 0.6, -0.004)
	idle_animation.track_insert_key(rotation_track, 1.2, -0.012)
	idle_animation.track_insert_key(rotation_track, 1.8, -0.004)
	idle_animation.track_insert_key(rotation_track, 2.4, 0.0)

	var animation_library := AnimationLibrary.new()
	var library_error := animation_library.add_animation(&"idle", idle_animation)
	if library_error != OK:
		push_error("Could not register Forest Drake skeletal idle animation.")
		return
	_rig_animation_player.add_animation_library(&"", animation_library)
	_rig_animation_player.play(&"idle")

	print("[AnimationProof] Skeletal rig created: 33x33 UV grid, %d vertices, %d quads, chest weight max 0.82." % [
		points.size(),
		mesh_polygons.size()
	])
	print("[AnimationProof] Fixed root anchor at source image %s; chest pivot at %s." % [
		str(ground_anchor),
		str(chest_center)
	])


func _create_contact_shadow_texture() -> Texture2D:
	var image := Image.create(96, 20, false, Image.FORMAT_RGBA8)
	var center := Vector2(47.5, 9.5)
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var dx := (float(x) - center.x) / 45.0
			var dy := (float(y) - center.y) / 8.0
			var distance_squared := dx * dx + dy * dy
			var falloff := clampf(1.0 - distance_squared, 0.0, 1.0)
			var alpha := 0.18 * falloff * falloff
			image.set_pixel(x, y, Color(0.075, 0.105, 0.075, alpha))
	return ImageTexture.create_from_image(image)


func _apply_drake_scale() -> void:
	var target_height_px := _drake_height_gcu * CELL_SIZE.y
	if _animated_drake != null:
		var scale_value := target_height_px / maxf(_animated_drake_source_height, 1.0)
		_animated_drake.scale = Vector2.ONE * scale_value
	if _rigged_drake != null:
		var rig_scale := target_height_px / maxf(_rigged_drake_source_height, 1.0)
		_rigged_drake.scale = Vector2.ONE * rig_scale
	if _static_drake != null:
		var static_scale := target_height_px / maxf(_static_drake_source_height, 1.0)
		_static_drake.scale = Vector2.ONE * static_scale
	if _status_label != null:
		_update_status()


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
	_report_image("%s (corner matte removed: %s)" % [label, str(matte_removed)], image, matte_removed)
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


func _report_frame(label: String, image: Image, matte_removed: bool) -> void:
	var corners: Array[Color] = [
		image.get_pixel(3, 3),
		image.get_pixel(image.get_width() - 4, 3),
		image.get_pixel(3, image.get_height() - 4),
		image.get_pixel(image.get_width() - 4, image.get_height() - 4)
	]
	print("[AnimationProof] %s | alpha_mode=%d | matte_removed=%s | corners=%s,%s,%s,%s" % [
		label,
		image.detect_alpha(),
		str(matte_removed),
		str(corners[0]),
		str(corners[1]),
		str(corners[2]),
		str(corners[3])
	])


func _report_image(label: String, image: Image, matte_removed: bool) -> void:
	print("[AnimationProof] %s | %dx%d | alpha_mode=%d | matte_removed=%s | visible_bounds=%s" % [
		label,
		image.get_width(),
		image.get_height(),
		image.detect_alpha(),
		str(matte_removed),
		str(_get_visible_bounds(image))
	])


func _build_overlay() -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "ReviewHUD"
	canvas.layer = 10
	add_child(canvas)

	var title := Label.new()
	title.position = Vector2(24.0, 16.0)
	title.text = "POCKET WORLDS  |  ANIMATION PROOF V2"
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
	controls.position = Vector2(24.0, 676.0)
	controls.text = "SPACE cycle RIG / SHEET / STATIC | 4 64px | 5 80px | 6 96px | R restart"
	controls.add_theme_font_size_override("font_size", 14)
	controls.add_theme_color_override("font_color", Color("#f3eddc"))
	canvas.add_child(controls)


func _update_status() -> void:
	if _status_label == null:
		return
	var size_text := "%.2f GCU / %.0f px" % [_drake_height_gcu, _drake_height_gcu * CELL_SIZE.y]
	match _display_mode:
		&"rig":
			_status_label.text = "FOREST DRAKE  •  SKELETAL IDLE  •  FIXED ROOT / CHEST DEFORMATION  •  %s" % size_text
		&"sheet":
			_status_label.text = "FOREST DRAKE  •  16-FRAME SPRITE IDLE  •  0.15 SEC/FRAME  •  %s" % size_text
		_:
			_status_label.text = "FOREST DRAKE  •  STATIC REFERENCE  •  %s" % size_text


func _set_drake_height_gcu(next_height: float) -> void:
	_drake_height_gcu = next_height
	_apply_drake_scale()
	_update_status()


func _set_display_mode(next_mode: StringName) -> void:
	_display_mode = next_mode
	if _rigged_drake != null:
		_rigged_drake.visible = _display_mode == &"rig"
	if _animated_drake != null:
		_animated_drake.visible = _display_mode == &"sheet"
		if _display_mode == &"sheet":
			_animated_drake.play(&"idle")
		else:
			_animated_drake.stop()
	if _static_drake != null:
		_static_drake.visible = _display_mode == &"static"
	if _rig_animation_player != null:
		if _display_mode == &"rig":
			_rig_animation_player.play(&"idle")
		else:
			_rig_animation_player.stop()
	_update_status()


func _cycle_display_mode() -> void:
	match _display_mode:
		&"rig":
			_set_display_mode(&"sheet")
		&"sheet":
			_set_display_mode(&"static")
		_:
			_set_display_mode(&"rig")


func _restart_current_animation() -> void:
	match _display_mode:
		&"rig":
			if _rig_animation_player != null:
				_rig_animation_player.play(&"idle")
		&"sheet":
			if _animated_drake != null:
				_animated_drake.play(&"idle")


func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return

	match key_event.keycode:
		KEY_SPACE:
			_cycle_display_mode()
		KEY_4:
			_set_drake_height_gcu(1.0)
		KEY_5:
			_set_drake_height_gcu(1.25)
		KEY_6:
			_set_drake_height_gcu(1.5)
		KEY_R:
			_restart_current_animation()
