@tool
class_name InputIcon
extends Resource


@export_group("Icon Folders")
@export_dir var keyboard_icons_path: String
@export_dir var mouse_icons_path: String
@export_dir var gamepad_icons_path: String

@export_group("Manual Mappings")
@export var manual_overrides: Dictionary = {}


func _init() -> void:
	if keyboard_icons_path == "":
		keyboard_icons_path = InputConfig.icon_keyboard_path
	
	if mouse_icons_path == "":
		mouse_icons_path = InputConfig.icon_mouse_path
	
	if gamepad_icons_path == "":
		gamepad_icons_path = InputConfig.icon_gamepad_path


func get_icon(event: InputEvent) -> Texture2D:
	var key = _get_event_key(event).to_lower()
	if key in manual_overrides:
		return manual_overrides[key]
	
	var path = _get_automatic_path(event)
	if path == "" or not ResourceLoader.exists(path):
		return null
	
	return load(path)


func _get_event_key(event: InputEvent) -> String:
	if event is InputEventKey:
		return OS.get_keycode_string(event.physical_keycode if event.physical_keycode != KEY_NONE else event.keycode)
	elif event is InputEventMouseButton:
		return "mouse_" + str(event.button_index)
	elif event is InputEventJoypadButton:
		return "joy_button_" + str(event.button_index)
	elif event is InputEventJoypadMotion:
		var suffix = "plus" if event.axis_value > 0 else "minus"
		return "joy_axis_" + str(event.axis) + "_" + suffix
	return ""


func _get_automatic_path(event: InputEvent) -> String:
	var folder = ""
	var file_name = _get_event_key(event)
	
	if event is InputEventKey:
		folder = keyboard_icons_path
	elif event is InputEventMouseButton:
		folder = mouse_icons_path
	elif event is InputEventJoypadButton or event is InputEventJoypadMotion:
		folder = gamepad_icons_path
	
	if folder.is_empty() or file_name.is_empty():
		return ""
	
	file_name = file_name.to_lower().replace(" ", "_") + ".png"
	return folder.path_join(file_name)