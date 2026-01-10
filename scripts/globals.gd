@tool
class_name InputConfig
extends RefCounted

# Keybind Defaults
static var keybind_remapping_text: String = "..."
static var keybind_unbound_text: String = "Unbound"

# SettingsMenu Defaults
static var menu_show_search: bool = true
static var menu_column_titles: Array[String] = ["PRIMARY", "SECONDARY", "TERTIARY"]
static var menu_label_stretch_ratio: float = 2.0
static var menu_button_stretch_ratio: float = 1.0
static var menu_search_placeholder: String = "Search actions..."
static var menu_restore_label: String = "RESTORE ALL DEFAULTS"
static var menu_show_restore_defaults: bool = true

# Template Scenes
static var menu_keybind_scene_override: PackedScene
static var menu_category_header_scene: PackedScene
static var menu_action_header_scene: PackedScene
static var menu_column_header_scene: PackedScene
static var menu_search_bar_scene: PackedScene
static var menu_footer_scene: PackedScene

# InputAction Defaults
static var action_category: String = "General"
static var action_deadzone: float = 0.5
static var action_device_limit: int = 0 # 0=BOTH
static var action_up_display_name: String = "Up"
static var action_down_display_name: String = "Down"
static var action_left_display_name: String = "Left"
static var action_right_display_name: String = "Right"
static var action_up_suffix: String = "up"
static var action_down_suffix: String = "down"
static var action_left_suffix: String = "left"
static var action_right_suffix: String = "right"

# InputIconLibrary Defaults
static var icon_keyboard_path: String = ""
static var icon_mouse_path: String = ""
static var icon_gamepad_path: String = ""
