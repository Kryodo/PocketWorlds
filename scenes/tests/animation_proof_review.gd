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
var _rig_animation_players: Array[AnimationPlayer] = []
var _chest_bone: Bone2D
var _body_motion_bone: Bone2D
var _head_bone: Bone2D
var _wing_bone: Bone2D
var _tail_bone: Bone2D
var _front_leg_near_bone: Bone2D
var _front_leg_far_bone: Bone2D
var _front_leg_near_rest_position := Vector2.ZERO
var _front_leg_far_rest_position := Vector2.ZERO
var _head_rest_position := Vector2.ZERO
var _posture_animation_player: AnimationPlayer
var _lying_idle_player: AnimationPlayer
var _posture_state: StringName = &"standing"
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

	print("ANIMATION PROOF V5 — LYING POSE / LEG ARTICULATION / SHADOW REFINEMENT")
	print("Ground: 7x5 candidate grid, 128x64 GCU, 1024x512 source tiles at 0.125 scale.")
	print("Drake idle: 16 frames, 4x4 sheet, %.1f FPS, target %.2f GCU / %.0f px." % [
		DEFAULT_IDLE_FPS,
		_drake_height_gcu,
		_drake_height_gcu * CELL_SIZE.y
	])
	print("Controls: L=toggle STANDING/LYING | SPACE cycle RIG/SHEET/STATIC | 4/5/6=size | R=reset standing idle")


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
	# 128x64 isometric footprint: broad enough to read around the feet at game scale.
	_drake_shadow.scale = Vector2(0.80, 0.68)
	_drake_shadow.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
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
	_rigged_drake.name = "ForestDrake_MultiPartRig"
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

	# These pivots are approximate articulation points on the approved flat artwork.
	# Keep the root at the ground anchor; all secondary bones inherit from the torso.
	var torso_pivot := Vector2(520.0, 565.0)
	var head_pivot := Vector2(438.0, 535.0)
	var wing_pivot := Vector2(590.0, 510.0)
	var tail_pivot := Vector2(690.0, 585.0)

	# BodyMotionBone carries the whole upper body vertically during breathing.
	# TorsoBone alone scales, so the head/wing/tail do not inherit torso expansion.
	var body_motion_bone := Bone2D.new()
	body_motion_bone.name = "BodyMotionBone"
	body_motion_bone.position = Vector2.ZERO
	body_motion_bone.set_autocalculate_length_and_angle(false)
	body_motion_bone.length = 1.0
	root_bone.add_child(body_motion_bone)
	_body_motion_bone = body_motion_bone

	var torso_bone := Bone2D.new()
	torso_bone.name = "TorsoBone"
	torso_bone.position = torso_pivot - ground_anchor
	torso_bone.set_autocalculate_length_and_angle(false)
	torso_bone.length = 105.0
	body_motion_bone.add_child(torso_bone)
	_chest_bone = torso_bone

	var head_bone := Bone2D.new()
	head_bone.name = "HeadNeckBone"
	head_bone.position = head_pivot - ground_anchor
	head_bone.set_autocalculate_length_and_angle(false)
	head_bone.length = 82.0
	body_motion_bone.add_child(head_bone)
	_head_bone = head_bone
	_head_rest_position = head_bone.position

	var wing_bone := Bone2D.new()
	wing_bone.name = "WingBone"
	wing_bone.position = wing_pivot - ground_anchor
	wing_bone.set_autocalculate_length_and_angle(false)
	wing_bone.length = 65.0
	body_motion_bone.add_child(wing_bone)
	_wing_bone = wing_bone

	var tail_bone := Bone2D.new()
	tail_bone.name = "TailBone"
	tail_bone.position = tail_pivot - ground_anchor
	tail_bone.set_autocalculate_length_and_angle(false)
	tail_bone.length = 90.0
	body_motion_bone.add_child(tail_bone)
	_tail_bone = tail_bone

	# The forelegs remain attached to the fixed ground-root rather than the
	# descending torso, so they can reach forward and stay grounded as the chest lowers.
	var front_leg_near_bone := Bone2D.new()
	front_leg_near_bone.name = "FrontLegNearBone"
	front_leg_near_bone.position = Vector2(430.0, 670.0) - ground_anchor
	front_leg_near_bone.set_autocalculate_length_and_angle(false)
	front_leg_near_bone.length = 72.0
	root_bone.add_child(front_leg_near_bone)
	_front_leg_near_bone = front_leg_near_bone
	_front_leg_near_rest_position = front_leg_near_bone.position

	var front_leg_far_bone := Bone2D.new()
	front_leg_far_bone.name = "FrontLegFarBone"
	front_leg_far_bone.position = Vector2(555.0, 675.0) - ground_anchor
	front_leg_far_bone.set_autocalculate_length_and_angle(false)
	front_leg_far_bone.length = 72.0
	root_bone.add_child(front_leg_far_bone)
	_front_leg_far_bone = front_leg_far_bone
	_front_leg_far_rest_position = front_leg_far_bone.position

	# Cache the default pose before animation starts.
	root_bone.rest = root_bone.transform
	body_motion_bone.rest = body_motion_bone.transform
	torso_bone.rest = torso_bone.transform
	head_bone.rest = head_bone.transform
	wing_bone.rest = wing_bone.transform
	tail_bone.rest = tail_bone.transform
	front_leg_near_bone.rest = front_leg_near_bone.transform
	front_leg_far_bone.rest = front_leg_far_bone.transform

	# A denser grid gives the narrow tail and wing membrane more vertices to bend.
	const GRID_COLUMNS := 49
	const GRID_ROWS := 49
	var points := PackedVector2Array()
	var uvs := PackedVector2Array()
	var root_weights := PackedFloat32Array()
	var torso_weights := PackedFloat32Array()
	var head_weights := PackedFloat32Array()
	var wing_weights := PackedFloat32Array()
	var tail_weights := PackedFloat32Array()
	var front_leg_near_weights := PackedFloat32Array()
	var front_leg_far_weights := PackedFloat32Array()
	var mesh_polygons: Array = []

	var torso_center := Vector2(520.0, 620.0)
	var torso_radii := Vector2(225.0, 175.0)
	var head_center := Vector2(385.0, 395.0)
	var head_radii := Vector2(215.0, 205.0)
	var wing_center := Vector2(620.0, 468.0)
	var wing_radii := Vector2(165.0, 135.0)
	var tail_center := Vector2(790.0, 650.0)
	var tail_radii := Vector2(155.0, 140.0)
	# Approximate source-image regions for the two visible forelegs. Keep these
	# influences tight so the new reach does not drag the belly or shoulder.
	var front_leg_near_center := Vector2(410.0, 760.0)
	var front_leg_far_center := Vector2(545.0, 760.0)
	var front_leg_radii := Vector2(92.0, 86.0)

	for row in range(GRID_ROWS):
		for column in range(GRID_COLUMNS):
			var source_point := Vector2(
				float(column) * float(image_width) / float(GRID_COLUMNS - 1),
				float(row) * float(image_height) / float(GRID_ROWS - 1)
			)
			points.append(source_point - ground_anchor)
			uvs.append(source_point)

			var torso_weight := _elliptical_bone_influence(source_point, torso_center, torso_radii, 0.92)
			# A broad high-weight core keeps the head volume stable; only the outer edge feathers.
			var head_weight := _elliptical_bone_influence(source_point, head_center, head_radii, 0.96, 0.70)
			var wing_weight := _elliptical_bone_influence(source_point, wing_center, wing_radii, 0.92)
			var tail_weight := _elliptical_bone_influence(source_point, tail_center, tail_radii, 0.95)
			var front_leg_near_weight := _elliptical_bone_influence(source_point, front_leg_near_center, front_leg_radii, 0.96, 0.34)
			var front_leg_far_weight := _elliptical_bone_influence(source_point, front_leg_far_center, front_leg_radii, 0.96, 0.34)

			# Leave a small root influence everywhere, and normalize overlaps so weights sum to one.
			var total_weight := torso_weight + head_weight + wing_weight + tail_weight + front_leg_near_weight + front_leg_far_weight
			if total_weight > 0.94:
				var normalization := 0.94 / total_weight
				torso_weight *= normalization
				head_weight *= normalization
				wing_weight *= normalization
				tail_weight *= normalization
				front_leg_near_weight *= normalization
				front_leg_far_weight *= normalization
				total_weight = 0.94

			root_weights.append(1.0 - total_weight)
			torso_weights.append(torso_weight)
			head_weights.append(head_weight)
			wing_weights.append(wing_weight)
			tail_weights.append(tail_weight)
			front_leg_near_weights.append(front_leg_near_weight)
			front_leg_far_weights.append(front_leg_far_weight)

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
	character_mesh.name = "TexturedMultiBoneMesh"
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
	character_mesh.add_bone(character_mesh.get_path_to(torso_bone), torso_weights)
	character_mesh.add_bone(character_mesh.get_path_to(head_bone), head_weights)
	character_mesh.add_bone(character_mesh.get_path_to(wing_bone), wing_weights)
	character_mesh.add_bone(character_mesh.get_path_to(tail_bone), tail_weights)
	character_mesh.add_bone(character_mesh.get_path_to(front_leg_near_bone), front_leg_near_weights)
	character_mesh.add_bone(character_mesh.get_path_to(front_leg_far_bone), front_leg_far_weights)

	_rig_animation_players.clear()

	# Layer 1: the whole upper body rises and settles, while only the torso expands.
	# Keeping torso scale on its own child prevents the head from appearing to inflate.
	var body_animation := Animation.new()
	body_animation.resource_name = "body_breathing"
	body_animation.length = 3.6
	body_animation.loop_mode = Animation.LOOP_LINEAR
	_add_bone_value_track(body_animation, "Skeleton2D/RootAnchor/BodyMotionBone:position",
		PackedFloat64Array([0.0, 0.9, 1.6, 2.4, 3.6]),
		[Vector2.ZERO, Vector2(0.0, -5.0), Vector2(0.0, -10.0), Vector2(0.0, -3.0), Vector2.ZERO])
	_add_bone_value_track(body_animation, "Skeleton2D/RootAnchor/BodyMotionBone:rotation",
		PackedFloat64Array([0.0, 0.9, 1.6, 2.4, 3.6]),
		[0.0, -0.004, -0.009, -0.003, 0.0])
	_add_bone_value_track(body_animation, "Skeleton2D/RootAnchor/BodyMotionBone/TorsoBone:scale",
		PackedFloat64Array([0.0, 0.9, 1.6, 2.4, 3.6]),
		[Vector2.ONE, Vector2(1.035, 1.05), Vector2(1.07, 1.10), Vector2(1.025, 1.025), Vector2.ONE])
	_rig_animation_player = _create_rig_layer_player("BodyBreathingPlayer", body_animation)

	# Layer 2: gentle left/right looks. Rotation and a tiny horizontal shift move the
	# head as a unit; there is deliberately no head scale track.
	var head_animation := Animation.new()
	head_animation.resource_name = "head_look_around"
	head_animation.length = 6.3
	head_animation.loop_mode = Animation.LOOP_LINEAR
	var head_rest_position := head_pivot - ground_anchor
	_add_bone_value_track(head_animation, "Skeleton2D/RootAnchor/BodyMotionBone/HeadNeckBone:rotation",
		PackedFloat64Array([0.0, 0.9, 1.5, 2.15, 2.8, 3.6, 4.25, 4.9, 5.55, 6.3]),
		[0.0, 0.0, -0.045, -0.035, 0.0, 0.0, 0.045, 0.035, 0.0, 0.0])
	_add_bone_value_track(head_animation, "Skeleton2D/RootAnchor/BodyMotionBone/HeadNeckBone:position",
		PackedFloat64Array([0.0, 0.9, 1.5, 2.15, 2.8, 3.6, 4.25, 4.9, 5.55, 6.3]),
		[head_rest_position, head_rest_position, head_rest_position + Vector2(-5.0, 0.0), head_rest_position + Vector2(-4.0, -1.0), head_rest_position, head_rest_position, head_rest_position + Vector2(5.0, 0.0), head_rest_position + Vector2(4.0, -1.0), head_rest_position, head_rest_position])
	_create_rig_layer_player("HeadIdlePlayer", head_animation)

	# Layer 3: one visible wing makes an occasional adjustment, not a constant flap.
	var wing_animation := Animation.new()
	wing_animation.resource_name = "wing_settle"
	wing_animation.length = 7.8
	wing_animation.loop_mode = Animation.LOOP_LINEAR
	_add_bone_value_track(wing_animation, "Skeleton2D/RootAnchor/BodyMotionBone/WingBone:rotation",
		PackedFloat64Array([0.0, 1.6, 2.1, 2.7, 3.5, 5.2, 5.7, 6.2, 7.8]),
		[0.0, 0.0, -0.11, -0.075, 0.0, 0.0, 0.055, 0.0, 0.0])
	_create_rig_layer_player("WingIdlePlayer", wing_animation)

	# Layer 4: the tail has its own slower, offset sway cycle.
	var tail_animation := Animation.new()
	tail_animation.resource_name = "tail_sway"
	tail_animation.length = 5.1
	tail_animation.loop_mode = Animation.LOOP_LINEAR
	_add_bone_value_track(tail_animation, "Skeleton2D/RootAnchor/BodyMotionBone/TailBone:rotation",
		PackedFloat64Array([0.0, 0.8, 1.5, 2.2, 3.1, 3.8, 5.1]),
		[0.0, 0.0, -0.11, -0.05, 0.095, 0.04, 0.0])
	_create_rig_layer_player("TailIdlePlayer", tail_animation)

	_create_posture_players()

	print("[AnimationProof] Multi-part rig: 49x49 grid, %d vertices, %d quads; torso/head/wing/tail weights active." % [
		points.size(),
		mesh_polygons.size()
	])
	print("[AnimationProof] Independent idle layers: body 3.6s, head 6.3s, wing 7.8s, tail 5.1s. The root anchor is fixed.")


func _elliptical_bone_influence(point: Vector2, center: Vector2, radii: Vector2, maximum_weight: float, full_weight_core: float = 0.22) -> float:
	var normalized_distance := Vector2(
		(point.x - center.x) / radii.x,
		(point.y - center.y) / radii.y
	).length()
	var transition := clampf((normalized_distance - full_weight_core) / (1.0 - full_weight_core), 0.0, 1.0)
	var smooth_transition := transition * transition * (3.0 - 2.0 * transition)
	return maximum_weight * (1.0 - smooth_transition)


func _add_bone_value_track(animation: Animation, property_path: String, key_times: PackedFloat64Array, key_values: Array) -> void:
	var track_index := animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(track_index, NodePath(property_path))
	animation.track_set_interpolation_type(track_index, Animation.INTERPOLATION_CUBIC)
	for index in range(key_times.size()):
		animation.track_insert_key(track_index, key_times[index], key_values[index])


func _create_rig_layer_player(player_name: String, animation: Animation) -> AnimationPlayer:
	var player := AnimationPlayer.new()
	player.name = player_name
	player.root_node = NodePath("..")
	_rigged_drake.add_child(player)

	var animation_library := AnimationLibrary.new()
	var library_error := animation_library.add_animation(&"idle", animation)
	if library_error != OK:
		push_error("Could not register Forest Drake animation layer: %s" % player_name)
		return player

	player.add_animation_library(&"", animation_library)
	player.play(&"idle")
	_rig_animation_players.append(player)
	return player


func _create_posture_players() -> void:
	# Posture animation is deliberately separate from the approved standing-idle
	# layers. The idle tracks are not edited; they are paused during transitions.
	_posture_animation_player = AnimationPlayer.new()
	_posture_animation_player.name = "PostureTransitionPlayer"
	_posture_animation_player.root_node = NodePath("..")
	_rigged_drake.add_child(_posture_animation_player)
	var posture_library := AnimationLibrary.new()
	_posture_animation_player.add_animation_library(&"", posture_library)
	_posture_animation_player.animation_finished.connect(_on_posture_transition_finished)

	_lying_idle_player = AnimationPlayer.new()
	_lying_idle_player.name = "LyingIdlePlayer"
	_lying_idle_player.root_node = NodePath("..")
	_rigged_drake.add_child(_lying_idle_player)
	var lying_library := AnimationLibrary.new()
	var lying_animation := Animation.new()
	lying_animation.resource_name = "lying_idle"
	lying_animation.length = 7.2
	lying_animation.loop_mode = Animation.LOOP_LINEAR

	# A low, slow breathing cycle with occasional independent head, wing and tail
	# adjustments. These tracks only run after the down-transition completes.
	_add_bone_value_track(lying_animation, "Skeleton2D/RootAnchor/BodyMotionBone:position",
		PackedFloat64Array([0.0, 1.2, 2.4, 3.6, 4.8, 6.0, 7.2]),
		[Vector2(0.0, 52.0), Vector2(0.0, 49.0), Vector2(0.0, 52.0), Vector2(0.0, 52.0), Vector2(0.0, 49.0), Vector2(0.0, 52.0), Vector2(0.0, 52.0)])
	_add_bone_value_track(lying_animation, "Skeleton2D/RootAnchor/BodyMotionBone/TorsoBone:scale",
		PackedFloat64Array([0.0, 1.2, 2.4, 3.6, 4.8, 6.0, 7.2]),
		[Vector2(1.015, 0.72), Vector2(1.035, 0.76), Vector2(1.015, 0.72), Vector2(1.015, 0.72), Vector2(1.035, 0.76), Vector2(1.015, 0.72), Vector2(1.015, 0.72)])
	_add_bone_value_track(lying_animation, "Skeleton2D/RootAnchor/BodyMotionBone/HeadNeckBone:rotation",
		PackedFloat64Array([0.0, 2.4, 2.9, 3.5, 4.2, 7.2]),
		[0.10, 0.10, 0.055, 0.10, 0.10, 0.10])
	_add_bone_value_track(lying_animation, "Skeleton2D/RootAnchor/BodyMotionBone/WingBone:rotation",
		PackedFloat64Array([0.0, 4.9, 5.3, 5.8, 7.2]),
		[-0.17, -0.17, -0.11, -0.17, -0.17])
	_add_bone_value_track(lying_animation, "Skeleton2D/RootAnchor/BodyMotionBone/TailBone:rotation",
		PackedFloat64Array([0.0, 3.5, 3.9, 4.4, 7.2]),
		[0.08, 0.08, 0.035, 0.08, 0.08])

	var lying_error := lying_library.add_animation(&"lying_idle", lying_animation)
	if lying_error != OK:
		push_error("Could not register Forest Drake lying idle.")
		return
	_lying_idle_player.add_animation_library(&"", lying_library)


func _get_live_posture_values() -> Dictionary:
	return {
		"Skeleton2D/RootAnchor/BodyMotionBone:position": _body_motion_bone.position,
		"Skeleton2D/RootAnchor/BodyMotionBone:rotation": _body_motion_bone.rotation,
		"Skeleton2D/RootAnchor/FrontLegNearBone:position": _front_leg_near_bone.position,
		"Skeleton2D/RootAnchor/FrontLegNearBone:rotation": _front_leg_near_bone.rotation,
		"Skeleton2D/RootAnchor/FrontLegFarBone:position": _front_leg_far_bone.position,
		"Skeleton2D/RootAnchor/FrontLegFarBone:rotation": _front_leg_far_bone.rotation,
		"Skeleton2D/RootAnchor/BodyMotionBone/TorsoBone:scale": _chest_bone.scale,
		"Skeleton2D/RootAnchor/BodyMotionBone/HeadNeckBone:position": _head_bone.position,
		"Skeleton2D/RootAnchor/BodyMotionBone/HeadNeckBone:rotation": _head_bone.rotation,
		"Skeleton2D/RootAnchor/BodyMotionBone/WingBone:rotation": _wing_bone.rotation,
		"Skeleton2D/RootAnchor/BodyMotionBone/TailBone:rotation": _tail_bone.rotation
	}


func _get_standing_posture_values() -> Dictionary:
	return {
		"Skeleton2D/RootAnchor/BodyMotionBone:position": Vector2.ZERO,
		"Skeleton2D/RootAnchor/BodyMotionBone:rotation": 0.0,
		"Skeleton2D/RootAnchor/FrontLegNearBone:position": _front_leg_near_rest_position,
		"Skeleton2D/RootAnchor/FrontLegNearBone:rotation": 0.0,
		"Skeleton2D/RootAnchor/FrontLegFarBone:position": _front_leg_far_rest_position,
		"Skeleton2D/RootAnchor/FrontLegFarBone:rotation": 0.0,
		"Skeleton2D/RootAnchor/BodyMotionBone/TorsoBone:scale": Vector2.ONE,
		"Skeleton2D/RootAnchor/BodyMotionBone/HeadNeckBone:position": _head_rest_position,
		"Skeleton2D/RootAnchor/BodyMotionBone/HeadNeckBone:rotation": 0.0,
		"Skeleton2D/RootAnchor/BodyMotionBone/WingBone:rotation": 0.0,
		"Skeleton2D/RootAnchor/BodyMotionBone/TailBone:rotation": 0.0
	}


func _get_lying_posture_values() -> Dictionary:
	return {
		"Skeleton2D/RootAnchor/BodyMotionBone:position": Vector2(0.0, 52.0),
		"Skeleton2D/RootAnchor/BodyMotionBone:rotation": 0.015,
		"Skeleton2D/RootAnchor/FrontLegNearBone:position": _front_leg_near_rest_position + Vector2(-26.0, -14.0),
		"Skeleton2D/RootAnchor/FrontLegNearBone:rotation": 0.075,
		"Skeleton2D/RootAnchor/FrontLegFarBone:position": _front_leg_far_rest_position + Vector2(-20.0, -12.0),
		"Skeleton2D/RootAnchor/FrontLegFarBone:rotation": -0.075,
		"Skeleton2D/RootAnchor/BodyMotionBone/TorsoBone:scale": Vector2(1.015, 0.72),
		"Skeleton2D/RootAnchor/BodyMotionBone/HeadNeckBone:position": _head_rest_position + Vector2(-4.0, 34.0),
		"Skeleton2D/RootAnchor/BodyMotionBone/HeadNeckBone:rotation": 0.10,
		"Skeleton2D/RootAnchor/BodyMotionBone/WingBone:rotation": -0.17,
		"Skeleton2D/RootAnchor/BodyMotionBone/TailBone:rotation": 0.08
	}


func _add_posture_transition_track(animation: Animation, property_path: String, start_value: Variant, end_value: Variant, delay: float, duration: float, total_duration: float) -> void:
	var track_index := animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(track_index, NodePath(property_path))
	animation.track_set_interpolation_type(track_index, Animation.INTERPOLATION_LINEAR)
	animation.track_insert_key(track_index, 0.0, start_value)
	if delay > 0.001:
		animation.track_insert_key(track_index, delay, start_value)

	for step in range(1, 4):
		var progress := float(step) / 4.0
		var eased_progress := progress * progress * (3.0 - 2.0 * progress)
		var key_time := delay + duration * progress
		animation.track_insert_key(track_index, key_time, _interpolate_posture_value(start_value, end_value, eased_progress))

	var finish_time := delay + duration
	animation.track_insert_key(track_index, finish_time, end_value)
	if finish_time < total_duration:
		animation.track_insert_key(track_index, total_duration, end_value)


func _interpolate_posture_value(from_value: Variant, to_value: Variant, weight: float) -> Variant:
	if typeof(from_value) == TYPE_VECTOR2:
		return Vector2(from_value).lerp(Vector2(to_value), weight)
	return lerpf(float(from_value), float(to_value), weight)


func _start_posture_transition(target_lying: bool) -> void:
	if _display_mode != &"rig" or _posture_state == &"to_lying" or _posture_state == &"to_standing":
		return
	if target_lying and _posture_state == &"lying":
		return
	if not target_lying and _posture_state == &"standing":
		return

	# Pause whichever idle is active and preserve its exact current transforms.
	# The first transition key is built from those values, avoiding a pose snap.
	for layer_player in _rig_animation_players:
		layer_player.pause()
	if _lying_idle_player != null:
		_lying_idle_player.pause()

	var start_values := _get_live_posture_values()
	if _posture_animation_player != null:
		_posture_animation_player.stop(true)
	var target_values := _get_lying_posture_values() if target_lying else _get_standing_posture_values()
	var total_duration := 2.8 if target_lying else 2.6
	var track_specs: Array[Dictionary] = []

	if target_lying:
		# Settle the body first; then fold the wing and lower the head into rest.
		track_specs = [
			{"path": "Skeleton2D/RootAnchor/BodyMotionBone:position", "delay": 0.0, "duration": 1.85},
			{"path": "Skeleton2D/RootAnchor/FrontLegNearBone:position", "delay": 0.45, "duration": 1.3},
			{"path": "Skeleton2D/RootAnchor/FrontLegNearBone:rotation", "delay": 0.5, "duration": 1.1},
			{"path": "Skeleton2D/RootAnchor/FrontLegFarBone:position", "delay": 0.45, "duration": 1.3},
			{"path": "Skeleton2D/RootAnchor/FrontLegFarBone:rotation", "delay": 0.5, "duration": 1.1},
			{"path": "Skeleton2D/RootAnchor/BodyMotionBone:rotation", "delay": 0.0, "duration": 1.65},
			{"path": "Skeleton2D/RootAnchor/BodyMotionBone/TorsoBone:scale", "delay": 0.35, "duration": 1.35},
			{"path": "Skeleton2D/RootAnchor/BodyMotionBone/WingBone:rotation", "delay": 0.2, "duration": 1.05},
			{"path": "Skeleton2D/RootAnchor/BodyMotionBone/TailBone:rotation", "delay": 0.8, "duration": 1.0},
			{"path": "Skeleton2D/RootAnchor/BodyMotionBone/HeadNeckBone:position", "delay": 0.95, "duration": 1.05},
			{"path": "Skeleton2D/RootAnchor/BodyMotionBone/HeadNeckBone:rotation", "delay": 0.95, "duration": 1.05}
		]
		_posture_state = &"to_lying"
	else:
		# Lift the head and unfold the wing first; then raise the chest and body.
		track_specs = [
			{"path": "Skeleton2D/RootAnchor/FrontLegNearBone:position", "delay": 0.0, "duration": 0.75},
			{"path": "Skeleton2D/RootAnchor/FrontLegNearBone:rotation", "delay": 0.0, "duration": 0.75},
			{"path": "Skeleton2D/RootAnchor/FrontLegFarBone:position", "delay": 0.0, "duration": 0.75},
			{"path": "Skeleton2D/RootAnchor/FrontLegFarBone:rotation", "delay": 0.0, "duration": 0.75},
			{"path": "Skeleton2D/RootAnchor/BodyMotionBone/HeadNeckBone:position", "delay": 0.0, "duration": 0.95},
			{"path": "Skeleton2D/RootAnchor/BodyMotionBone/HeadNeckBone:rotation", "delay": 0.0, "duration": 0.9},
			{"path": "Skeleton2D/RootAnchor/BodyMotionBone/WingBone:rotation", "delay": 0.0, "duration": 0.9},
			{"path": "Skeleton2D/RootAnchor/BodyMotionBone/TailBone:rotation", "delay": 0.1, "duration": 0.8},
			{"path": "Skeleton2D/RootAnchor/BodyMotionBone/TorsoBone:scale", "delay": 0.35, "duration": 1.1},
			{"path": "Skeleton2D/RootAnchor/BodyMotionBone:position", "delay": 0.65, "duration": 1.45},
			{"path": "Skeleton2D/RootAnchor/BodyMotionBone:rotation", "delay": 0.65, "duration": 1.3}
		]
		_posture_state = &"to_standing"

	var transition := Animation.new()
	transition.resource_name = "posture_transition"
	transition.length = total_duration
	transition.loop_mode = Animation.LOOP_NONE
	for spec in track_specs:
		var property_path: String = spec["path"]
		_add_posture_transition_track(
			transition,
			property_path,
			start_values[property_path],
			target_values[property_path],
			float(spec["delay"]),
			float(spec["duration"]),
			total_duration
		)

	var posture_library := _posture_animation_player.get_animation_library(&"")
	if posture_library.has_animation(&"transition"):
		posture_library.remove_animation(&"transition")
	var add_error := posture_library.add_animation(&"transition", transition)
	if add_error != OK:
		push_error("Could not create Forest Drake posture transition.")
		_posture_state = &"standing" if target_lying else &"lying"
		return
	_posture_animation_player.play(&"transition")
	_update_status()


func _on_posture_transition_finished(animation_name: StringName) -> void:
	if animation_name != &"transition":
		return
	if _posture_state == &"to_lying":
		_posture_state = &"lying"
		_lying_idle_player.stop()
		_lying_idle_player.play(&"lying_idle")
	elif _posture_state == &"to_standing":
		_posture_state = &"standing"
		for layer_player in _rig_animation_players:
			# Restart at the exact standing rest keys, then resume the approved idle cycles.
			layer_player.stop()
			layer_player.play(&"idle")
	_update_status()


func _reset_posture_to_standing() -> void:
	if _posture_animation_player != null:
		_posture_animation_player.stop(true)
	if _lying_idle_player != null:
		_lying_idle_player.stop(true)
	if _body_motion_bone == null:
		_posture_state = &"standing"
		return
	var standing_values := _get_standing_posture_values()
	_body_motion_bone.position = standing_values["Skeleton2D/RootAnchor/BodyMotionBone:position"]
	_body_motion_bone.rotation = standing_values["Skeleton2D/RootAnchor/BodyMotionBone:rotation"]
	_chest_bone.scale = standing_values["Skeleton2D/RootAnchor/BodyMotionBone/TorsoBone:scale"]
	_head_bone.position = standing_values["Skeleton2D/RootAnchor/BodyMotionBone/HeadNeckBone:position"]
	_head_bone.rotation = standing_values["Skeleton2D/RootAnchor/BodyMotionBone/HeadNeckBone:rotation"]
	_front_leg_near_bone.position = standing_values["Skeleton2D/RootAnchor/FrontLegNearBone:position"]
	_front_leg_near_bone.rotation = standing_values["Skeleton2D/RootAnchor/FrontLegNearBone:rotation"]
	_front_leg_far_bone.position = standing_values["Skeleton2D/RootAnchor/FrontLegFarBone:position"]
	_front_leg_far_bone.rotation = standing_values["Skeleton2D/RootAnchor/FrontLegFarBone:rotation"]
	_wing_bone.rotation = standing_values["Skeleton2D/RootAnchor/BodyMotionBone/WingBone:rotation"]
	_tail_bone.rotation = standing_values["Skeleton2D/RootAnchor/BodyMotionBone/TailBone:rotation"]
	_posture_state = &"standing"


func _create_contact_shadow_texture() -> Texture2D:
	# A soft projected oval matching the 2:1 ground-diamond footprint. The old
	# 96x20, 0.18-alpha strip was too flat and too faint at the Drake's display scale.
	var image := Image.create(128, 64, false, Image.FORMAT_RGBA8)
	var center := Vector2(63.5, 31.5)
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var dx := (float(x) - center.x) / 59.0
			var dy := (float(y) - center.y) / 27.0
			var distance := sqrt(dx * dx + dy * dy)
			var falloff := clampf(1.0 - distance, 0.0, 1.0)
			var alpha := 0.34 * falloff * falloff
			image.set_pixel(x, y, Color(0.035, 0.052, 0.038, alpha))
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
	title.text = "POCKET WORLDS  |  ANIMATION PROOF V5"
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
	controls.text = "L toggle STANDING / LYING | SPACE RIG / SHEET / STATIC | 4 64px | 5 80px | 6 96px | R reset standing"
	controls.add_theme_font_size_override("font_size", 14)
	controls.add_theme_color_override("font_color", Color("#f3eddc"))
	canvas.add_child(controls)


func _update_status() -> void:
	if _status_label == null:
		return
	var size_text := "%.2f GCU / %.0f px" % [_drake_height_gcu, _drake_height_gcu * CELL_SIZE.y]
	match _display_mode:
		&"rig":
			var posture_label := "STANDING IDLE"
			match _posture_state:
				&"to_lying":
					posture_label = "LOWERING TO REST"
				&"lying":
					posture_label = "LYING IDLE"
				&"to_standing":
					posture_label = "RISING TO STAND"
			_status_label.text = "FOREST DRAKE  •  MULTI-PART RIG  •  %s  •  %s" % [posture_label, size_text]
		&"sheet":
			_status_label.text = "FOREST DRAKE  •  16-FRAME SPRITE IDLE  •  0.15 SEC/FRAME  •  %s" % size_text
		_:
			_status_label.text = "FOREST DRAKE  •  STATIC REFERENCE  •  %s" % size_text


func _set_drake_height_gcu(next_height: float) -> void:
	_drake_height_gcu = next_height
	_apply_drake_scale()
	_update_status()


func _set_display_mode(next_mode: StringName) -> void:
	if next_mode != &"rig":
		_reset_posture_to_standing()
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
	for layer_player in _rig_animation_players:
		if _display_mode == &"rig":
			layer_player.play(&"idle")
		else:
			layer_player.stop()
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
			_reset_posture_to_standing()
			for layer_player in _rig_animation_players:
				layer_player.play(&"idle")
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
		KEY_L:
			if _posture_state == &"standing":
				_start_posture_transition(true)
			elif _posture_state == &"lying":
				_start_posture_transition(false)
		KEY_R:
			_restart_current_animation()
