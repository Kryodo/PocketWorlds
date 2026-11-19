extends Node2D

# Isolated proof: animate the complete RGBA Forest Drake image with one weighted mesh.
# No limb cutouts or reconstructed artwork are required for this experiment.
const DRAKE_TEXTURE_PATH := "res://art_inbox/creatures/ForestDrake_RigMaster_SW34_1024.png"
const VIEWPORT_SIZE := Vector2(1280.0, 720.0)
const TARGET_VISIBLE_HEIGHT := 300.0
const GRID_COLUMNS := 49
const GRID_ROWS := 49
const WALK_CYCLE_SECONDS := 1.25
const STARTING_SPEED := 1.0
const MAX_BONE_WEIGHT := 0.96

# Source-image coordinates (1024x1024). These are initial estimates for the new
# southwest-facing master and are intentionally isolated here for easy calibration.
const BONE_NAMES := [
	"RootAnchor",
	"TorsoBone",
	"HeadNeckBone",
	"WingBone",
	"TailBone",
	"FrontLegNearBone",
	"FrontLegFarBone",
	"RearLegNearBone",
	"RearLegFarBone"
]

const REGION_CENTERS := {
	"torso": Vector2(505.0, 610.0),
	"head": Vector2(365.0, 420.0),
	"wing": Vector2(610.0, 475.0),
	"tail": Vector2(760.0, 625.0),
	"front_near": Vector2(435.0, 742.0),
	"front_far": Vector2(278.0, 710.0),
	"rear_near": Vector2(660.0, 710.0),
	"rear_far": Vector2(555.0, 735.0)
}

const REGION_RADII := {
	"torso": Vector2(225.0, 180.0),
	"head": Vector2(185.0, 205.0),
	"wing": Vector2(180.0, 150.0),
	"tail": Vector2(185.0, 140.0),
	"front_near": Vector2(82.0, 112.0),
	"front_far": Vector2(76.0, 108.0),
	"rear_near": Vector2(82.0, 105.0),
	"rear_far": Vector2(72.0, 100.0)
}

var _rig_root: Node2D
var _skeleton: Skeleton2D
var _mesh: Polygon2D
var _bones: Dictionary = {}
var _rest_positions: Dictionary = {}
var _body_motion_bone: Bone2D
var _torso_bone: Bone2D
var _head_bone: Bone2D
var _wing_bone: Bone2D
var _tail_bone: Bone2D
var _walk_phase := 0.0
var _walk_speed := STARTING_SPEED
var _playing := true
var _status_label: Label
var _bounds := Rect2i()
var _ground_anchor := Vector2.ZERO


func _ready() -> void:
	_build_background()
	var texture := load(DRAKE_TEXTURE_PATH) as Texture2D
	if texture == null:
		push_error("Could not load the new Forest Drake master: %s" % DRAKE_TEXTURE_PATH)
		_build_error_label("Missing ForestDrake_RigMaster_SW34_1024.png")
		return

	var character_image := texture.get_image()
	if character_image == null or character_image.is_empty():
		push_error("The Forest Drake master image is empty.")
		_build_error_label("The Forest Drake texture could not be read.")
		return
	if character_image.is_compressed():
		var decompress_error := character_image.decompress()
		if decompress_error != OK:
			push_error("Could not decompress the Forest Drake master.")
			_build_error_label("Could not decompress the Drake PNG.")
			return
	character_image.convert(Image.FORMAT_RGBA8)

	_bounds = _get_visible_bounds(character_image)
	if _bounds.size == Vector2i.ZERO:
		push_error("No visible pixels were found in the Forest Drake master.")
		_build_error_label("The Drake image appears fully transparent.")
		return

	_ground_anchor = Vector2(
		float(_bounds.position.x) + float(_bounds.size.x) * 0.5,
		float(_bounds.position.y + _bounds.size.y)
	)

	_rig_root = Node2D.new()
	_rig_root.name = "ForestDrake_MeshWalkRoot"
	_rig_root.position = Vector2(640.0, 486.0)
	_rig_root.scale = Vector2.ONE * (TARGET_VISIBLE_HEIGHT / maxf(float(_bounds.size.y), 1.0))
	_rig_root.z_index = 2
	add_child(_rig_root)

	_build_contact_shadow()
	_build_skeleton_and_mesh(character_image)
	_build_hud()

	print("[DrakeMeshWalk] Source: %s, %dx%d, alpha_mode=%d." % [
		DRAKE_TEXTURE_PATH,
		character_image.get_width(),
		character_image.get_height(),
		character_image.detect_alpha()
	])
	print("[DrakeMeshWalk] Visible bounds: %s | ground anchor: %s | display scale: %.4f." % [
		str(_bounds), str(_ground_anchor), _rig_root.scale.x
	])
	print("[DrakeMeshWalk] Full-image mesh: %dx%d grid. No artwork was cut into separate pieces.")
	_apply_walk_pose()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, VIEWPORT_SIZE), Color("#1e2b26"), true)
	draw_rect(Rect2(Vector2(20.0, 20.0), VIEWPORT_SIZE - Vector2(40.0, 40.0)), Color("#34483a"), false, 2.0)
	draw_line(Vector2(150.0, 486.0), Vector2(1130.0, 486.0), Color(0.58, 0.66, 0.52, 0.34), 1.0)
	draw_string(ThemeDB.fallback_font, Vector2(36.0, 112.0), "FRONT 3/4 WALKING — FULL IMAGE MESH TEST", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 17, Color("#d6dfcf"))


func _process(delta: float) -> void:
	if not _playing:
		return
	_walk_phase = fposmod(_walk_phase + delta * _walk_speed / WALK_CYCLE_SECONDS, 1.0)
	_apply_walk_pose()


func _create_bone(bone_name: String, source_pivot: Vector2, parent: Node, length: float) -> Bone2D:
	var bone := Bone2D.new()
	bone.name = bone_name
	bone.position = source_pivot - _ground_anchor
	bone.set_autocalculate_length_and_angle(false)
	bone.length = length
	parent.add_child(bone)
	_bones[bone_name] = bone
	_rest_positions[bone_name] = bone.position
	return bone


func _build_skeleton_and_mesh(character_image: Image) -> void:
	_skeleton = Skeleton2D.new()
	_skeleton.name = "Skeleton2D"
	_rig_root.add_child(_skeleton)

	var root_bone := Bone2D.new()
	root_bone.name = "RootAnchor"
	root_bone.position = Vector2.ZERO
	root_bone.set_autocalculate_length_and_angle(false)
	root_bone.length = 90.0
	_skeleton.add_child(root_bone)
	_bones["RootAnchor"] = root_bone
	_rest_positions["RootAnchor"] = Vector2.ZERO

	_body_motion_bone = _create_bone("BodyMotionBone", _ground_anchor, root_bone, 1.0)
	_torso_bone = _create_bone("TorsoBone", Vector2(505.0, 605.0), _body_motion_bone, 110.0)
	_head_bone = _create_bone("HeadNeckBone", Vector2(395.0, 505.0), _body_motion_bone, 86.0)
	_wing_bone = _create_bone("WingBone", Vector2(605.0, 485.0), _body_motion_bone, 72.0)
	_tail_bone = _create_bone("TailBone", Vector2(745.0, 625.0), _body_motion_bone, 95.0)

	# The four limb pivots stay under the fixed ground root. This lets the feet
	# move independently while the chest has a small vertical weight response.
	_create_bone("FrontLegNearBone", Vector2(435.0, 625.0), root_bone, 145.0)
	_create_bone("FrontLegFarBone", Vector2(315.0, 610.0), root_bone, 135.0)
	_create_bone("RearLegNearBone", Vector2(655.0, 625.0), root_bone, 130.0)
	_create_bone("RearLegFarBone", Vector2(555.0, 655.0), root_bone, 120.0)

	# Cache the untouched transforms as the mesh rest pose.
	for bone_name in BONE_NAMES:
		var bone: Bone2D = _bones[bone_name]
		bone.rest = bone.transform

	var points := PackedVector2Array()
	var uvs := PackedVector2Array()
	var polygons: Array = []
	var weight_arrays: Array[PackedFloat32Array] = []
	for _bone_index in range(BONE_NAMES.size()):
		weight_arrays.append(PackedFloat32Array())

	for row in range(GRID_ROWS):
		for column in range(GRID_COLUMNS):
			var source_point := Vector2(
				float(column) * float(character_image.get_width()) / float(GRID_COLUMNS - 1),
				float(row) * float(character_image.get_height()) / float(GRID_ROWS - 1)
			)
			points.append(source_point - _ground_anchor)
			uvs.append(source_point)

			var front_near := _elliptical_influence(source_point, REGION_CENTERS["front_near"], REGION_RADII["front_near"], 0.98, 0.52)
			var front_far := _elliptical_influence(source_point, REGION_CENTERS["front_far"], REGION_RADII["front_far"], 0.98, 0.52)
			var rear_near := _elliptical_influence(source_point, REGION_CENTERS["rear_near"], REGION_RADII["rear_near"], 0.98, 0.52)
			var rear_far := _elliptical_influence(source_point, REGION_CENTERS["rear_far"], REGION_RADII["rear_far"], 0.98, 0.52)
			var strongest_limb := maxf(maxf(front_near, front_far), maxf(rear_near, rear_far))

			var torso := _elliptical_influence(source_point, REGION_CENTERS["torso"], REGION_RADII["torso"], 0.82, 0.24) * (1.0 - strongest_limb * 0.90)
			var head := _elliptical_influence(source_point, REGION_CENTERS["head"], REGION_RADII["head"], 0.94, 0.68)
			var wing := _elliptical_influence(source_point, REGION_CENTERS["wing"], REGION_RADII["wing"], 0.90, 0.28)
			var tail := _elliptical_influence(source_point, REGION_CENTERS["tail"], REGION_RADII["tail"], 0.92, 0.40)

			var raw_weights := PackedFloat32Array([
				torso, head, wing, tail,
				front_near, front_far, rear_near, rear_far
			])
			var total_weight := 0.0
			for weight in raw_weights:
				total_weight += weight
			if total_weight > MAX_BONE_WEIGHT:
				var normalization := MAX_BONE_WEIGHT / total_weight
				for index in range(raw_weights.size()):
					raw_weights[index] *= normalization
				total_weight = MAX_BONE_WEIGHT

			weight_arrays[0].append(1.0 - total_weight)
			for index in range(raw_weights.size()):
				weight_arrays[index + 1].append(raw_weights[index])

	for row in range(GRID_ROWS - 1):
		for column in range(GRID_COLUMNS - 1):
			var top_left := row * GRID_COLUMNS + column
			var top_right := top_left + 1
			var bottom_left := top_left + GRID_COLUMNS
			var bottom_right := bottom_left + 1
			polygons.append(PackedInt32Array([
				top_left, top_right, bottom_right, bottom_left
			]))

	_mesh = Polygon2D.new()
	_mesh.name = "FullImageWeightedMesh"
	_mesh.texture = ImageTexture.create_from_image(character_image)
	_mesh.polygon = points
	_mesh.uv = uvs
	_mesh.polygons = polygons
	_mesh.color = Color.WHITE
	_mesh.antialiased = false
	_mesh.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_rig_root.add_child(_mesh)

	_mesh.skeleton = _mesh.get_path_to(_skeleton)
	for index in range(BONE_NAMES.size()):
		var bone: Bone2D = _bones[BONE_NAMES[index]]
		_mesh.add_bone(_mesh.get_path_to(bone), weight_arrays[index])


func _elliptical_influence(point: Vector2, center: Vector2, radii: Vector2, maximum_weight: float, full_weight_core: float) -> float:
	var normalized_distance := Vector2(
		(point.x - center.x) / radii.x,
		(point.y - center.y) / radii.y
	).length()
	var transition := clampf((normalized_distance - full_weight_core) / (1.0 - full_weight_core), 0.0, 1.0)
	var smooth_transition := transition * transition * (3.0 - 2.0 * transition)
	return maximum_weight * (1.0 - smooth_transition)


func _apply_walk_pose() -> void:
	var cycle_angle := TAU * _walk_phase
	var bob := (0.5 - cos(cycle_angle * 2.0) * 0.5) * 3.2
	_body_motion_bone.position = Vector2(0.0, -bob)
	_body_motion_bone.rotation = sin(cycle_angle) * 0.008
	_torso_bone.scale = Vector2(1.0 + 0.002 * cos(cycle_angle * 2.0), 1.0 - 0.004 * cos(cycle_angle * 2.0))
	_head_bone.rotation = -sin(cycle_angle + 0.20) * 0.022
	_wing_bone.rotation = sin(cycle_angle + 0.50) * 0.028
	_tail_bone.rotation = sin(cycle_angle + 0.85) * 0.055

	# Four-beat walk: each foot has its own phase; diagonally opposite feet are
	# deliberately offset to avoid a synchronized two-leg "trot" appearance.
	_apply_leg_pose("FrontLegNearBone", _walk_phase + 0.00, 0.26, 18.0, 20.0)
	_apply_leg_pose("RearLegFarBone", _walk_phase + 0.25, 0.22, 15.0, 16.0)
	_apply_leg_pose("FrontLegFarBone", _walk_phase + 0.50, 0.23, 16.0, 17.0)
	_apply_leg_pose("RearLegNearBone", _walk_phase + 0.75, 0.21, 14.0, 15.0)

	if _status_label != null:
		_update_hud()


func _apply_leg_pose(bone_name: String, phase: float, rotation_amplitude: float, stride_px: float, lift_px: float) -> void:
	var bone: Bone2D = _bones[bone_name]
	var local_phase := fposmod(phase, 1.0)
	var wave := sin(TAU * local_phase)
	var stride_wave := cos(TAU * local_phase)
	var lift := maxf(0.0, wave) * lift_px
	var rest_position: Vector2 = _rest_positions[bone_name]
	bone.position = rest_position + Vector2(stride_wave * stride_px, -lift)
	bone.rotation = wave * rotation_amplitude


func _build_contact_shadow() -> void:
	var shadow := Sprite2D.new()
	shadow.name = "SeparateGroundContactShadow"
	shadow.texture = _create_shadow_texture()
	shadow.centered = true
	shadow.position = Vector2(-26.0, -54.0)
	shadow.scale = Vector2(3.7, 1.05)
	shadow.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	shadow.z_index = -1
	_rig_root.add_child(shadow)


func _create_shadow_texture() -> Texture2D:
	var image := Image.create(128, 64, false, Image.FORMAT_RGBA8)
	var center := Vector2(63.5, 31.5)
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var dx := (float(x) - center.x) / 60.0
			var dy := (float(y) - center.y) / 27.0
			var distance_squared := dx * dx + dy * dy
			var falloff := clampf(1.0 - distance_squared, 0.0, 1.0)
			var alpha := clampf(0.34 * pow(falloff, 1.25) + 0.16 * exp(-distance_squared * 12.0), 0.0, 0.48)
			image.set_pixel(x, y, Color(0.025, 0.038, 0.028, alpha))
	return ImageTexture.create_from_image(image)


func _get_visible_bounds(image: Image) -> Rect2i:
	var width := image.get_width()
	var height := image.get_height()
	var min_x := width
	var min_y := height
	var max_x := -1
	var max_y := -1

	for y in range(height):
		var count := 0
		for x in range(width):
			if image.get_pixel(x, y).a > 0.08:
				count += 1
		if count >= 3:
			min_y = mini(min_y, y)
			max_y = maxi(max_y, y)

	for x in range(width):
		var count := 0
		for y in range(height):
			if image.get_pixel(x, y).a > 0.08:
				count += 1
		if count >= 3:
			min_x = mini(min_x, x)
			max_x = maxi(max_x, x)

	if max_x < min_x or max_y < min_y:
		return Rect2i(Vector2i.ZERO, Vector2i.ZERO)
	return Rect2i(Vector2i(min_x, min_y), Vector2i(max_x - min_x + 1, max_y - min_y + 1))


func _build_background() -> void:
	queue_redraw()


func _build_hud() -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "WalkProofHUD"
	canvas.layer = 10
	add_child(canvas)

	var title := Label.new()
	title.position = Vector2(36.0, 28.0)
	title.text = "POCKET WORLDS  /  FOREST DRAKE  /  FRONT 3/4 MESH WALK"
	title.add_theme_font_size_override("font_size", 21)
	title.add_theme_color_override("font_color", Color("#f3eddc"))
	canvas.add_child(title)

	_status_label = Label.new()
	_status_label.position = Vector2(36.0, 58.0)
	_status_label.add_theme_font_size_override("font_size", 16)
	_status_label.add_theme_color_override("font_color", Color("#d5dfcf"))
	canvas.add_child(_status_label)

	var controls := Label.new()
	controls.position = Vector2(36.0, 665.0)
	controls.text = "SPACE Play / Pause  |  N Step 1/8 cycle  |  UP/DOWN Speed  |  R Reset"
	controls.add_theme_font_size_override("font_size", 15)
	controls.add_theme_color_override("font_color", Color("#f3eddc"))
	canvas.add_child(controls)
	_update_hud()


func _build_error_label(message: String) -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)
	var label := Label.new()
	label.position = Vector2(40.0, 60.0)
	label.text = message
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", Color("#ffb4a8"))
	canvas.add_child(label)


func _update_hud() -> void:
	if _status_label == null:
		return
	var state := "PLAYING" if _playing else "PAUSED"
	_status_label.text = "4-BEAT WALK  |  %s  |  SPEED %.2fx  |  PHASE %03d%%" % [
		state, _walk_speed, roundi(_walk_phase * 100.0)
	]


func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return

	match key_event.keycode:
		KEY_SPACE:
			_playing = not _playing
			_update_hud()
		KEY_N:
			_playing = false
			_walk_phase = fposmod(_walk_phase + 0.125, 1.0)
			_apply_walk_pose()
			_update_hud()
		KEY_UP:
			_walk_speed = minf(_walk_speed + 0.25, 2.5)
			_update_hud()
		KEY_DOWN:
			_walk_speed = maxf(_walk_speed - 0.25, 0.5)
			_update_hud()
		KEY_R:
			_walk_phase = 0.0
			_playing = true
			_walk_speed = STARTING_SPEED
			_apply_walk_pose()
			_update_hud()
