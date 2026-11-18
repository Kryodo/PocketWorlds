extends "res://scenes/tests/animation_proof_review.gd"

# Isolated pickup/drag/drop interaction built on the approved Forest Drake rig.
# The inherited animation proof remains unchanged; this scene only wraps the rig
# in a ground-plane anchor and offsets the visual while it is being carried.

const HOVER_HEIGHT := 34.0
const HOVER_BOB_AMOUNT := 2.0
const HOVER_BOB_SPEED := 2.1
const DRAG_FOLLOW_RESPONSE := 18.0
const PICKUP_DURATION := 0.22
const SETTLE_DURATION := 0.24
# The rig is scaled down from source-image pixels, so this hit rect uses rig-local source coordinates.
const HIT_RECT := Rect2(Vector2(-430.0, -760.0), Vector2(860.0, 840.0))
const SHADOW_LIFT_SCALE := 1.34
const SHADOW_LIFT_ALPHA := 0.72

var _drake_world_anchor: Node2D
var _is_dragging := false
var _target_anchor_global := Vector2.ZERO
var _grab_offset := Vector2.ZERO
var _lift_amount := 0.0
var _hover_clock := 0.0
var _lift_tween: Tween
var _shadow_base_scale := Vector2.ONE
var _shadow_base_modulate := Color.WHITE
var _interaction_state_text := "READY • press and drag the Forest Drake"


func _ready() -> void:
	super._ready()
	_wrap_drake_in_ground_anchor()
	_configure_interaction_hud()
	_update_status()


func _wrap_drake_in_ground_anchor() -> void:
	if _rigged_drake == null or _drake_shadow == null or _sorted_world == null:
		push_error("Forest Drake interaction could not find the rig or its shadow.")
		return

	var original_world_position := _rigged_drake.global_position
	var original_parent := _rigged_drake.get_parent()
	if original_parent == null:
		push_error("Forest Drake rig has no world parent.")
		return

	# The wrapper remains on the ground plane and participates in Y sorting.
	# Only the child visual rises, so the shadow can stay on the ground beneath it.
	original_parent.remove_child(_rigged_drake)

	_drake_world_anchor = Node2D.new()
	_drake_world_anchor.name = "ForestDrake_GroundAnchor"
	_drake_world_anchor.position = original_world_position
	_drake_world_anchor.z_index = 0
	original_parent.add_child(_drake_world_anchor)

	_drake_world_anchor.add_child(_rigged_drake)
	_rigged_drake.position = Vector2.ZERO

	_shadow_base_scale = _drake_shadow.scale
	_shadow_base_modulate = _drake_shadow.modulate
	_drake_shadow.global_position = original_world_position + Vector2(0.0, -2.0)
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
			label.text = "POCKET WORLDS  |  FOREST DRAKE PICKUP V1"
		elif label.position.y > 650.0:
			label.text = "MOUSE / TOUCH: PRESS + DRAG TO PICK UP  •  MOVE  •  RELEASE TO SET DOWN"


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
		_hover_clock += delta
		var follow_weight := 1.0 - exp(-DRAG_FOLLOW_RESPONSE * delta)
		_drake_world_anchor.global_position = _drake_world_anchor.global_position.lerp(
			_target_anchor_global,
			follow_weight
		)

	var bob_offset := 0.0
	if _is_dragging:
		bob_offset = sin(_hover_clock * HOVER_BOB_SPEED) * HOVER_BOB_AMOUNT

	_rigged_drake.position = Vector2(0.0, -_lift_amount - bob_offset)
	_update_shadow_for_lift()


func _begin_drag(screen_position: Vector2) -> bool:
	if _is_dragging or _drake_world_anchor == null or _rigged_drake == null:
		return false
	if not _rigged_drake.visible:
		return false

	var world_position := _screen_to_world(screen_position)
	var local_position := _rigged_drake.to_local(world_position)
	if not HIT_RECT.has_point(local_position):
		return false

	_is_dragging = true
	_hover_clock = 0.0
	_grab_offset = _drake_world_anchor.global_position - world_position
	_target_anchor_global = _drake_world_anchor.global_position

	_animate_lift(HOVER_HEIGHT, PICKUP_DURATION, Tween.EASE_OUT)
	_interaction_state_text = "PICKED UP • move the Forest Drake, then release to place it"
	_update_status()
	return true


func _update_drag_target(screen_position: Vector2) -> void:
	if not _is_dragging:
		return
	var world_position := _screen_to_world(screen_position)
	_target_anchor_global = world_position + _grab_offset


func _end_drag(screen_position: Vector2) -> void:
	if not _is_dragging or _drake_world_anchor == null:
		return

	_update_drag_target(screen_position)
	# Commit the final pointer position before settling so the creature lands
	# exactly where the player released it, without leaving a smoothing tail.
	_drake_world_anchor.global_position = _target_anchor_global
	_is_dragging = false

	_animate_lift(0.0, SETTLE_DURATION, Tween.EASE_IN_OUT)
	_interaction_state_text = "SETTLING • the drake is landing"
	_update_status()


func _animate_lift(target_height: float, duration: float, ease_type: Tween.EaseType) -> void:
	if _lift_tween != null and _lift_tween.is_running():
		_lift_tween.kill()

	_lift_tween = create_tween()
	_lift_tween.set_trans(Tween.TRANS_SINE)
	_lift_tween.set_ease(ease_type)
	_lift_tween.tween_property(self, "_lift_amount", target_height, duration)
	if is_zero_approx(target_height):
		_lift_tween.tween_callback(_on_settled)


func _on_settled() -> void:
	if _is_dragging:
		return
	_lift_amount = 0.0
	_rigged_drake.position = Vector2.ZERO
	_interaction_state_text = "LANDED • press and drag the Forest Drake again"
	_update_status()


func _update_shadow_for_lift() -> void:
	if _drake_shadow == null or _drake_world_anchor == null:
		return

	var lift_ratio := clampf(_lift_amount / HOVER_HEIGHT, 0.0, 1.0)
	_drake_shadow.global_position = _drake_world_anchor.global_position + Vector2(0.0, -2.0)
	_drake_shadow.scale = _shadow_base_scale.lerp(
		_shadow_base_scale * SHADOW_LIFT_SCALE,
		lift_ratio
	)

	var shadow_modulate := _shadow_base_modulate
	shadow_modulate.a *= lerpf(1.0, SHADOW_LIFT_ALPHA, lift_ratio)
	_drake_shadow.modulate = shadow_modulate


func _screen_to_world(screen_position: Vector2) -> Vector2:
	var canvas_transform := get_viewport().get_canvas_transform()
	return canvas_transform.affine_inverse() * screen_position


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key_event := event as InputEventKey
		if key_event.pressed and not key_event.echo and key_event.keycode == KEY_SPACE:
			# Keep the test locked to the rig; Space must not switch to the old
			# static/sprite-sheet comparison while the interaction is being reviewed.
			return
	super._unhandled_key_input(event)
