extends Node

signal state_changed
signal toast_requested(message: String)

const SAVE_PATH := "user://pocket_worlds_save.json"

var inventory: Dictionary = {
	"coins": 24,
	"dew": 2,
	"wood": 0,
	"berries": 0,
	"moonpetal_seed": 0,
	"moonpetal": 0,
	"moonstone": 0,
	"moonpetal_essence": 0,
	"rune_lantern": 0
}
var level: int = 1
var experience: int = 0
var flags: Dictionary = {}
var discoveries: Dictionary = {
	"sanctuary_arrival": {
		"title": "A place to call home",
		"description": "Your Sanctuary is a small world waiting to be shaped."
	}
}

func _ready() -> void:
	load_game()

func get_item_count(item_id: String) -> int:
	return int(inventory.get(item_id, 0))

func add_item(item_id: String, amount: int = 1) -> void:
	if amount <= 0:
		return
	inventory[item_id] = get_item_count(item_id) + amount
	state_changed.emit()
	save_game()

func consume_item(item_id: String, amount: int = 1) -> bool:
	if amount <= 0 or get_item_count(item_id) < amount:
		return false
	inventory[item_id] = get_item_count(item_id) - amount
	state_changed.emit()
	save_game()
	return true

func add_experience(amount: int) -> void:
	if amount <= 0:
		return
	experience += amount
	var levelled_up := false
	while experience >= experience_to_next_level():
		experience -= experience_to_next_level()
		level += 1
		levelled_up = true
	state_changed.emit()
	save_game()
	if levelled_up:
		toast_requested.emit("Sanctuary level %d reached!" % level)

func experience_to_next_level() -> int:
	return 40 + (level - 1) * 20

func has_flag(flag_id: String) -> bool:
	return bool(flags.get(flag_id, false))

func get_flag(flag_id: String, fallback: Variant = false) -> Variant:
	return flags.get(flag_id, fallback)

func set_flag(flag_id: String, value: Variant = true) -> void:
	flags[flag_id] = value
	state_changed.emit()
	save_game()

func unlock_discovery(discovery_id: String, title: String, description: String) -> bool:
	if discoveries.has(discovery_id):
		return false
	discoveries[discovery_id] = {
		"title": title,
		"description": description
	}
	state_changed.emit()
	save_game()
	toast_requested.emit("New discovery: %s" % title)
	return true

func is_discovered(discovery_id: String) -> bool:
	return discoveries.has(discovery_id)

func save_game() -> void:
	var save_data := {
		"version": 1,
		"inventory": inventory,
		"level": level,
		"experience": experience,
		"flags": flags,
		"discoveries": discoveries
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("Pocket Worlds: Could not open save file for writing.")
		return
	file.store_string(JSON.stringify(save_data, "\t"))
	file.close()

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_warning("Pocket Worlds: Could not open save file for reading.")
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Dictionary:
		push_warning("Pocket Worlds: Save file was invalid; starting with a fresh game.")
		return
	var data: Dictionary = parsed
	if int(data.get("version", 0)) != 1:
		push_warning("Pocket Worlds: Save version is unsupported; starting with a fresh game.")
		return
	var loaded_inventory: Variant = data.get("inventory", {})
	var loaded_flags: Variant = data.get("flags", {})
	var loaded_discoveries: Variant = data.get("discoveries", {})
	if loaded_inventory is Dictionary:
		for key in inventory.keys():
			inventory[key] = int(loaded_inventory.get(key, inventory[key]))
	if loaded_flags is Dictionary:
		flags = loaded_flags
	if loaded_discoveries is Dictionary and not loaded_discoveries.is_empty():
		discoveries = loaded_discoveries
	level = max(1, int(data.get("level", 1)))
	experience = max(0, int(data.get("experience", 0)))
	state_changed.emit()
