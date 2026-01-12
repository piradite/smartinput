extends Node

func _ready() -> void:
	var parent = get_parent()
	if parent:
		if not parent.visibility_changed.is_connected(_on_visibility_changed):
			parent.visibility_changed.connect(_on_visibility_changed)

func _exit_tree() -> void:
	InputController.save_config()

func _on_visibility_changed() -> void:
	var parent = get_parent()
	if parent and not parent.is_visible_in_tree():
		InputController.save_config()
