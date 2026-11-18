extends "res://scenes/tests/animation_proof_review.gd"

# Pickup/drag/drop proof using the refined walking-proof rig.
# Existing standing, lying and walking animation work remains inherited unchanged.
# Carried-only reactions and hover idles are added as separate Godot AnimationPlayers.

const HOVER_HEIGHT := 36.0
const HOVER_BOB_AMOUNT := 2.0
const HOVER_BOB_SPEED := 2.15
const DRAG_FOLLOW_RESPONSE := 18.0
const PICKUP_LIFT_DURATION := 0.28
const PICKUP_POSE_DURATION := 0.52
const SETTLE_DURATION := 0.30
# The rig is scaled down from source-image pixels, so this hit rect uses rig-local source coordinates.
const HIT_RECT := Rect2(Vector2(-430.0, -760.0), Vector2(860.0, 840.0))
const SHADOW_LIFT_SCALE := 1.30
const SHADOW_LIFT_ALPHA := 0.70

const BODY_POSITION_PATH := "Skeleton2D/RootAnchor/BodyMotionBone:position"
const BODY_ROTATION_PATH := "Skeleton2D/RootAnchor/BodyMotionBone:rotation"
const TORSO_SCALE_PATH := "Skeleton2D/RootAnchor/BodyMotionBone/TorsoBone:scale"
const HEAD_POSITION_PATH := "Skeleton2D/RootAnchor/BodyMotionBone/HeadNeckBone:position"
const HEAD_ROTATION_PATH := "Skeleton2D/RootAnchor/BodyMotionBone/HeadNeckBone:rotation"
const WING_ROTATION_PATH := "Skeleton2D/RootAnchor/BodyMotionBone/WingBone:rotation"
const TAIL_ROTATION_PATH := "Skeleton2D/RootAnchor/BodyMotionBone/TailBone:rotation"
const FRONT_NEAR_POSITION_PATH := "Skeleton2D/RootAnchor/FrontLegNearBone:position"
const FRONT_NEAR_ROTATION_PATH := "Skeleton2D/RootAnchor/FrontLegNearBone:rotation"
const FRONT_FAR_POSITION_PATH := "Skeleton2D/RootAnchor/FrontLegFarBone:position"
const FRONT_FAR_ROTATION_PATH := "Skeleton2D/RootAnchor/FrontLegFarBone:rotation"

var _drake_world_anchor: Node2D
var _is_dragging := false
var _is_hovering := false
var _target_anchor_global := Vector2.ZERO
var _grab_offset := Vector2.ZERO
var _lift_amount := 0.0
var _hover_clock := 0.0
var _lift_tween: Tween
var _pose_tween: Tween
var _hover_animation_players: Array[AnimationPlayer] = []
var _shadow_base_scale := Vector2.ONE
var _shadow_base_modulate := Color.WHITE
var _interaction_state_text := "READY • press and drag the Forest Drake"


func _ready() -> void:
	super._ready()
	_wrap_drake_in_ground_anchor()
	_build_carried_hover_animations()
	_configure_interaction_hud()
	_update_status()


func _wrap_drake_in_ground_anchor() -> void:
	if _rigged_drake == null or _drake_shadow == null or _sorted_world == null:
		push_error("Forest Drake interaction could not find the rig or its refined contact shadow.")
		return

	var original_world_position := _rigged_drake.global_position
	var original_parent := _rigged_drake.get_parent()
	if original_parent == null:
		push_error("Forest Drake rig has no world parent.")
		return

	# In the walking-proof rig the contact shadow is a child of the rig.
	# Move it to the ground-anchor wrapper and compensate for the rig's scale,
	# so only the creature visual rises when carried.
	var rig_scale := _rigged_drake.scale
	var shadow_position_in_rig := _drake_shadow.position
	var shadow_scale_in_rig := _drake_shadow.scale
	_rigged_drake.remove_child(_drake_shadow)
	original_parent.remove_child(_rigged_drake)

	_drake_world_anchor = Node2D.new()
	_drake_world_anchor.name = "ForestDrake_GroundAnchor"
	original_parent.add_child(_drake_world_anchor)
	_drake_world_anchor.global_position = original_world_position
	_drake_world_anchor.z_index = 0

	_drake_world_anchor.add_child(_drake_shadow)
	_drake_shadow.position = shadow_position_in_rig * rig_scale
	_drake_shadow.scale = shadow_scale_in_rig * rig_scale
	_drake_shadow.z_index = 1

	_drake_world_anchor.add_child(_rigged_drake)
	_rigged_drake.position = Vector2.ZERO
	_rigged_drake.z_index = 2

	_shadow_base_scale = _drake_shadow.scale
	_shadow_base_modulate = _drake_shadow.modulate
	_target_anchor_global = original_world_position


func _configure_interaction_hud() -> void:
	var hud := get_node_or_null("ReviewHUD") as CanvasLayer
	if hud == null:
		return

	for child in hud.get_children():
		if not (child is Label):
			continue
		var label := child as Label
		if label.position.y < 30.0:
			label.text = "POCKET WORLDS  |  FOREST DRAKE PICKUP + FLOAT IDLE V2"
		elif label.position.y > 650.0:
			label.text = "MOUSE / TOUCH: PRESS + DRAG  •  WATCH THE DRAKE REACT  •  RELEASE TO SET DOWN"


func _update_status() -> void:
	if _status_label == null:
		return
	_status_label.text = _interaction_state_text


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			if _begin_drag(touch.position):
				get_viewport().set_input_as_handled()
		elif _is_dragging:
			_end_drag(touch.position)
			get_viewport().set_input_as_handled()
		return

	if event is InputEventScreenDrag:
		if _is_dragging:
			_update_drag_target((event as InputEventScreenDrag).position)
			get_viewport().set_input_as_handled()
		return

	if event is InputEventMouseButton:
		var mouse_button := event as InputEventMouseButton
		if mouse_button.button_index != MOUSE_BUTTON_LEFT:
			return
		if mouse_button.pressed:
			if _begin_drag(mouse_button.position):
				get_viewport().set_input_as_handled()
		elif _is_dragging:
			_end_drag(mouse_button.position)
			get_viewport().set_input_as_handled()
		return

	if event is InputEventMouseMotion and _is_dragging:
		_update_drag_target((event as InputEventMouseMotion).position)
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if _drake_world_anchor == null or _rigged_drake == null:
		return

	if _is_dragging:
		var follow_weight := 1.0 - exp(-DRAG_FOLLOW_RESPONSE * delta)
		_drake_world_anchor.global_position = _drake_world_anchor.global_position.lerp(
			_target_anchor_global,
			follow_weight
		)

	var bob_offset := 0.0
	if _is_dragging and _is_hovering:
		_hover_clock += delta
		# Two unsynchronised waves keep the overall lift alive without looking mechanical.
		bob_offset = sin(_hover_clock * HOVER_BOB_SPEED) * HOVER_BOB_AMOUNT
		bob_offset += sin(_hover_clock * 3.65 + 0.9) * 0.55

	_rigged_drake.position = Vector2(0.0, -_lift_amount - bob_offset)
	_update_shadow_for_lift()


func _begin_drag(screen_position: Vector2) -> bool:
	if _is_dragging or _drake_world_anchor == null or _rigged_drake == null:
		return false
	if not _rigged_drake.visible or _display_mode != &"rig":
		return false
	# The carried pose is built from the standing rig. Do not pick up during a
	# walk or lie transition; this proof intentionally keeps those states separate.
	if _walk_state != &"idle" or _posture_state != &"standing":
		return false

	var world_position := _screen_to_world(screen_position)
	var local_position := _rigged_drake.to_local(world_position)
	if not HIT_RECT.has_point(local_position):
		return false

	_is_dragging = true
	_is_hovering = false
	_hover_clock = 0.0

	# The ground anchor follows the pointer offset; the visual rises above it.
	# This keeps a visible gap between the carried creature and its ground shadow.
	_grab_offset = _drake_world_anchor.global_position - world_position
	_target_anchor_global = _drake_world_anchor.global_position

	_animate_lift(HOVER_HEIGHT, PICKUP_LIFT_DURATION, Tween.TRANS_BACK, Tween.EASE_OUT)
	_start_pickup_pose_reaction()
	_interaction_state_text = "LIFTING • the drake is tucking its paws"
	_update_status()
	return true


func _start_pickup_pose_reaction() -> void:
	_pause_grounded_animation_layers()
	_animate_rig_pose(
		_get_carried_pose_values(),
		PICKUP_POSE_DURATION,
		Tween.TRANS_BACK,
		Tween.EASE_OUT,
		_on_pickup_pose_reaction_finished
	)


func _pause_grounded_animation_layers() -> void:
	for player in _rig_animation_players:
		player.pause()
	if _lying_idle_player != null:
		_lying_idle_player.stop(true)
	if _walk_animation_player != null:
		_walk_animation_player.stop(true)
	if _posture_animation_player != null:
		_posture_animation_player.stop(true)


func _get_carried_pose_values() -> Dictionary:
	var values := _get_standing_posture_values()
	values[BODY_POSITION_PATH] = values[BODY_POSITION_PATH] + Vector2(0.0, -18.0)
	values[BODY_ROTATION_PATH] = -0.035
	values[TORSO_SCALE_PATH] = Vector2(1.045, 1.055)
	values[HEAD_POSITION_PATH] = values[HEAD_POSITION_PATH] + Vector2(-5.0, -8.0)
	values[HEAD_ROTATION_PATH] = -0.12
	values[WING_ROTATION_PATH] = -0.18
	values[TAIL_ROTATION_PATH] = 0.10
	values[FRONT_NEAR_POSITION_PATH] = values[FRONT_NEAR_POSITION_PATH] + Vector2(-4.0, -19.0)
	values[FRONT_NEAR_ROTATION_PATH] = -0.17
	values[FRONT_FAR_POSITION_PATH] = values[FRONT_FAR_POSITION_PATH] + Vector2(5.0, -17.0)
	values[FRONT_FAR_ROTATION_PATH] = 0.15
	return values


func _on_pickup_pose_reaction_finished() -> void:
	if not _is_dragging:
		return
	_start_hover_idle()
	_interaction_state_text = "FLOATING • the drake is looking around"
	_update_status()


func _start_hover_idle() -> void:
	_is_hovering = true
	_hover_clock = 0.0
	for player in _hover_animation_players:
		# All hover layers start on their carried-pose key. Their different loop
		# lengths and internal timing create the asynchronous motion naturally.
		player.play(&"hover")


func _build_carried_hover_animations() -> void:
	var carried := _get_carried_pose_values()

	# Body: uneven floating rhythm plus a restrained inhale/exhale.
	var body := Animation.new()
	body.resource_name = "carried_body_float"
	body.length = 3.2
	body.loop_mode = Animation.LOOP_LINEAR
	var body_base: Vector2 = carried[BODY_POSITION_PATH]
	var body_rotation: float = carried[BODY_ROTATION_PATH]
	_add_bone_value_track(body, BODY_POSITION_PATH,
		PackedFloat64Array([0.0, 0.38, 0.86, 1.35, 1.88, 2.48, 3.2]),
		[body_base, body_base + Vector2(0.0, -8.0), body_base + Vector2(0.0, -18.0), body_base + Vector2(0.0, -9.0), body_base + Vector2(0.0, -3.0), body_base + Vector2(0.0, -14.0), body_base])
	_add_bone_value_track(body, BODY_ROTATION_PATH,
		PackedFloat64Array([0.0, 0.55, 1.05, 1.72, 2.35, 3.2]),
		[body_rotation, body_rotation - 0.018, body_rotation + 0.022, body_rotation + 0.008, body_rotation - 0.014, body_rotation])
	_add_bone_value_track(body, TORSO_SCALE_PATH,
		PackedFloat64Array([0.0, 0.82, 1.62, 2.42, 3.2]),
		[carried[TORSO_SCALE_PATH], Vector2(1.025, 1.035), Vector2(1.06, 1.075), Vector2(1.03, 1.04), carried[TORSO_SCALE_PATH]])
	_create_hover_animation_player("CarriedBodyFloatPlayer", body)

	# Head: several brief, curious glances separated by small rests.
	var head := Animation.new()
	head.resource_name = "carried_head_glances"
	head.length = 5.8
	head.loop_mode = Animation.LOOP_LINEAR
	var head_base: Vector2 = carried[HEAD_POSITION_PATH]
	var head_rotation: float = carried[HEAD_ROTATION_PATH]
	_add_bone_value_track(head, HEAD_POSITION_PATH,
		PackedFloat64Array([0.0, 0.52, 0.88, 1.18, 1.72, 2.42, 2.88, 3.22, 4.15, 4.62, 5.8]),
		[head_base, head_base + Vector2(-2.0, -2.0), head_base + Vector2(-9.0, -10.0), head_base + Vector2(-5.0, -5.0), head_base, head_base + Vector2(8.0, -5.0), head_base + Vector2(11.0, -8.0), head_base + Vector2(3.0, -2.0), head_base + Vector2(-5.0, -5.0), head_base, head_base])
	_add_bone_value_track(head, HEAD_ROTATION_PATH,
		PackedFloat64Array([0.0, 0.52, 0.88, 1.18, 1.72, 2.42, 2.88, 3.22, 4.15, 4.62, 5.8]),
		[head_rotation, head_rotation + 0.015, head_rotation - 0.10, head_rotation - 0.04, head_rotation, head_rotation + 0.08, head_rotation + 0.12, head_rotation + 0.025, head_rotation - 0.065, head_rotation, head_rotation])
	_create_hover_animation_player("CarriedHeadLookPlayer", head)

	# Wing: occasional quick little corrections, never a constant flap.
	var wing := Animation.new()
	wing.resource_name = "carried_wing_flicks"
	wing.length = 4.6
	wing.loop_mode = Animation.LOOP_LINEAR
	var wing_base: float = carried[WING_ROTATION_PATH]
	_add_bone_value_track(wing, WING_ROTATION_PATH,
		PackedFloat64Array([0.0, 1.10, 1.24, 1.42, 1.68, 2.76, 2.90, 3.08, 4.0, 4.6]),
		[wing_base, wing_base, wing_base - 0.15, wing_base + 0.055, wing_base, wing_base, wing_base - 0.10, wing_base + 0.025, wing_base, wing_base])
	_create_hover_animation_player("CarriedWingFlickPlayer", wing)

	# Tail: slow counterbalance with one sharper, delayed twitch.
	var tail := Animation.new()
	tail.resource_name = "carried_tail_balance"
	tail.length = 6.4
	tail.loop_mode = Animation.LOOP_LINEAR
	var tail_base: float = carried[TAIL_ROTATION_PATH]
	_add_bone_value_track(tail, TAIL_ROTATION_PATH,
		PackedFloat64Array([0.0, 0.85, 1.75, 2.55, 3.35, 3.78, 4.55, 5.48, 6.4]),
		[tail_base, tail_base + 0.08, tail_base - 0.035, tail_base - 0.16, tail_base - 0.22, tail_base - 0.015, tail_base + 0.13, tail_base + 0.055, tail_base])
	_create_hover_animation_player("CarriedTailBalancePlayer", tail)

	# Forepaws stay visibly tucked, with small asynchronous kick/relax motions.
	var legs := Animation.new()
	legs.resource_name = "carried_forepaw_tucks"
	legs.length = 3.8
	legs.loop_mode = Animation.LOOP_LINEAR
	var near_position: Vector2 = carried[FRONT_NEAR_POSITION_PATH]
	var near_rotation: float = carried[FRONT_NEAR_ROTATION_PATH]
	var far_position: Vector2 = carried[FRONT_FAR_POSITION_PATH]
	var far_rotation: float = carried[FRONT_FAR_ROTATION_PATH]
	_add_bone_value_track(legs, FRONT_NEAR_POSITION_PATH,
		PackedFloat64Array([0.0, 0.58, 0.92, 1.32, 1.85, 2.40, 2.78, 3.20, 3.8]),
		[near_position, near_position + Vector2(-2.0, -3.0), near_position + Vector2(-7.0, -9.0), near_position + Vector2(-3.0, -2.0), near_position, near_position + Vector2(-4.0, -5.0), near_position + Vector2(-2.0, -1.0), near_position, near_position])
	_add_bone_value_track(legs, FRONT_NEAR_ROTATION_PATH,
		PackedFloat64Array([0.0, 0.58, 0.92, 1.32, 1.85, 2.40, 2.78, 3.20, 3.8]),
		[near_rotation, near_rotation - 0.035, near_rotation - 0.12, near_rotation - 0.04, near_rotation, near_rotation - 0.06, near_rotation - 0.025, near_rotation, near_rotation])
	_add_bone_value_track(legs, FRONT_FAR_POSITION_PATH,
		PackedFloat64Array([0.0, 0.72, 1.05, 1.52, 2.02, 2.56, 2.94, 3.42, 3.8]),
		[far_position, far_position + Vector2(2.0, -2.0), far_position + Vector2(6.0, -7.0), far_position + Vector2(2.0, -3.0), far_position, far_position + Vector2(5.0, -4.0), far_position + Vector2(1.0, -1.0), far_position, far_position])
	_add_bone_value_track(legs, FRONT_FAR_ROTATION_PATH,
		PackedFloat64Array([0.0, 0.72, 1.05, 1.52, 2.02, 2.56, 2.94, 3.42, 3.8]),
		[far_rotation, far_rotation + 0.025, far_rotation + 0.11, far_rotation + 0.03, far_rotation, far_rotation + 0.07, far_rotation + 0.015, far_rotation, far_rotation])
	_create_hover_animation_player("CarriedForepawFloatPlayer", legs)


func _create_hover_animation_player(player_name: String, animation: Animation) -> void:
	var player := AnimationPlayer.new()
	player.name = player_name
	player.root_node = NodePath("..")
	_rigged_drake.add_child(player)

	var library := AnimationLibrary.new()
	var error := library.add_animation(&"hover", animation)
	if error != OK:
		push_error("Could not register carried Forest Drake animation: %s" % player_name)
		return
	player.add_animation_library(&"", library)
	_hover_animation_players.append(player)


func _animate_rig_pose(
	target_values: Dictionary,
	duration: float,
	transition: Tween.TransitionType,
	ease: Tween.EaseType,
	on_finished: Callable
) -> void:
	if _pose_tween != null and _pose_tween.is_running():
		_pose_tween.kill()

	_pose_tween = create_tween()
	_pose_tween.set_parallel(true)
	_pose_tween.set_trans(transition)
	_pose_tween.set_ease(ease)

	for raw_path in target_values.keys():
		var property_path := String(raw_path)
		var separator := property_path.rfind(":")
		if separator < 0:
			continue
		var node_path := NodePath(property_path.substr(0, separator))
		var property_path_name := NodePath(property_path.substr(separator + 1))
		var target_node := _rigged_drake.get_node_or_null(node_path)
		if target_node == null:
			push_warning("Could not find rig node for carried pose path: %s" % property_path)
			continue
		_pose_tween.tween_property(target_node, property_path_name, target_values[raw_path], duration)

	if on_finished.is_valid():
		_pose_tween.finished.connect(on_finished)


func _end_drag(screen_position: Vector2) -> void:
	if not _is_dragging or _drake_world_anchor == null:
		return

	_update_drag_target(screen_position)
	# Commit the final pointer position before the landing animation starts.
	_drake_world_anchor.global_position = _target_anchor_global
	_is_dragging = false
	_is_hovering = false

	_pause_hover_animation_players()
	_animate_lift(0.0, SETTLE_DURATION, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
	_animate_rig_pose(
		_get_standing_posture_values(),
		SETTLE_DURATION,
		Tween.TRANS_SINE,
		Tween.EASE_IN_OUT,
		_on_landing_pose_finished
	)
	_interaction_state_text = "LANDING • the drake is unfolding its paws"
	_update_status()


func _pause_hover_animation_players() -> void:
	for player in _hover_animation_players:
		player.pause()


func _on_landing_pose_finished() -> void:
	if _is_dragging:
		return
	_lift_amount = 0.0
	_rigged_drake.position = Vector2.ZERO
	for player in _hover_animation_players:
		player.stop(true)
	for player in _rig_animation_players:
		player.play(&"idle")
	_update_shadow_for_lift()
	_interaction_state_text = "LANDED • press and drag the Forest Drake again"
	_update_status()


func _animate_lift(
	target_height: float,
	duration: float,
	transition: Tween.TransitionType,
	ease: Tween.EaseType
) -> void:
	if _lift_tween != null and _lift_tween.is_running():
		_lift_tween.kill()
	_lift_tween = create_tween()
	_lift_tween.set_trans(transition)
	_lift_tween.set_ease(ease)
	_lift_tween.tween_property(self, "_lift_amount", target_height, duration)


func _update_shadow_for_lift() -> void:
	if _drake_shadow == null:
		return
	var lift_ratio := clampf(_lift_amount / HOVER_HEIGHT, 0.0, 1.0)
	_drake_shadow.scale = _shadow_base_scale.lerp(
		_shadow_base_scale * SHADOW_LIFT_SCALE,
		lift_ratio
	)
	var shadow_modulate := _shadow_base_modulate
	shadow_modulate.a *= lerpf(1.0, SHADOW_LIFT_ALPHA, lift_ratio)
	_drake_shadow.modulate = shadow_modulate


func _update_drag_target(screen_position: Vector2) -> void:
	if not _is_dragging:
		return
	var world_position := _screen_to_world(screen_position)
	_target_anchor_global = world_position + _grab_offset


func _screen_to_world(screen_position: Vector2) -> Vector2:
	var canvas_transform := get_viewport().get_canvas_transform()
	return canvas_transform.affine_inverse() * screen_position


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key_event := event as InputEventKey
		if key_event.pressed and not key_event.echo:
			match key_event.keycode:
				KEY_SPACE, KEY_W, KEY_L:
					# Keep the interaction review locked to a standing rig.
					return
				KEY_R:
					if _is_dragging:
						return
	super._unhandled_key_input(event)
