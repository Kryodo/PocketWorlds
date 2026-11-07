@tool
class_name PWAssetDefinition
extends Resource

enum PlacementMode {
	PLACEABLE,
	DECORATIVE,
	FIXED
}

enum AssetRole {
	WORLD_OBJECT,
	GROUND_TILE
}

@export var schema_version: int = 1
@export var asset_id: StringName = &""
@export var display_name: String = ""
@export var category: StringName = &"environment"
@export var tags: Array[StringName] = []

@export_file("*.png") var texture_path: String = ""
@export var texture_size_px: Vector2i = Vector2i.ZERO
@export var ground_anchor_px: Vector2 = Vector2.ZERO
@export var visual_offset: Vector2 = Vector2.ZERO

@export var footprint_size: Vector2i = Vector2i.ONE
@export var footprint_offsets: Array[Vector2i] = []
@export var placement_mode: PlacementMode = PlacementMode.PLACEABLE
@export var blocking_offsets: Array[Vector2i] = []
@export var selection_polygon: PackedVector2Array = PackedVector2Array()

@export var sort_y_offset: float = 0.0
@export var sort_z_index: int = 0
@export var sprite_frames: SpriteFrames
@export var default_animation: StringName = &"idle"
@export var asset_role: AssetRole = AssetRole.WORLD_OBJECT
@export var sprite_scale: Vector2 = Vector2.ONE

func get_footprint_cells(anchor: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	if not footprint_offsets.is_empty():
		for offset in footprint_offsets:
			result.append(anchor + offset)
		return result
	for y in range(maxi(1, footprint_size.y)):
		for x in range(maxi(1, footprint_size.x)):
			result.append(anchor + Vector2i(x, y))
	return result

func get_blocking_cells(anchor: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for offset in blocking_offsets:
		result.append(anchor + offset)
	return result

func load_texture() -> Texture2D:
	if texture_path.is_empty() or not ResourceLoader.exists(texture_path):
		return null
	return load(texture_path) as Texture2D
