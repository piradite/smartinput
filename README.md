# SmartInput
High-Flexibility Input Remapping Framework for Godot 4.5+

- Professional-grade input logic and UI generation.
- Decoupled architecture for maximum project flexibility.
- Full support for Keyboard, Mouse, and Gamepad hardware.

<div align = center><img src="icon.png" width="256"><br><br>

&ensp;[<kbd> <br> Usage <br> </kbd>](#Usage)&ensp;
&ensp;[<kbd> <br> Installation <br> </kbd>](#Installation)&ensp;
&ensp;[<kbd> <br> InputController API <br> </kbd>](#inputcontroller-api-reference)&ensp;
&ensp;[<kbd> <br> SettingsMenu API <br> </kbd>](#settingsmenu-ui-api-reference)&ensp;
&ensp;[<kbd> <br> InputAction Resource <br> </kbd>](#inputaction-resource-properties)&ensp;
&ensp;[<kbd> <br> Icon Library Guide <br> </kbd>](#icon-library-inputiconlibrary)&ensp;
&ensp;[<kbd> <br> FAQ <br> </kbd>](#FAQ)&ensp;
<br><br><br><br></div>

--------------------------------------------------------------------------------

## Requirements
* Godot 4.5+

## Features
* Multi-Slot Mapping: Support for up to 3 binding slots (Primary, Secondary, Tertiary) per action.
* Vector2 Support: Automated generation of directional sub-actions (WASD/Sticks).
* Modifier Combos: Native detection for Shift, Ctrl, Alt, and Meta combinations.
* Pretty Names: Intuitive labels for Mouse and Controller buttons.
* Visual Icons: Optional icon library support for visual button prompts.
* Whitelist and Blacklist: Restrict remapping to specific keys or buttons.
* Remap Modals: Custom scenes for the remapping process.
* Dynamic Locking: Lock specific actions or slots at runtime.
* Custom Validators: Assign a Callable for deep validation logic.

--------------------------------------------------------------------------------

## Usage

### Setting Up the Plugin
1. Place the SmartInput folder in res://addons/smartinput/ or install it through Godot Asset Library.
2. Enable the plugin in Project Settings -> Plugins.
3. The InputController autoload will be created automatically.

### Creating your Controls
1. Right-click in your FileSystem -> New Resource -> InputActionsList.
2. Name it controls.tres.
3. Add actions to the Actions array. Choose "Press" for buttons or "Vector 2" for movement.
4. Assign this resource to the controller in your game's init script:
   ```gdscript
   func _ready():
       InputController.input_actions = load("res://controls.tres")
   ```

### Generating the Remap Menu
1. Create a VBoxContainer in your UI scene.
2. Add it to a Node Group named "SettingsMenu".
3. Call the population function whenever you open your menu or whenever the game loads:
   ```gdscript
   func _on_settings_opened():
       InputController.populate_group("SettingsMenu")
   ```

### Global Configuration
You can configure global defaults for the entire system in two ways. These methods are synchronized.

**Option A: User-Friendly Namespaces (via InputController)**
```gdscript
# Layout & Behavior
InputController.SettingsMenu.column_titles = ["KEYBOARD", "MOUSE", "GAMEPAD"]
InputController.SettingsMenu.show_search = false

# Global UI Templates (Theming)
InputController.SettingsMenu.keybind_scene_override = load("res://my_custom_keybind.tscn")
InputController.SettingsMenu.category_header_scene = load("res://my_header.tscn")

# Keybind Text
InputController.Keybind.remapping_text = "PRESS NOW..."
InputController.Keybind.unbound_text = "---"

# Default Action Settings (Applied to new resources)
InputController.InputAction.default_deadzone = 0.2
InputController.InputAction.category = "Gameplay"

# Icon Paths
InputController.InputIconLibrary.keyboard_icons_path = "res://assets/keys/"
```

**Option B: Direct Static Access (via InputConfig)**
```gdscript
InputConfig.menu_column_titles = ["K", "M", "J"]
InputConfig.action_deadzone = 0.1
```

### Script Access
For convenience, `InputController` exposes the plugin's resource scripts, making it easier to reference them without `preload` calls:
```gdscript
var new_list = InputController.InputActionsList.new()
var new_action = InputController.InputActionScript.new()
var new_lib = InputController.InputIconLibraryScript.new()
```

### Configuration Variable Reference
Below is the full list of configurable properties available via `InputController` namespaces (and their `InputConfig` static equivalents).

**SettingsMenu (InputConfig.menu_*)**
*   `show_search` (bool): Toggle search bar visibility.
*   `column_titles` (Array[String]): List of titles for the binding columns.
*   `label_stretch_ratio` (float): Horizontal size ratio for action labels.
*   `button_stretch_ratio` (float): Horizontal size ratio for binding buttons.
*   `search_placeholder` (String): Placeholder text for the search bar.
*   `restore_label` (String): Label for the "Restore Defaults" button.
*   `show_restore_defaults` (bool): Toggle visibility of the restore defaults button.
*   `keybind_scene_override` (PackedScene): Custom scene for individual keybind rows.
*   `category_header_scene` (PackedScene): Custom scene for category headers.
*   `action_header_scene` (PackedScene): Custom scene for vector action headers.
*   `column_header_scene` (PackedScene): Custom scene for the column title row.
*   `search_bar_scene` (PackedScene): Custom scene replacing the search LineEdit.
*   `footer_scene` (PackedScene): Custom scene replacing the footer area.

**Keybind (InputConfig.keybind_*)**
*   `remapping_text` (String): Text shown on a button while it is waiting for input.
*   `unbound_text` (String): Text shown on a button that has no binding.

**InputAction (InputConfig.action_*)**
*   `category` (String): Default category for new actions.
*   `deadzone` (float): Default deadzone for new actions.
*   `device_limit` (int): 0 = Both, 1 = Keyboard Only, 2 = Controller Only.
*   `up_display_name` (String): Default display name for "Up".
*   `down_display_name` (String): Default display name for "Down".
*   `left_display_name` (String): Default display name for "Left".
*   `right_display_name` (String): Default display name for "Right".
*   `up_suffix` (String): Default ID suffix for "Up" (e.g. "_up").
*   `down_suffix` (String): Default ID suffix for "Down" (e.g. "_down").
*   `left_suffix` (String): Default ID suffix for "Left" (e.g. "_left").
*   `right_suffix` (String): Default ID suffix for "Right" (e.g. "_right").

**InputIconLibrary (InputConfig.icon_*)**
*   `keyboard_icons_path` (String): Global default folder path for keyboard icons.
*   `mouse_icons_path` (String): Global default folder path for mouse icons.
*   `gamepad_icons_path` (String): Global default folder path for gamepad icons.

--------------------------------------------------------------------------------

## InputController API Reference

This is the main singleton used for logic and remapping management. It also acts as the central hub for global configuration via the `SettingsMenu`, `Keybind`, `InputAction`, and `InputIconLibrary` namespaces.

## Gameplay API (Static)
Use these in your Player or Camera scripts. They automatically handle UI suppression.

#### InputController.get_vector(id: String) -> Vector2
- Purpose: Gets movement or looking direction (WASD/Joystick).
- Usage: `var move = InputController.get_vector("move")`
- Detail: Returns Vector2.ZERO if the user is typing in a LineEdit or currently remapping a key.

#### InputController.is_held(id: String) -> bool
- Purpose: Checks if an action is currently being pressed.
- Usage: `if InputController.is_held("sprint"): run()`

#### InputController.is_just_pressed(id: String) -> bool
- Purpose: Checks if an action was hit this frame.
- Usage: `if InputController.is_just_pressed("jump"): jump()`

## Configuration API
Properties you can change via script to alter the system behavior.

#### InputController.save_path: String
- Default: "user://input_config.cfg"
- Purpose: Defines where the user's custom bindings are saved.
- Usage: `InputController.save_path = "user://profiles/player_1.cfg"`

#### InputController.use_pretty_names: bool
- Default: true
- Purpose: Converts generic indices (Joy 0) to friendly names (Button A).
- Usage: `InputController.use_pretty_names = false`

#### InputController.bindings_per_action: int
- Range: 1 to 3
- Purpose: Determines how many remapping columns are shown in the UI.
- Usage: `InputController.set_bindings_count(1)`

#### InputController.unbind_inputs: Array
- Default: [KEY_DELETE, MOUSE_BUTTON_RIGHT]
- Purpose: List of inputs that trigger an "Unbind" action instead of mapping.
- Usage: `InputController.unbind_inputs.append("U")`

#### InputController.show_conflicts: bool
- Default: true
- Purpose: If true, buttons with conflicting bindings will highlight red and show a tooltip.
- Usage: `InputController.show_conflicts = false`

#### InputController.modal_scene: PackedScene
- Purpose: Optional custom scene to handle the "Press any key" remapping event (replaces the simple button text change).
- Usage: `InputController.modal_scene = load("res://ui/remap_modal.tscn")`

#### InputController.keybind_scene: PackedScene
- Purpose: The default row scene used if no override is provided in `SettingsMenu`.
- Usage: `InputController.keybind_scene = load("res://ui/my_row.tscn")`

## Runtime Logic API
Functions to restrict or modify remapping behavior during gameplay.

#### lock_action(id: StringName, locked: bool, direction: String = "")
- Purpose: Disables an entire row in the menu. Locked rows cannot be clicked or focused.
- Usage: `InputController.lock_action("inventory", true)`

#### block_slot(id: StringName, index: int, blocked: bool, direction: String = "")
- Purpose: Disables a specific column for an action.
- Usage: `InputController.block_slot("move", 0, true) # Primary slot locked`

#### whitelist_inputs(id: StringName, list: Array, direction: String = "")
- Purpose: Only allow specific keys/buttons for an action. Rejects everything else.
- Usage: `InputController.whitelist_inputs("move", ["W", "A", "S", "D"], "up")`

#### blacklist_inputs(id: StringName, list: Array, direction: String = "")
- Purpose: Prevent specific keys from being bound to an action.
- Usage: `InputController.blacklist_inputs("jump", ["Escape", MOUSE_BUTTON_LEFT])`

#### validator_func: Callable
- Purpose: Assign a custom function for complex validation logic.
- Usage:
  ```gdscript
  InputController.validator_func = func(id, event, dir):
      return event is InputEventKey # Only allow keyboard for this action
  ```

--------------------------------------------------------------------------------

## SettingsMenu UI API Reference

Exports available on the VBoxContainer node (when added to the SettingsMenu group).

### Layout Configuration
- **label_stretch_ratio** (Float): Controls the horizontal width of the action name column. Default: 2.0.
- **button_stretch_ratio** (Float): Controls the horizontal width of each remapping button. Default: 1.0.

### Template Scenes
Inject your own scenes to change the UI look without touching core code. Your custom scenes should ideally have a `set_text(text: String)` method if they are headers.
- **category_header_scene**: Spawned for category titles (e.g., "GAMEPLAY").
- **action_header_scene**: Spawned for the base title of Vector2 actions.
- **column_header_scene**: Spawned for the "PRIMARY", "SECONDARY", etc. labels.
- **search_bar_scene**: Replaces the default LineEdit search bar.
- **footer_scene**: Replaces the default "Restore Defaults" button area.
- **keybind_scene_override**: Use a completely custom remapping row. Must implement `setup(id, label, direction)`.

### Localization & Strings
- **show_search** (Bool): Toggle the search bar visibility.
- **show_restore_defaults** (Bool): Toggle the default "RESTORE ALL DEFAULTS" button visibility.
- **search_placeholder** (String): Text shown in the empty search field.
- **restore_label** (String): Text shown on the restore defaults button.
- **column_titles** (Array[String]): List of strings for column headers (e.g., ["Key 1", "Key 2"]).

--------------------------------------------------------------------------------

## InputAction Resource Properties

Configuration available inside your .tres files for each individual action.

### Identity & Grouping
- **id**: The unique StringName used in code (e.g. "move", "jump").
- **display_name**: The user-friendly text shown in the menu (e.g. "Jump Action").
- **category**: The group name used to organize actions in the menu.

### Constraints & Locking
- **is_locked** (Bool): If true, the entire row is disabled and non-focusable in the UI.
- **blocked_indices** (Array[int]): A list of specific slot indices to disable (e.g., [0, 2] locks Primary and Tertiary).
- **custom_row_scene** (PackedScene): Assign a specific visual scene for this one action.
- **device_limit** (Enum): 
  - **Both**: Default. Any input allowed.
  - **Keyboard Only**: Rejects gamepad buttons/axes.
  - **Controller Only**: Rejects keyboard and mouse inputs.

### Vector Configuration (Vector2 Only)
- **Directional Suffixes**: The string appended to the ID for each direction (e.g., "up", "down").
- **Directional Display Names**: What the player sees for each direction (e.g., "Forward", "Backward").

--------------------------------------------------------------------------------

## Icon Library (InputIconLibrary)

A specialized resource for handling button glyphs automatically.

### Properties
- **keyboard_icons_path**: Path to folder containing icons named like "w.png", "space.png".
- **mouse_icons_path**: Path to folder containing icons named like "mouse_1.png".
- **gamepad_icons_path**: Path to folder containing icons named like "joy_button_0.png" or "joy_axis_0_plus.png".
- **manual_overrides**: A Dictionary mapping key names/indices to specific Texture2Ds.

### Automatic Naming Convention
To use the automatic folder loading, name your files using lowercase and underscores:
- **Keys**: `escape.png`, `page_up.png`, `w.png`.
- **Mouse**: `mouse_1.png`, `mouse_2.png`.
- **Gamepad Buttons**: `joy_button_0.png`.
- **Gamepad Axes**: `joy_axis_0_plus.png` (Right/Down) or `joy_axis_0_minus.png` (Left/Up).

--------------------------------------------------------------------------------

## Signals Reference

### InputController Signals
- **action_pressed(id)**: Emitted when a PRESS action is triggered.
- **action_released(id)**: Emitted when an action is released.
- **device_changed(is_controller)**: Emitted when the user switches input devices.
- **bindings_updated**: Emitted when keys are changed or defaults are restored.
- **request_menu_build**: Emitted to trigger a UI refresh across all menus.
- **remapping_started(id, index)**: Emitted when the remapping UI or modal opens.
- **remapping_finished(id, index, event)**: Emitted when the remapping is completed or cancelled.

--------------------------------------------------------------------------------

## FAQ

Q: How do I handle conflicts?
A: Enable `show_conflicts` on the InputController. Conflicting buttons will turn red and show a tooltip listing the other actions using that key.

Q: Where are the files saved?
A: User bindings are saved to the `save_path` (defaulting to `user://input_config.cfg`). This file is in Godot's ConfigFile format and can be manually edited.

Q: Can I use custom icons for specific keys only?
A: Yes. Use the `manual_overrides` dictionary in your `InputIconLibrary` resource to map specific key names to textures.

--------------------------------------------------------------------------------

## License
Boost Software License 1.0. You can use this in any project (commercial or personal) without giving credit in your final product. However, you must keep the original license and attribution within the source files.
