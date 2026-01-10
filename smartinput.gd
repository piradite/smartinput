@tool
extends EditorPlugin
const AUTOLOAD_NAME = "InputController"
func _enter_tree():
	add_autoload_singleton(AUTOLOAD_NAME, "res://addons/smartinput/scripts/input_controller.gd")
func _exit_tree():
	remove_autoload_singleton(AUTOLOAD_NAME)