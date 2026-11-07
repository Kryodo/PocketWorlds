class_name WorldDebugObject
extends Node2D

var object_id: String = ""
var display_name: String = ""
var kind: String = "tree"
var selection_size: Vector2 = Vector2(72.0, 92.0)
var visual_scale: float = 1.0
var selected: bool = false
var interactable: bool = true

func configure(data: Dictionary) -> void:
	object_id = String(data.get("id", ""))
	display_name = String(data.get("name", object_id))
	kind = String(data.get("kind", "tree"))
	selection_size = data.get("selection_size", Vector2(72.0, 92.0))
	visual_scale = float(data.get("visual_scale", 1.0))
	interactable = bool(data.get("interactable", true))
	queue_redraw()

func get_selection_rect() -> Rect2:
	return Rect2(Vector2(-selection_size.x * 0.5, -selection_size.y), selection_size)

func _draw() -> void:
	_draw_ground_shadow()
	match kind:
		"tree":
			_draw_tree()
		"bush", "flowers":
			_draw_bush()
		"pond":
			_draw_pond()
		"log":
			_draw_log()
		"garden":
			_draw_garden()
		"home":
			_draw_home()
		"marker":
			_draw_marker()
		"crystal":
			_draw_crystal()
		"stone":
			_draw_stone()
		"lantern_slot", "lantern":
			_draw_lantern()
	if selected:
		draw_arc(Vector2(0.0, 2.0), maxf(23.0, selection_size.x * 0.28), 0.0, TAU, 32, Color("f2d58a"), 2.0, true)

func _draw_ground_shadow() -> void:
	var points := PackedVector2Array()
	for index in range(24):
		var angle := TAU * float(index) / 24.0
		points.append(Vector2(cos(angle) * 25.0, sin(angle) * 9.0 + 2.0))
	draw_colored_polygon(points, Color(0.05, 0.09, 0.07, 0.42))

func _draw_tree() -> void:
	draw_rect(Rect2(Vector2(-7, -25) * visual_scale, Vector2(14, 30) * visual_scale), Color("76503a"))
	draw_circle(Vector2(-16, -58) * visual_scale, 27.0 * visual_scale, Color("254a37"))
	draw_circle(Vector2(14, -62) * visual_scale, 31.0 * visual_scale, Color("315d40"))
	draw_circle(Vector2(-2, -88) * visual_scale, 27.0 * visual_scale, Color("3d704a"))
	draw_circle(Vector2(-8, -91) * visual_scale, 13.0 * visual_scale, Color("67945a"))
	draw_circle(Vector2(20, -70) * visual_scale, 10.0 * visual_scale, Color("78a764"))

func _draw_bush() -> void:
	draw_circle(Vector2(-15, -18) * visual_scale, 17.0 * visual_scale, Color("2c563e"))
	draw_circle(Vector2(7, -22) * visual_scale, 21.0 * visual_scale, Color("3b704a"))
	draw_circle(Vector2(22, -12) * visual_scale, 13.0 * visual_scale, Color("4a8051"))
	draw_circle(Vector2(-5, -27) * visual_scale, 5.0 * visual_scale, Color("c3656c"))

func _draw_pond() -> void:
	var points := PackedVector2Array()
	for index in range(32):
		var angle := TAU * float(index) / 32.0
		points.append(Vector2(cos(angle) * 49.0, sin(angle) * 22.0 - 9.0))
	draw_colored_polygon(points, Color("78976e"))
	for index in range(points.size()):
		points[index] += Vector2(-2.0, -4.0)
	draw_colored_polygon(points, Color("477e89"))
	draw_line(Vector2(-20, -14), Vector2(-2, -14), Color("b3d3c0"), 3.0, true)
	draw_line(Vector2(13, -2), Vector2(29, -2), Color("86b7ad"), 2.0, true)

func _draw_log() -> void:
	draw_rect(Rect2(Vector2(-29, -15) * visual_scale, Vector2(58, 20) * visual_scale), Color("64462f"))
	draw_rect(Rect2(Vector2(-25, -20) * visual_scale, Vector2(49, 8) * visual_scale), Color("946844"))
	draw_circle(Vector2(24, -5) * visual_scale, 7.0 * visual_scale, Color("c3a071"))

func _draw_garden() -> void:
	draw_rect(Rect2(Vector2(-28, -19), Vector2(56, 24)), Color("4f392c"))
	draw_rect(Rect2(Vector2(-24, -16), Vector2(48, 17)), Color("806044"))
	for row in range(3):
		draw_line(Vector2(-18, -13 + row * 6), Vector2(18, -13 + row * 6), Color("b08a5c"), 2.0, true)

func _draw_home() -> void:
	draw_rect(Rect2(Vector2(-32, -55), Vector2(64, 55)), Color("b08a5b"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(-39, -51), Vector2(0, -91), Vector2(39, -51)
	]), Color("75483b"))
	draw_rect(Rect2(Vector2(-7, -27), Vector2(14, 27)), Color("543b32"))
	draw_rect(Rect2(Vector2(-24, -42), Vector2(12, 12)), Color("e1c98b"))
	draw_rect(Rect2(Vector2(12, -42), Vector2(12, 12)), Color("e1c98b"))

func _draw_marker() -> void:
	draw_rect(Rect2(Vector2(-22, -47), Vector2(44, 47)), Color("68746b"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(-26, -43), Vector2(0, -63), Vector2(26, -43)
	]), Color("879188"))
	draw_line(Vector2(-12, -27), Vector2(12, -27), Color("d5c58a"), 4.0, true)
	draw_line(Vector2(0, -38), Vector2(0, -13), Color("d5c58a"), 4.0, true)

func _draw_crystal() -> void:
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, -69), Vector2(19, -27), Vector2(11, 0), Vector2(-13, 0), Vector2(-21, -28)
	]), Color("8075b6"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, -69), Vector2(2, -24), Vector2(-13, 0), Vector2(-21, -28)
	]), Color("b1a5dd"))
	draw_line(Vector2(0, -56), Vector2(0, -30), Color("e8e1fa"), 3.0, true)

func _draw_stone() -> void:
	draw_colored_polygon(PackedVector2Array([
		Vector2(-29, -5), Vector2(-22, -25), Vector2(-4, -36), Vector2(24, -25), Vector2(31, -5), Vector2(19, 3), Vector2(-21, 3)
	]), Color("718078"))
	draw_line(Vector2(-10, -22), Vector2(-1, -28), Color("a2afa3"), 3.0, true)

func _draw_lantern() -> void:
	draw_rect(Rect2(Vector2(-5, -35), Vector2(10, 35)), Color("58483b"))
	draw_rect(Rect2(Vector2(-13, -48), Vector2(26, 16)), Color("8b6748"))
	draw_rect(Rect2(Vector2(-8, -44), Vector2(16, 9)), Color("f0cf79"))
	draw_circle(Vector2(0, -39), 4.0, Color("fff0ae"))
