# SmartInput
High-Flexibility Input Remapping Framework for Godot 4.5+

- Professional-grade input logic and UI generation.
- Decoupled architecture for maximum project flexibility.
- Full support for Keyboard, Mouse, and Gamepad hardware.

<div align = center><img src="icon.png" width="256"><br><br>

&ensp;[<kbd> <br> Usage <br> </kbd>](#Usage)&ensp;
&ensp;[<kbd> <br> Installation <br> </kbd>](#Installation)&ensp;
&ensp;[<kbd> <br> API Reference <br> </kbd>](#api-reference)&ensp;
&ensp;[<kbd> <br> Icon Library Guide <br> </kbd>](#icon-library-inputiconlibrary)&ensp;
&ensp;[<kbd> <br> FAQ <br> </kbd>](#FAQ)&ensp;
<br><br><br><br></div>

--------------------------------------------------------------------------------

## Requirements
* Godot 4.5+

## Features
* **Multi-Slot Mapping**: Support for up to 3 binding slots per action.
* **Vector2 Support**: Automated generation of directional sub-actions (WASD/Sticks).
* **Modifier Combos**: Native detection for Shift, Ctrl, Alt, and Meta combinations.
* **Visual Icons**: Optional icon library support for visual button prompts.
* **Whitelist/Blacklist**: Restrict remapping to specific keys or buttons.
* **Custom Validators**: Assign a Callable for deep validation logic.

--------------------------------------------------------------------------------

## Usage

### Setting Up the Plugin
1. Place the SmartInput folder in `res://addons/smartinput/`.
2. Enable the plugin in Project Settings -> Plugins.
3. The `InputController` autoload will be created automatically.

### Creating your Controls
1. Create a new `InputActionsList` resource (e.g., `controls.tres`).
2. Add actions to the `Actions` array. Choose **Press** for buttons or **Vector 2** for movement.
3. Assign this resource to the controller in your game's init script:
   ```gdscript
   func _ready():
       InputController.input_actions = load("res://controls.tres")
   ```

### Generating the Remap Menu
1. Create a `VBoxContainer` in your UI scene.
2. Add it to a Node Group named **"SettingsMenu"**.
3. Call the population function:
   ```gdscript
   InputController.populate_group("SettingsMenu")
   ```

--------------------------------------------------------------------------------

## API Reference

### Global Configuration
You can configure these via `InputController.Namespace.property` or `InputConfig.menu_property`.

#### SettingsMenu (UI Layout & Visibility)
*   `show_search` (bool): Toggle search bar visibility.
*   `search_placeholder` (String): Placeholder text for the search bar.
*   `column_titles` (Array[String]): Titles for the binding columns.
*   `show_column_headers` (bool): Toggle "ACTION PRIMARY..." header row.
*   `show_category_headers` (bool): Toggle category labels.
*   `show_action_headers` (bool): Toggle base titles for Vector2 actions.
*   `show_separators` (bool): Toggle HSeparators between categories.
*   `show_restore_defaults` (bool): Toggle visibility of the restore button.
*   `restore_label` (String): Text shown on the restore button.
*   `label_stretch_ratio` (float): Width ratio for action labels.
*   `button_stretch_ratio` (float): Width ratio for binding buttons.

#### UI Templates (Theming)
*   `keybind_scene_override` (PackedScene): Custom scene for individual keybind rows.
*   `category_header_scene` (PackedScene): Custom scene for category titles.
*   `action_header_scene` (PackedScene): Custom scene for vector action headers.
*   `column_header_scene` (PackedScene): Custom scene for the column title row.
*   `search_bar_scene` (PackedScene): Custom scene replacing the search bar.
*   `footer_scene` (PackedScene): Custom scene replacing the footer area.

#### Keybind & Action Defaults
*   `Keybind.remapping_text` (String): Text shown while waiting for input.
*   `Keybind.unbound_text` (String): Text shown for empty slots.
*   `InputAction.category` (String): Default category for new actions.
*   `InputAction.deadzone` (float): Default deadzone (0.5).
*   `InputAction.device_limit` (int): 0 = Both, 1 = Keyboard Only, 2 = Controller Only.

### InputController (Core Logic)
#### Gameplay API (Static)
*   `InputController.get_vector(id: String) -> Vector2`: Gets movement (WASD/Joystick).
*   `InputController.is_held(id: String) -> bool`: Checks if an action is pressed.
*   `InputController.is_just_pressed(id: String) -> bool`: Checks if an action was hit this frame.

#### Remapping Logic & State
*   `input_actions` (InputActionsList): The resource containing your action definitions.
*   `save_path` (String): Path for user bindings (default: `user://input_config.cfg`).
*   `use_pretty_names` (bool): Converts indices (Joy 0) to names (Button A).
*   `show_conflicts` (bool): Highlights conflicting bindings in red.
*   `unbind_inputs` (Array): Inputs that trigger an unbind (default: Delete/RightClick).
*   `set_bindings_count(int)`: Sets columns shown (1-3).
*   `restore_defaults()`: Resets all bindings to resource defaults.
*   `keybind_scene` (PackedScene): Global default row scene.
*   `modal_scene` (PackedScene): Optional scene for "Press any key" popup.
*   `icon_library` (Resource): Active `InputIconLibrary` resource.

#### Constraints & Runtime Control
*   `lock_action(id, locked, dir)`: Disables an entire row.
*   `block_slot(id, index, blocked, dir)`: Disables a specific column for an action.
*   `block_category(cat)` / `unblock_category(cat)`: Hides/disables an entire category.
*   `whitelist_inputs(id, list, dir)`: Only allow specific keys/buttons.
*   `blacklist_inputs(id, list, dir)`: Prevent specific keys from being bound.
*   `validator_func`: Custom validation: `func(id, event, dir) -> bool`.

--------------------------------------------------------------------------------

## InputAction Resource Properties
*   `id` (StringName): Unique action identifier.
*   `display_name` (String): User-friendly label.
*   `category` (String): Grouping for the menu.
*   `behavior` (Enum): **Press** or **Vector 2**.
*   `is_locked` (bool): Hard-lock the action in the UI.
*   `blocked_indices` (Array[int]): Indices of columns to disable.
*   `custom_row_scene` (PackedScene): Visual override for this specific action.
*   `device_limit` (Enum): Restrict hardware type for this action.

--------------------------------------------------------------------------------

## Icon Library (InputIconLibrary)
*   `keyboard_icons_path` (String): Folder for keyboard glyphs.
*   `mouse_icons_path` (String): Folder for mouse glyphs.
*   `gamepad_icons_path` (String): Folder for controller glyphs.
*   `manual_overrides` (Dictionary): Map specific key names to Texture2Ds.

### Automatic Naming Convention
Name files in lowercase using underscores (e.g., `space.png`, `mouse_1.png`, `joy_button_0.png`).

--------------------------------------------------------------------------------

## Signals Reference
- **action_pressed(id)** / **action_released(id)**
- **device_changed(is_controller)**: Emitted when hardware changes.
- **bindings_updated**: Emitted when keys change or defaults restored.
- **request_menu_build**: Triggers a UI refresh.
- **remapping_started(id, index)** / **remapping_finished(id, index, event)**

--------------------------------------------------------------------------------

## FAQ
**Q: How do I handle conflicts?**
A: Enable `show_conflicts` on the `InputController`. Conflicting buttons will turn red and show a tooltip listing other actions using that key.

**Q: Where are the files saved?**
A: User bindings are saved to the `save_path` defined in `InputController`.

--------------------------------------------------------------------------------

## License
Boost Software License 1.0. Use it in any project without credit, but keep the license in source files.