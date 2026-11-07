class_name WorldEntity
extends Node2D

var definition: PWAssetDefinition
var instance_id: StringName = &""
var grid_anchor: Vector2i = Vector2i.ZERO

var _sprite: Sprite2D
var _animated_sprite: AnimatedSprite2D

func configure(next_definition: PWAssetDefinition, next_instance_id: StringName, next_grid_anchor: Vector2i) -> void:
	definition = next_definition
	instance_id = next_instance_id
	grid_anchor = next_grid_anchor
	_rebuild_visual()

# Keep this Node2D's origin on the object's ground contact point.
# Its parent sorts this origin by Y; the sprite itself is offset above it.
func set_ground_position(world_position: Vector2) -> void:
	var depth_adjustment := definition.sort_y_offset if definition != null else 0.0
	position = world_position + Vector2(0.0, depth_adjustment)

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
		_sprite.position = _get_sprite_offset()
		add_child(_sprite)

func _get_sprite_offset() -> Vector2:
	var texture_size := Vector2(definition.texture_size_px)
	if texture_size == Vector2.ZERO:
		var texture := definition.load_texture()
		if texture != null:
			texture_size = texture.get_size()
	return texture_size * 0.5 - definition.ground_anchor_px + definition.visual_offset
