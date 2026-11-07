class_name WorldCameraController
extends RefCounted

var camera: Camera2D
var viewport: Viewport
var min_zoom: float = 0.45
var max_zoom: float = 1.65

func configure(next_camera: Camera2D, next_viewport: Viewport, next_min_zoom: float = 0.45, next_max_zoom: float = 1.65) -> void:
	camera = next_camera
	viewport = next_viewport
	min_zoom = next_min_zoom
	max_zoom = next_max_zoom

func pan_by_screen_delta(screen_delta: Vector2) -> void:
	if camera == null:
		return
	camera.position -= screen_delta / maxf(camera.zoom.x, 0.001)

func zoom_at(screen_position: Vector2, factor: float) -> void:
	if camera == null or viewport == null:
		return
	var old_world_point := screen_to_world(screen_position)
	var next_zoom := clampf(camera.zoom.x * factor, min_zoom, max_zoom)
	if is_equal_approx(next_zoom, camera.zoom.x):
		return
	camera.zoom = Vector2.ONE * next_zoom
	camera.force_update_scroll()
	var new_world_point := screen_to_world(screen_position)
	camera.position += old_world_point - new_world_point
	camera.force_update_scroll()

func screen_to_world(screen_position: Vector2) -> Vector2:
	if camera == null or viewport == null:
		return screen_position
	camera.force_update_scroll()
	return viewport.get_canvas_transform().affine_inverse() * screen_position

func set_world_limits(world_bounds: Rect2, margin: float = 80.0) -> void:
	if camera == null:
		return
	camera.limit_enabled = true
	camera.limit_left = floori(world_bounds.position.x - margin)
	camera.limit_top = floori(world_bounds.position.y - margin)
	camera.limit_right = ceili(world_bounds.end.x + margin)
	camera.limit_bottom = ceili(world_bounds.end.y + margin)

func center_on(world_position: Vector2) -> void:
	if camera == null:
		return
	camera.position = world_position
	camera.force_update_scroll()

func reset_zoom(value: float = 0.9) -> void:
	if camera == null:
		return
	camera.zoom = Vector2.ONE * clampf(value, min_zoom, max_zoom)
	camera.force_update_scroll()
