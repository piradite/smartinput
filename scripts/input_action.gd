@tool
class_name InputAction
extends Resource
enum Behavior { PRESS, VECTOR_2 }
enum DeviceRequirement { BOTH, KEYBOARD_ONLY, CONTROLLER_ONLY }
@export_group("Identity")
@export var category: String = "General"
@export var display_name: String = ""
@export var id: StringName
@export var is_locked: bool = false
@export var blocked_indices: Array[int] = []
@export var custom_row_scene: PackedScene
@export_group("Constraints")
@export var behavior: Behavior = Behavior.PRESS:
    set(value):
        behavior = value
        notify_property_list_changed()
@export var device_limit: DeviceRequirement = DeviceRequirement.BOTH
@export_group("Default Events")
@export var events: Array[InputEvent]
@export var deadzone: float = 0.5
@export_group("Vector Display Names")
@export var up_display_name: String = "Up"
@export var down_display_name: String = "Down"
@export var left_display_name: String = "Left"
@export var right_display_name: String = "Right"
@export_group("Vector Suffixes")
@export var up_suffix: String = "up"
@export var down_suffix: String = "down"
@export var left_suffix: String = "left"
@export var right_suffix: String = "right"
@export_group("Vector Events")
@export var up: Array[InputEvent]
@export var down: Array[InputEvent]
@export var left: Array[InputEvent]
@export var right: Array[InputEvent]

func _init():
    category = InputConfig.action_category
    deadzone = InputConfig.action_deadzone
    device_limit = InputConfig.action_device_limit as DeviceRequirement
    up_display_name = InputConfig.action_up_display_name
    down_display_name = InputConfig.action_down_display_name
    left_display_name = InputConfig.action_left_display_name
    right_display_name = InputConfig.action_right_display_name
    up_suffix = InputConfig.action_up_suffix
    down_suffix = InputConfig.action_down_suffix
    left_suffix = InputConfig.action_left_suffix
    right_suffix = InputConfig.action_right_suffix

func _validate_property(property: Dictionary):
    if behavior == Behavior.PRESS:
        if property.name in ["deadzone", "up", "down", "left", "right", "up_display_name", "down_display_name", "left_display_name", "right_display_name", "up_suffix", "down_suffix", "left_suffix", "right_suffix"]:
            property.usage = PROPERTY_USAGE_NO_EDITOR
    elif behavior == Behavior.VECTOR_2:
        if property.name == "events":
            property.usage = PROPERTY_USAGE_NO_EDITOR
