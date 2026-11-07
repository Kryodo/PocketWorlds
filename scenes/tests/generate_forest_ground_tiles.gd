extends Node

func _ready() -> void:
	var result: Dictionary = ForestGroundTileGenerator.generate_all_assets()
	var errors: Array = result.get("errors", [])
	if not errors.is_empty():
		for error in errors:
			push_error(String(error))
		print("FOREST GROUND TILE PNG GENERATION FAIL")
		get_tree().quit(1)
		return
	var generated: Array = result.get("generated", [])
	var skipped: Array = result.get("skipped", [])
	print("FOREST GROUND TILE PNG GENERATION PASS · generated %d · existing preserved %d" % [generated.size(), skipped.size()])
	get_tree().quit()
