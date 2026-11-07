extends Node2D

const BOARD_SIZE := Vector2(1280.0, 720.0)

const CURRENT_AXIS_A := Vector2(48.0, 24.0)
const CURRENT_AXIS_B := Vector2(-48.0, 24.0)
const CANDIDATE_AXIS_A := Vector2(64.0, 32.0)
const CANDIDATE_AXIS_B := Vector2(-64.0, 32.0)

const BG := Color("17272c")
const PANEL := Color("22383a")
const PANEL_EDGE := Color("45625a")
const TEXT_MAIN := Color("f3ead4")
const TEXT_MUTED := Color("bdc8b8")
const ACCENT := Color("d7bb7d")
const GRID_FILL := Color(0.45, 0.72, 0.48, 0.22)
const GRID_LINE := Color("9bc69a")
const FOOTPRINT_FILL := Color(0.82, 0.70, 0.43, 0.18)
const FOOTPRINT_LINE := Color("e5c889")

func _ready() -> void:
	_validate_candidate_projection()
	_build_labels()
	queue_redraw()
	print("GRID FOOTPRINT REFERENCE PASS")
	print("Candidate: 128 × 64 | A=(64,32) | B=(-64,32)")
	print("PNG centre anchor: (64,32) at 1×; (128,64) at 2×")
	print("Press P to export the reference board to res://assets/catalog/grid_footprint_reference.png")

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, BOARD_SIZE), BG, true)
	_draw_panel(Rect2(20.0, 96.0, 300.0, 556.0))
	_draw_panel(Rect2(336.0, 96.0, 600.0, 556.0))
	_draw_panel(Rect2(952.0, 96.0, 308.0, 556.0))

	_draw_grid_size_panel()
	_draw_footprint_examples()
	_draw_visual_scale_examples()
	draw_line(Vector2(20.0, 664.0), Vector2(1260.0, 664.0), PANEL_EDGE, 1.0, true)

func _draw_panel(rect: Rect2) -> void:
	draw_rect(rect, PANEL, true)
	draw_rect(rect, PANEL_EDGE, false, 2.0, true)

func _draw_grid_size_panel() -> void:
	# Candidate 128 × 64 ground-tile canvas.
	var candidate_center := Vector2(170.0, 250.0)
	_draw_canvas_diamond(candidate_center, 128.0, 64.0, GRID_FILL, GRID_LINE)
	draw_circle(candidate_center, 5.0, ACCENT)
	draw_circle(candidate_center, 10.0, Color(0.84, 0.73, 0.48, 0.35), false, 1.5, true)

	# Axis vectors are shown from the top grid intersection.
	var top := candidate_center + Vector2(0.0, -32.0)
	_draw_arrow(top, top + CANDIDATE_AXIS_A, Color("89b7e8"))
	_draw_arrow(top, top + CANDIDATE_AXIS_B, Color("e6a56f"))

	# Current 96 × 48 tile, shown at the same diagram scale.
	var current_center := Vector2(170.0, 468.0)
	_draw_canvas_diamond(
		current_center,
		96.0,
		48.0,
		Color(0.58, 0.66, 0.72, 0.12),
		Color("8b9ba5")
	)
	draw_circle(current_center, 4.0, Color("aebdc4"))

func _draw_canvas_diamond(
	center: Vector2,
	width: float,
	height: float,
	fill_color: Color,
	line_color: Color
) -> void:
	var points := PackedVector2Array([
		center + Vector2(0.0, -height * 0.5),
		center + Vector2(width * 0.5, 0.0),
		center + Vector2(0.0, height * 0.5),
		center + Vector2(-width * 0.5, 0.0)
	])
	draw_colored_polygon(points, fill_color)
	points.append(points[0])
	draw_polyline(points, line_color, 2.0, true)

func _draw_footprint_examples() -> void:
	# All footprint diagrams use the same scale, so their relative areas are comparable.
	var scale := 0.38
	_draw_footprint(Vector2(382.0, 218.0), Vector2i(1, 1), scale)
	_draw_footprint(Vector2(520.0, 218.0), Vector2i(1, 2), scale)
	_draw_footprint(Vector2(700.0, 218.0), Vector2i(2, 2), scale)
	_draw_footprint(Vector2(412.0, 438.0), Vector2i(2, 3), scale)
	_draw_footprint(Vector2(700.0, 438.0), Vector2i(3, 3), scale)

func _draw_footprint(origin: Vector2, footprint: Vector2i, scale: float) -> void:
	var axis_a := CANDIDATE_AXIS_A * scale
	var axis_b := CANDIDATE_AXIS_B * scale
	var outer := PackedVector2Array([
		origin,
		origin + axis_a * float(footprint.x),
		origin + axis_a * float(footprint.x) + axis_b * float(footprint.y),
		origin + axis_b * float(footprint.y)
	])
	draw_colored_polygon(outer, FOOTPRINT_FILL)

	for y in range(footprint.y):
		for x in range(footprint.x):
			var top := origin + axis_a * float(x) + axis_b * float(y)
			var cell := PackedVector2Array([
				top,
				top + axis_a,
				top + axis_a + axis_b,
				top + axis_b
			])
			cell.append(cell[0])
			draw_polyline(cell, GRID_LINE, 1.35, true)

	outer.append(outer[0])
	draw_polyline(outer, FOOTPRINT_LINE, 2.2, true)

func _draw_visual_scale_examples() -> void:
	# Small 1×1 plant: a modest sprite above its single-cell ground footprint.
	_draw_canvas_diamond(Vector2(1106.0, 213.0), 64.0, 32.0, GRID_FILL, GRID_LINE)
	draw_line(Vector2(1106.0, 213.0), Vector2(1106.0, 158.0), Color("74a96a"), 5.0, true)
	draw_line(Vector2(1106.0, 188.0), Vector2(1089.0, 173.0), Color("74a96a"), 4.0, true)
	draw_line(Vector2(1106.0, 181.0), Vector2(1122.0, 165.0), Color("74a96a"), 4.0, true)
	draw_circle(Vector2(1106.0, 151.0), 10.0, Color("e9a7c8"))

	# 2×2 tree: the canopy intentionally overhangs its occupied ground cells.
	_draw_footprint(Vector2(1058.0, 352.0), Vector2i(2, 2), 0.34)
	_draw_ellipse(Vector2(1058.0, 302.0), Vector2(67.0, 49.0), Color("397b50"))
	_draw_ellipse(Vector2(1030.0, 296.0), Vector2(38.0, 31.0), Color("599454"))
	_draw_ellipse(Vector2(1093.0, 302.0), Vector2(34.0, 29.0), Color("4b894e"))
	draw_rect(Rect2(1051.0, 332.0, 14.0, 42.0), Color("98633c"), true)
	_draw_ellipse(Vector2(1058.0, 375.0), Vector2(27.0, 7.0), Color(0.05, 0.09, 0.06, 0.45))

	# 3×3 cottage: an architectural landmark, clearly larger than a compact prop.
	_draw_footprint(Vector2(1092.0, 548.0), Vector2i(3, 3), 0.27)
	draw_colored_polygon(PackedVector2Array([
		Vector2(1023.0, 526.0), Vector2(1092.0, 476.0),
		Vector2(1162.0, 526.0), Vector2(1154.0, 540.0),
		Vector2(1092.0, 493.0), Vector2(1031.0, 540.0)
	]), Color("8c5546"))
	draw_rect(Rect2(1031.0, 525.0, 123.0, 49.0), Color("d0a66d"), true)
	draw_rect(Rect2(1082.0, 544.0, 22.0, 30.0), Color("684b3a"), true)
	draw_rect(Rect2(1043.0, 538.0, 18.0, 15.0), Color("9cc3bf"), true)
	draw_rect(Rect2(1123.0, 538.0, 18.0, 15.0), Color("9cc3bf"), true)

func _draw_arrow(start: Vector2, finish: Vector2, color: Color) -> void:
	draw_line(start, finish, color, 3.0, true)
	var direction := (finish - start).normalized()
	var perpendicular := Vector2(-direction.y, direction.x)
	var arrow := PackedVector2Array([
		finish,
		finish - direction * 12.0 + perpendicular * 6.0,
		finish - direction * 12.0 - perpendicular * 6.0
	])
	draw_colored_polygon(arrow, color)

func _draw_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for index in range(33):
		var angle := TAU * float(index) / 32.0
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	draw_colored_polygon(points, color)

func _build_labels() -> void:
	_add_label("POCKET WORLDS  /  GRID & FOOTPRINT REFERENCE", Vector2(26.0, 18.0), Vector2(1050.0, 32.0), 24, TEXT_MAIN, true)
	_add_label("CP06 · PROPOSED 128 × 64 DIMETRIC GRID · TECHNICAL GUIDE FOR RELATIVE SCALE", Vector2(28.0, 55.0), Vector2(1120.0, 24.0), 13, TEXT_MUTED)

	_add_label("CELL STANDARD", Vector2(38.0, 112.0), Vector2(260.0, 26.0), 17, TEXT_MAIN, true)
	_add_label("CANDIDATE 128 × 64", Vector2(78.0, 170.0), Vector2(190.0, 22.0), 13, ACCENT, true)
	_add_label("PNG centre anchor: (64, 32)", Vector2(62.0, 341.0), Vector2(220.0, 22.0), 13, TEXT_MAIN)
	_add_label("A = (64, 32)", Vector2(212.0, 253.0), Vector2(100.0, 20.0), 11, Color("9fc4ef"))
	_add_label("B = (-64, 32)", Vector2(34.0, 253.0), Vector2(115.0, 20.0), 11, Color("f0b080"))
	_add_label("CURRENT 96 × 48", Vector2(88.0, 411.0), Vector2(175.0, 22.0), 12, TEXT_MUTED, true)
	_add_label("PNG centre: (48, 24)", Vector2(73.0, 508.0), Vector2(195.0, 20.0), 12, TEXT_MUTED)
	_add_label("2× source: 256 × 128", Vector2(63.0, 552.0), Vector2(220.0, 20.0), 12, TEXT_MAIN)
	_add_label("2× pixel anchor: (128, 64)", Vector2(48.0, 575.0), Vector2(245.0, 20.0), 12, TEXT_MAIN)
	_add_label("World cell-centre offset from top vertex: (0, 32)", Vector2(39.0, 615.0), Vector2(265.0, 28.0), 10, TEXT_MUTED)

	_add_label("LOGICAL FOOTPRINTS", Vector2(354.0, 112.0), Vector2(520.0, 26.0), 17, TEXT_MAIN, true)
	_add_label("Each outline is made from occupied 128 × 64 cells.", Vector2(356.0, 145.0), Vector2(540.0, 20.0), 12, TEXT_MUTED)
	_add_label("1 × 1", Vector2(390.0, 276.0), Vector2(90.0, 20.0), 13, TEXT_MAIN, true)
	_add_label("128 × 64", Vector2(381.0, 298.0), Vector2(100.0, 18.0), 10, TEXT_MUTED)
	_add_label("1 × 2", Vector2(538.0, 295.0), Vector2(90.0, 20.0), 13, TEXT_MAIN, true)
	_add_label("192 × 96", Vector2(530.0, 317.0), Vector2(100.0, 18.0), 10, TEXT_MUTED)
	_add_label("2 × 2", Vector2(720.0, 314.0), Vector2(90.0, 20.0), 13, TEXT_MAIN, true)
	_add_label("256 × 128", Vector2(709.0, 336.0), Vector2(110.0, 18.0), 10, TEXT_MUTED)
	_add_label("2 × 3", Vector2(425.0, 535.0), Vector2(90.0, 20.0), 13, TEXT_MAIN, true)
	_add_label("320 × 160", Vector2(414.0, 557.0), Vector2(110.0, 18.0), 10, TEXT_MUTED)
	_add_label("3 × 3", Vector2(726.0, 571.0), Vector2(90.0, 20.0), 13, TEXT_MAIN, true)
	_add_label("384 × 192", Vector2(714.0, 593.0), Vector2(110.0, 18.0), 10, TEXT_MUTED)
	_add_label("Width = 64 × (columns + rows)   ·   Height = 32 × (columns + rows)", Vector2(354.0, 620.0), Vector2(565.0, 20.0), 10, ACCENT)

	_add_label("VISUAL SIZE ≠ FOOTPRINT", Vector2(970.0, 112.0), Vector2(270.0, 26.0), 16, TEXT_MAIN, true)
	_add_label("1 × 1 plant", Vector2(1044.0, 235.0), Vector2(140.0, 20.0), 12, TEXT_MAIN, true)
	_add_label("2 × 2 tree · canopy may overhang", Vector2(974.0, 400.0), Vector2(270.0, 20.0), 11, TEXT_MAIN, true)
	_add_label("3 × 3 cottage · architectural scale", Vector2(974.0, 606.0), Vector2(270.0, 20.0), 11, TEXT_MAIN, true)
	_add_label("Base / contact point stays on ground.", Vector2(974.0, 427.0), Vector2(270.0, 20.0), 10, TEXT_MUTED)
	_add_label("Do not resize all objects to one canvas.", Vector2(974.0, 629.0), Vector2(270.0, 18.0), 10, TEXT_MUTED)

	_add_label("Footprint = occupied ground cells. Visible artwork can extend above or beyond it.", Vector2(25.0, 675.0), Vector2(870.0, 20.0), 12, TEXT_MAIN)
	_add_label("Press P to export PNG", Vector2(1030.0, 675.0), Vector2(220.0, 20.0), 12, ACCENT, true)

func _add_label(
	value: String,
	label_position: Vector2,
	label_size: Vector2,
	font_size: int,
	color: Color,
	bold: bool = false
) -> void:
	var label := Label.new()
	label.text = value
	label.position = label_position
	label.size = label_size
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	if bold:
		label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.4))
		label.add_theme_constant_override("shadow_size", 2)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)

func _validate_candidate_projection() -> void:
	var determinant := (
		CANDIDATE_AXIS_A.x * CANDIDATE_AXIS_B.y
		- CANDIDATE_AXIS_A.y * CANDIDATE_AXIS_B.x
	)
	assert(not is_zero_approx(determinant), "Candidate projection axes must not be collinear.")

	for y in range(32):
		for x in range(32):
			var expected := Vector2i(x, y)
			var point := _candidate_grid_to_world(expected)
			var actual := _candidate_world_to_grid(point, determinant)
			assert(actual == expected, "Candidate grid round-trip failed at %s." % expected)

	var footprints: Array[Vector2i] = [
		Vector2i(1, 1),
		Vector2i(1, 2),
		Vector2i(2, 2),
		Vector2i(2, 3),
		Vector2i(3, 3)
	]
	for footprint in footprints:
		var bounds := _candidate_footprint_bounds(footprint)
		var expected_width := 64.0 * float(footprint.x + footprint.y)
		var expected_height := 32.0 * float(footprint.x + footprint.y)
		assert(
			is_equal_approx(bounds.x, expected_width)
			and is_equal_approx(bounds.y, expected_height),
			"Candidate footprint bounds failed for %s." % footprint
		)

	assert((Vector2(128.0, 64.0) * 0.5).is_equal_approx(Vector2(64.0, 32.0)), "1× PNG centre anchor must be (64,32).")
	assert((Vector2(256.0, 128.0) * 0.5).is_equal_approx(Vector2(128.0, 64.0)), "2× PNG centre anchor must be (128,64).")

func _candidate_grid_to_world(cell: Vector2i) -> Vector2:
	return CANDIDATE_AXIS_A * float(cell.x) + CANDIDATE_AXIS_B * float(cell.y)

func _candidate_world_to_grid(point: Vector2, determinant: float) -> Vector2i:
	var x := (point.x * CANDIDATE_AXIS_B.y - point.y * CANDIDATE_AXIS_B.x) / determinant
	var y := (CANDIDATE_AXIS_A.x * point.y - CANDIDATE_AXIS_A.y * point.x) / determinant
	return Vector2i(roundi(x), roundi(y))

func _candidate_footprint_bounds(footprint: Vector2i) -> Vector2:
	var corners := PackedVector2Array([
		Vector2.ZERO,
		CANDIDATE_AXIS_A * float(footprint.x),
		CANDIDATE_AXIS_A * float(footprint.x) + CANDIDATE_AXIS_B * float(footprint.y),
		CANDIDATE_AXIS_B * float(footprint.y)
	])
	var min_x := corners[0].x
	var max_x := corners[0].x
	var min_y := corners[0].y
	var max_y := corners[0].y
	for corner in corners:
		min_x = minf(min_x, corner.x)
		max_x = maxf(max_x, corner.x)
		min_y = minf(min_y, corner.y)
		max_y = maxf(max_y, corner.y)
	return Vector2(max_x - min_x, max_y - min_y)

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_P:
		_export_reference_png()

func _export_reference_png() -> void:
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var path := "res://assets/catalog/grid_footprint_reference.png"
	var error := image.save_png(ProjectSettings.globalize_path(path))
	if error == OK:
		print("GRID FOOTPRINT REFERENCE PNG EXPORTED: ", path)
	else:
		push_error("Could not export grid reference PNG. Error: %d" % error)
