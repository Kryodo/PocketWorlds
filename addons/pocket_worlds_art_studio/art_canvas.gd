@tool
extends Control

signal pixel_requested(pixel: Vector2i)

var _preview_texture: Texture2D
var image_size: Vector2i = Vector2i(128, 128)
var _last_drawn_pixel: Vector2i = Vector2i(-1, -1)

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	mouse_filter = Control.MOUSE_FILTER_STOP
	queue_redraw()

func set_preview_image(image: Image) -> void:
	if image == null or image.is_empty():
		_preview_texture = null
	else:
		_preview_texture = ImageTexture.create_from_image(image)
		image_size = image.get_size()
	queue_redraw()

func _get_canvas_rect() -> Rect2:
	var available := Vector2(maxf(64.0, size.x - 32.0), maxf(64.0, size.y - 32.0))
	var image_aspect := float(image_size.x) / float(maxi(1, image_size.y))
	var available_aspect := available.x / available.y
	var canvas_size := available
	if available_aspect > image_aspect:
		canvas_size.x = available.y * image_aspect
	else:
		canvas_size.y = available.x / image_aspect
	return Rect2((size - canvas_size) * 0.5, canvas_size)

func _draw() -> void:
	var canvas_rect := _get_canvas_rect()
	draw_rect(Rect2(Vector2.ZERO, size), Color("202b29"))
	draw_rect(canvas_rect.grow(3.0), Color("111918"))
	var pixel_scale := canvas_rect.size / Vector2(image_size)
	var checker_pixels := 8
	var checker_columns := ceili(float(image_size.x) / float(checker_pixels))
	var checker_rows := ceili(float(image_size.y) / float(checker_pixels))
	for y in range(checker_rows):
		for x in range(checker_columns):
			var shade := Color("46514c") if (x + y) % 2 == 0 else Color("39443f")
			var origin := canvas_rect.position + Vector2(x, y) * float(checker_pixels) * pixel_scale
			var extent := Vector2(
				minf(float(checker_pixels), float(image_size.x - x * checker_pixels)),
				minf(float(checker_pixels), float(image_size.y - y * checker_pixels))
			) * pixel_scale
			draw_rect(Rect2(origin, extent), shade)

	if _preview_texture != null:
		draw_texture_rect(_preview_texture, canvas_rect, false)

	if canvas_rect.size.x / float(image_size.x) >= 3.0:
		for line_index in range(image_size.x + 1):
			var x := canvas_rect.position.x + canvas_rect.size.x * float(line_index) / float(image_size.x)
			draw_line(Vector2(x, canvas_rect.position.y), Vector2(x, canvas_rect.end.y), Color(0.08, 0.12, 0.1, 0.22), 1.0)
		for line_index in range(image_size.y + 1):
			var y := canvas_rect.position.y + canvas_rect.size.y * float(line_index) / float(image_size.y)
			draw_line(Vector2(canvas_rect.position.x, y), Vector2(canvas_rect.end.x, y), Color(0.08, 0.12, 0.1, 0.22), 1.0)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			var pixel := _screen_to_pixel(event.position)
			_emit_line(_last_drawn_pixel, pixel)
			_last_drawn_pixel = pixel
			accept_event()
		else:
			_last_drawn_pixel = Vector2i(-1, -1)
			accept_event()
	elif event is InputEventMouseMotion and (event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
		var pixel := _screen_to_pixel(event.position)
		_emit_line(_last_drawn_pixel, pixel)
		_last_drawn_pixel = pixel
		accept_event()

func _emit_line(start_pixel: Vector2i, end_pixel: Vector2i) -> void:
	if not _is_valid_pixel(end_pixel):
		return
	if not _is_valid_pixel(start_pixel):
		pixel_requested.emit(end_pixel)
		return
	var distance := maxi(absi(end_pixel.x - start_pixel.x), absi(end_pixel.y - start_pixel.y))
	if distance == 0:
		pixel_requested.emit(end_pixel)
		return
	for step in range(distance + 1):
		var amount := float(step) / float(distance)
		var pixel := Vector2i(
			roundi(lerpf(float(start_pixel.x), float(end_pixel.x), amount)),
			roundi(lerpf(float(start_pixel.y), float(end_pixel.y), amount))
		)
		pixel_requested.emit(pixel)

func _screen_to_pixel(position: Vector2) -> Vector2i:
	var canvas_rect := _get_canvas_rect()
	var local := (position - canvas_rect.position) / canvas_rect.size
	return Vector2i(
		floori(local.x * image_size.x),
		floori(local.y * image_size.y)
	)

func _is_valid_pixel(pixel: Vector2i) -> bool:
	return pixel.x >= 0 and pixel.y >= 0 and pixel.x < image_size.x and pixel.y < image_size.y
