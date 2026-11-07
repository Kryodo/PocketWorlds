@tool
extends EditorPlugin

const STUDIO_WINDOW_SCRIPT := preload("res://addons/pocket_worlds_art_studio/art_studio_window.gd")

var _studio_window: Window

func _enter_tree() -> void:
	add_tool_menu_item("Pocket Worlds Art Studio", _open_studio)

func _exit_tree() -> void:
	remove_tool_menu_item("Pocket Worlds Art Studio")
	if is_instance_valid(_studio_window):
		_studio_window.queue_free()
		_studio_window = null

func _open_studio() -> void:
	if not is_instance_valid(_studio_window):
		_studio_window = STUDIO_WINDOW_SCRIPT.new()
		_studio_window.filesystem_changed.connect(_on_filesystem_changed)
		get_editor_interface().get_base_control().add_child(_studio_window)
	_studio_window.popup_centered(Vector2i(1180, 820))

func _on_filesystem_changed() -> void:
	call_deferred("_scan_project_filesystem")

func _scan_project_filesystem() -> void:
	get_editor_interface().get_resource_filesystem().scan()
