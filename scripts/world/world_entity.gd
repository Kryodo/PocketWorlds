class_name WorldEntity
extends Node2D

var definition: PWAssetDefinition
var instance_id: StringName = &""
var object_id: String = ""
var display_name: String = ""
var grid_anchor: Vector2i = Vector2i.ZERO
var selection_size: Vector2 = Vector2(100.0, 100.0)
var selected: bool = false
var interactable: bool = true

var _sprite: Sprite2D
var _animated_sprite: AnimatedSprite2D

func configure(
	next_definition: PWAssetDefinition,
	next_instance_id: StringName,
	next_grid_anchor: Vector2i,
	next_selection_size: Vector2 = Vector2(100.0, 100.0)
) -> void:
	definition = next_definition
	instance_id = next_instance_id
	object_id = String(next_instance_id)
	grid_anchor = next_grid_anchor
	selection_size = next_selection_size
	display_name = definition.display_name if definition != null else object_id
	_rebuild_visual()

# The Node2D origin is the bottom-center ground contact point used by the parent's Y-sort.
# The sprite is offset upward from this point using the artwork's pixel anchor.
func set_ground_position(world_position: Vector2) -> void:
	var depth_adjustment := definition.sort_y_offset if definition != null else 0.0
	position = world_position + Vector2(0.0, depth_adjustment)

func get_selection_rect() -> Rect2:
	return Rect2(Vector2(-selection_size.x * 0.5, -selection_size.y), selection_size)

func _draw() -> void:
	if not selected:
		return
	var radius_x := maxf(23.0, selection_size.x * 0.28)
	var radius_y := maxf(8.0, selection_size.y * 0.075)
	var points := PackedVector2Array()
	for index in range(33):
		var angle := TAU * float(index) / 32.0
		points.append(Vector2(cos(angle) * radius_x, sin(angle) * radius_y + 2.0))
	draw_polyline(points, Color("f2d58a"), 2.0, true)

func _rebuild_visual() -> void:
	for child in get_children():
		child.queue_free()
	_sprite = null
	_animated_sprite = null
	if definition == null:
		return

	z_index = definition.sort_z_index

	if definition.sprite_frames != null and definition.sprite_frames.get_animation_names().size() > 0:
		_animated_sprite = AnimatedSprite2D.new()
		_animated_sprite.sprite_frames = definition.sprite_frames
		_animated_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_animated_sprite.scale = definition.sprite_scale
		_animated_sprite.position = _get_sprite_offset()
		add_child(_animated_sprite)
		var animation_name := String(definition.default_animation)
		if not _animated_sprite.sprite_frames.has_animation(animation_name):
			animation_name = _animated_sprite.sprite_frames.get_animation_names()[0]
		_animated_sprite.play(animation_name)
	else:
		var texture := definition.load_texture()
		if texture == null:
			return
		_sprite = Sprite2D.new()
		_sprite.texture = texture
		_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_sprite.scale = definition.sprite_scale
		_sprite.position = _get_sprite_offset()
		add_child(_sprite)

func _get_sprite_offset() -> Vector2:
	var texture_size := Vector2(definition.texture_size_px)
	if texture_size == Vector2.ZERO:
		var texture := definition.load_texture()
		if texture != null:
			texture_size = texture.get_size()
	return (texture_size * 0.5 - definition.ground_anchor_px) * definition.sprite_scale + definition.visual_offset
