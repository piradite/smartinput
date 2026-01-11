extends Node
signal action_pressed(action_id: StringName)
signal action_released(action_id: StringName)
signal device_changed(is_controller: bool)
signal bindings_updated
signal request_menu_build
signal remapping_started(action_id: StringName, index: int)
signal remapping_finished(action_id: StringName, index: int, event: InputEvent)

class KeybindProxy:
    var remapping_text: String:
        get: return InputConfig.keybind_remapping_text
        set(v): InputConfig.keybind_remapping_text = v
    var unbound_text: String:
        get: return InputConfig.keybind_unbound_text
        set(v): InputConfig.keybind_unbound_text = v

class SettingsMenuProxy:
    var show_search: bool:
        get: return InputConfig.menu_show_search
        set(v): InputConfig.menu_show_search = v
    var column_titles: Array:
        get: return InputConfig.menu_column_titles
        set(v): 
            var typed: Array[String] = []
            typed.assign(v)
            InputConfig.menu_column_titles = typed
    var label_stretch_ratio: float:
        get: return InputConfig.menu_label_stretch_ratio
        set(v): InputConfig.menu_label_stretch_ratio = v
    var button_stretch_ratio: float:
        get: return InputConfig.menu_button_stretch_ratio
        set(v): InputConfig.menu_button_stretch_ratio = v
    var search_placeholder: String:
        get: return InputConfig.menu_search_placeholder
        set(v): InputConfig.menu_search_placeholder = v
    var restore_label: String:
        get: return InputConfig.menu_restore_label
        set(v): InputConfig.menu_restore_label = v
    var show_restore_defaults: bool:
        get: return InputConfig.menu_show_restore_defaults
        set(v): InputConfig.menu_show_restore_defaults = v
    var show_column_headers: bool:
        get: return InputConfig.menu_show_column_headers
        set(v): InputConfig.menu_show_column_headers = v
    var show_category_headers: bool:
        get: return InputConfig.menu_show_category_headers
        set(v): InputConfig.menu_show_category_headers = v
    var show_action_headers: bool:
        get: return InputConfig.menu_show_action_headers
        set(v): InputConfig.menu_show_action_headers = v
    var show_separators: bool:
        get: return InputConfig.menu_show_separators
        set(v): InputConfig.menu_show_separators = v

    var keybind_scene_override: PackedScene:
        get: return InputConfig.menu_keybind_scene_override
        set(v): InputConfig.menu_keybind_scene_override = v
    var category_header_scene: PackedScene:
        get: return InputConfig.menu_category_header_scene
        set(v): InputConfig.menu_category_header_scene = v
    var action_header_scene: PackedScene:
        get: return InputConfig.menu_action_header_scene
        set(v): InputConfig.menu_action_header_scene = v
    var column_header_scene: PackedScene:
        get: return InputConfig.menu_column_header_scene
        set(v): InputConfig.menu_column_header_scene = v
    var search_bar_scene: PackedScene:
        get: return InputConfig.menu_search_bar_scene
        set(v): InputConfig.menu_search_bar_scene = v
    var footer_scene: PackedScene:
        get: return InputConfig.menu_footer_scene
        set(v): InputConfig.menu_footer_scene = v

class InputActionProxy:
    var category: String:
        get: return InputConfig.action_category
        set(v): InputConfig.action_category = v
    var deadzone: float:
        get: return InputConfig.action_deadzone
        set(v): InputConfig.action_deadzone = v
    var device_limit: int:
        get: return InputConfig.action_device_limit
        set(v): InputConfig.action_device_limit = v
    
    var up_display_name: String:
        get: return InputConfig.action_up_display_name
        set(v): InputConfig.action_up_display_name = v
    var down_display_name: String:
        get: return InputConfig.action_down_display_name
        set(v): InputConfig.action_down_display_name = v
    var left_display_name: String:
        get: return InputConfig.action_left_display_name
        set(v): InputConfig.action_left_display_name = v
    var right_display_name: String:
        get: return InputConfig.action_right_display_name
        set(v): InputConfig.action_right_display_name = v
        
    var up_suffix: String:
        get: return InputConfig.action_up_suffix
        set(v): InputConfig.action_up_suffix = v
    var down_suffix: String:
        get: return InputConfig.action_down_suffix
        set(v): InputConfig.action_down_suffix = v
    var left_suffix: String:
        get: return InputConfig.action_left_suffix
        set(v): InputConfig.action_left_suffix = v
    var right_suffix: String:
        get: return InputConfig.action_right_suffix
        set(v): InputConfig.action_right_suffix = v

class InputIconLibraryProxy:
    var keyboard_icons_path: String:
        get: return InputConfig.icon_keyboard_path
        set(v): InputConfig.icon_keyboard_path = v
    var mouse_icons_path: String:
        get: return InputConfig.icon_mouse_path
        set(v): InputConfig.icon_mouse_path = v
    var gamepad_icons_path: String:
        get: return InputConfig.icon_gamepad_path
        set(v): InputConfig.icon_gamepad_path = v

var Keybind = KeybindProxy.new()
var SettingsMenu = SettingsMenuProxy.new()
var InputAction = InputActionProxy.new()
var InputIconLibrary = InputIconLibraryProxy.new()

const InputActionScript = preload("res://addons/smartinput/scripts/input_action.gd")
const InputActionsListScript = preload("res://addons/smartinput/scripts/input_actions_list.gd")
const InputIconLibraryScript = preload("res://addons/smartinput/scripts/input_icon_library.gd")
const InputActionsList = InputActionsListScript

@export var input_actions: InputActionsList:
    set(value):
        input_actions = value
        if is_inside_tree(): _initialize_bindings()
@export var save_path: String = "user://input_config.cfg"
@export var keybind_scene: PackedScene
@export var modal_scene: PackedScene
@export var icon_library: Resource
@export var show_conflicts: bool = true
@export var use_pretty_names: bool = true
@export var show_restore_defaults: bool = true
@export var unbind_inputs: Array = [KEY_DELETE, MOUSE_BUTTON_RIGHT]
@export_range(1, 3) var bindings_per_action: int = 3
var is_remapping: bool = false
var is_controller: bool = false
var _action_map: Dictionary = {}
var _blocked_categories: Array[String] = []
var _runtime_locks: Dictionary = {}
var _runtime_slot_blocks: Dictionary = {}
var _whitelists: Dictionary = {}
var _blacklists: Dictionary = {}
var validator_func: Callable
func _ready():
    if not keybind_scene: keybind_scene = load("res://addons/smartinput/ui/keybind.tscn")
    _initialize_bindings()
func _initialize_bindings():
    if not input_actions: return
    _action_map.clear()
    for res in input_actions.actions:
        if not res or res.id == &"": continue
        _action_map[res.id] = res
        if res.behavior == InputActionScript.Behavior.PRESS:
            _register(res.id, res.events)
        elif res.behavior == InputActionScript.Behavior.VECTOR_2:
            _register(res.id + "_" + res.up_suffix, res.up, res.deadzone)
            _register(res.id + "_" + res.down_suffix, res.down, res.deadzone)
            _register(res.id + "_" + res.left_suffix, res.left, res.deadzone)
            _register(res.id + "_" + res.right_suffix, res.right, res.deadzone)
    load_config()
    bindings_updated.emit()
func lock_action(id: StringName, locked: bool, direction: String = ""):
    var key = str(id) + (":" + direction if not direction.is_empty() else "")
    _runtime_locks[key] = locked
    bindings_updated.emit()
func block_slot(id: StringName, index: int, blocked: bool, direction: String = ""):
    var key = str(id) + (":" + direction if not direction.is_empty() else "")
    if not key in _runtime_slot_blocks: _runtime_slot_blocks[key] = []
    if blocked:
        if not index in _runtime_slot_blocks[key]: _runtime_slot_blocks[key].append(index)
    else:
        _runtime_slot_blocks[key].erase(index)
    bindings_updated.emit()
func whitelist_inputs(id: StringName, list: Array, direction: String = ""):
    var key = str(id) + (":" + direction if not direction.is_empty() else "")
    _whitelists[key] = list
func blacklist_inputs(id: StringName, list: Array, direction: String = ""):
    var key = str(id) + (":" + direction if not direction.is_empty() else "")
    _blacklists[key] = list
func is_index_locked(id: StringName, index: int, direction: String = "") -> bool:
    var res = _action_map.get(id)
    if not res: return false
    if res.is_locked: return true
    if index in res.blocked_indices: return true
    var base_key = str(id); var dir_key = str(id) + ":" + direction if not direction.is_empty() else ""
    if _runtime_locks.get(base_key, false): return true
    if not dir_key.is_empty() and _runtime_locks.get(dir_key, false): return true
    if id in _runtime_slot_blocks and index in _runtime_slot_blocks[id]: return true
    if not dir_key.is_empty() and dir_key in _runtime_slot_blocks and index in _runtime_slot_blocks[dir_key]: return true
    return false
func populate_group(group_name: String):
    for node in Engine.get_main_loop().get_nodes_in_group(group_name):
        if node is VBoxContainer: _build_menu_in_container(node)
    request_menu_build.emit()
func _build_menu_in_container(container: VBoxContainer):
    for child in container.get_children(): child.queue_free()
    var rows = VBoxContainer.new(); rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL; container.add_child(rows)
    
    if InputConfig.menu_show_column_headers:
        var header = HBoxContainer.new(); var lbl_name = Label.new(); lbl_name.text = " ACTION"; lbl_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL; lbl_name.size_flags_stretch_ratio = 2.0; header.add_child(lbl_name)
        for i in range(bindings_per_action):
            var lbl = Label.new(); lbl.text = ["PRIMARY", "SECONDARY", "TERTIARY"][i]; lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL; header.add_child(lbl)
        rows.add_child(header)
    
    for category in get_categories():
        if InputConfig.menu_show_category_headers:
            if InputConfig.menu_show_separators: rows.add_child(HSeparator.new())
            var cat_lbl = Label.new(); cat_lbl.text = category.to_upper(); cat_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; rows.add_child(cat_lbl)
        
        for action in get_actions_in_category(category):
            if action.behavior == InputActionScript.Behavior.PRESS: _spawn_row(rows, action.id, action.display_name)
            else:
                if InputConfig.menu_show_action_headers:
                    var act_lbl = Label.new(); act_lbl.text = action.display_name; rows.add_child(act_lbl)
                _spawn_row(rows, action.id, action.up_display_name, "up")
                _spawn_row(rows, action.id, action.down_display_name, "down")
                _spawn_row(rows, action.id, action.left_display_name, "left")
                _spawn_row(rows, action.id, action.right_display_name, "right")
    
    if show_restore_defaults and InputConfig.menu_show_restore_defaults:
        var btn = Button.new(); btn.text = "RESTORE ALL DEFAULTS"; btn.pressed.connect(func(): restore_defaults()); rows.add_child(btn)
func _spawn_row(container: VBoxContainer, id: StringName, label: String, dir: String = "", scene_override: PackedScene = null):
    var res = _action_map.get(id)
    var scene = scene_override
    if not scene and res and res.custom_row_scene: scene = res.custom_row_scene
    if not scene: scene = keybind_scene
    if not scene: return
    var row = scene.instantiate()
    container.add_child(row)
    if row.has_method("setup"): row.setup(id, label, dir)
func _register(name: StringName, events: Array, deadzone: float = 0.5):
    if not InputMap.has_action(name): InputMap.add_action(name, deadzone)
    InputMap.action_erase_events(name); for e in events: if e: InputMap.action_add_event(name, e)
func _input(event):
    var was_controller = is_controller
    if event is InputEventKey or event is InputEventMouseButton: is_controller = false
    elif event is InputEventJoypadButton or event is InputEventJoypadMotion: is_controller = true
    if was_controller != is_controller: device_changed.emit(is_controller)
func _unhandled_input(event):
    for id in _action_map:
        if is_action_blocked(id): continue
        var res = _action_map[id]
        if res.behavior == InputActionScript.Behavior.PRESS:
            if event.is_action_pressed(id): action_pressed.emit(id)
            elif event.is_action_released(id): action_released.emit(id)
func populate_menus(): request_menu_build.emit()
func set_bindings_count(count: int): bindings_per_action = clampi(count, 1, 3); bindings_updated.emit()
func is_valid_input(action_id: StringName, event: InputEvent, direction: String = "") -> bool:
    var res = _action_map.get(action_id)
    if res:
        if res.device_limit == InputActionScript.DeviceRequirement.KEYBOARD_ONLY and (event is InputEventJoypadButton or event is InputEventJoypadMotion): return false
        if res.device_limit == InputActionScript.DeviceRequirement.CONTROLLER_ONLY and (event is InputEventKey or event is InputEventMouseButton): return false
    var base_key = str(action_id); var dir_key = str(action_id) + ":" + direction if not direction.is_empty() else ""
    var wl = _whitelists.get(dir_key, _whitelists.get(base_key))
    if wl != null and not is_event_in_list(event, wl): return false
    var bl = _blacklists.get(dir_key, _blacklists.get(base_key))
    if bl != null and is_event_in_list(event, bl): return false
    if validator_func.is_valid():
        if validator_func.get_argument_count() == 3: return validator_func.call(action_id, event, direction)
        else: return validator_func.call(action_id, event)
    return true
func is_event_in_list(event: InputEvent, list: Array) -> bool:
    for item in list:
        if item is int:
            if event is InputEventKey:
                if event.keycode == item or event.physical_keycode == item: return true
            elif event is InputEventMouseButton or event is InputEventJoypadButton:
                if event.button_index == item: return true
        elif item is String:
            var text = ""
            if event is InputEventKey: text = OS.get_keycode_string(event.physical_keycode if event.physical_keycode != KEY_NONE else event.keycode)
            elif event is InputEventMouseButton: text = "Mouse Button " + str(event.button_index)
            else: text = event.as_text()
            if text.to_lower() == item.to_lower(): return true
    return false
func get_event_icon(event: InputEvent) -> Texture2D:
    if icon_library and icon_library.has_method("get_icon"): return icon_library.get_icon(event)
    return null
func remap_action(id: StringName, index: int, new_event: InputEvent):
    var res = _action_map.get(id)
    if not res or is_index_locked(id, index): return
    if res.events.size() <= index: res.events.resize(index + 1)
    res.events[index] = new_event; _rebuild_input_map(id, res.events)
func remap_vector(id: StringName, direction: String, index: int, new_event: InputEvent):
    var res = _action_map.get(id)
    if not res or is_index_locked(id, index, direction): return
    var arr = _get_vector_array(res, direction)
    if arr.size() <= index: arr.resize(index + 1)
    arr[index] = new_event; _rebuild_input_map(id + "_" + _get_suffix(res, direction), arr)
func _rebuild_input_map(action_name: StringName, events: Array):
    InputMap.action_erase_events(action_name); for e in events: if e: InputMap.action_add_event(action_name, e)
func restore_defaults():
    if FileAccess.file_exists(save_path): DirAccess.remove_absolute(save_path)
    if input_actions: input_actions = ResourceLoader.load(input_actions.resource_path, "", ResourceLoader.CACHE_MODE_REPLACE); _initialize_bindings()
func save_config():
    var config = ConfigFile.new()
    for id in _action_map:
        var res = _action_map[id]
        if res.behavior == InputActionScript.Behavior.PRESS: config.set_value("bindings", id, res.events)
        else:
            config.set_value("bindings", id + "_" + res.up_suffix, res.up); config.set_value("bindings", id + "_" + res.down_suffix, res.down)
            config.set_value("bindings", id + "_" + res.left_suffix, res.left); config.set_value("bindings", id + "_" + res.right_suffix, res.right)
    config.save(save_path)
func load_config():
    var config = ConfigFile.new(); if config.load(save_path) != OK: return
    for id in _action_map:
        var res = _action_map[id]
        if res.behavior == InputActionScript.Behavior.PRESS and config.has_section_key("bindings", id):
            res.events = config.get_value("bindings", id); _rebuild_input_map(id, res.events)
        elif res.behavior == InputActionScript.Behavior.VECTOR_2:
            res.up = config.get_value("bindings", id + "_" + res.up_suffix, res.up); res.down = config.get_value("bindings", id + "_" + res.down_suffix, res.down)
            res.left = config.get_value("bindings", id + "_" + res.left_suffix, res.left); res.right = config.get_value("bindings", id + "_" + res.right_suffix, res.right)
            _rebuild_input_map(id + "_" + res.up_suffix, res.up); _rebuild_input_map(id + "_" + res.down_suffix, res.down)
            _rebuild_input_map(id + "_" + res.left_suffix, res.left); _rebuild_input_map(id + "_" + res.right_suffix, res.right)
func find_conflicts(event: InputEvent) -> Array[String]:
    var conflicts: Array[String] = []; for action in InputMap.get_actions():
        if action.begins_with("ui_"): continue
        if InputMap.action_has_event(action, event): conflicts.append(get_display_name(action))
    return conflicts
func get_display_name(id: StringName) -> String:
    var res = _action_map.get(id); if res: return res.display_name if not res.display_name.is_empty() else str(id).capitalize()
    var s_id = str(id); if "_" in s_id:
        for base_id in _action_map:
            var base_s = str(base_id); if s_id.begins_with(base_s + "_"):
                var action = _action_map[base_id]; if action.behavior == InputActionScript.Behavior.VECTOR_2:
                    var suffix = s_id.trim_prefix(base_s + "_"); var dn = ""
                    if suffix == action.up_suffix: dn = action.up_display_name
                    elif suffix == action.down_suffix: dn = action.down_display_name
                    elif suffix == action.left_suffix: dn = action.left_display_name
                    elif suffix == action.right_suffix: dn = action.right_display_name
                    if not dn.is_empty():
                        var bn = action.display_name if not action.display_name.is_empty() else base_s.capitalize()
                        return bn + " (" + dn + ")"
    return s_id.capitalize()
func _get_vector_array(res: InputAction, dir: String) -> Array[InputEvent]:
    match dir:
        "up": return res.up
        "down": return res.down
        "left": return res.left
        "right": return res.right
    return []
func _get_suffix(res: InputAction, dir: String) -> String:
    match dir:
        "up": return res.up_suffix
        "down": return res.down_suffix
        "left": return res.left_suffix
        "right": return res.right_suffix
    return ""
func get_categories() -> Array[String]:
    var cats: Array[String] = []; for id in _action_map: if not _action_map[id].category in cats: cats.append(_action_map[id].category)
    return cats
func get_actions_in_category(cat: String) -> Array[InputAction]:
    var list: Array[InputAction] = []; for id in _action_map: if _action_map[id].category == cat: list.append(_action_map[id])
    return list
func get_action_events(id: StringName) -> Array: var res = _action_map.get(id); return res.events if res else []
func get_vector_events(id: StringName, dir: String) -> Array: var res = _action_map.get(id); return _get_vector_array(res, dir) if res else []
func block_category(c: String): if not c in _blocked_categories: _blocked_categories.append(c)
func unblock_category(c: String): _blocked_categories.erase(c)
func is_action_blocked(id: StringName) -> bool:
    var res = _action_map.get(id); return res.category in _blocked_categories if res else false
static func get_vector(id: String) -> Vector2:
    var node = Engine.get_main_loop().root.get_node_or_null("InputController")
    if not node or _is_input_suppressed(id) or not id in node._action_map: return Vector2.ZERO
    var res = node._action_map[id]; return Input.get_vector(id + "_" + res.left_suffix, id + "_" + res.right_suffix, id + "_" + res.up_suffix, id + "_" + res.down_suffix)
static func is_held(id: String) -> bool: return false if _is_input_suppressed(id) else Input.is_action_pressed(id)
static func is_just_pressed(id: String) -> bool: return false if _is_input_suppressed(id) else Input.is_action_just_pressed(id)
static func _is_input_suppressed(id: StringName) -> bool:
    var root = Engine.get_main_loop().root; var node = root.get_node_or_null("InputController")
    if not node or node.is_remapping or node.is_action_blocked(id): return true
    var focus = root.get_viewport().gui_get_focus_owner(); return focus and (focus is LineEdit or focus is TextEdit)
