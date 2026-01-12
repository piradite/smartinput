extends HBoxContainer


@export var remapping_text: String = "..."
@export var unbound_text: String = "Unbound"

var action_id: StringName
var direction: String = ""
var is_remapping: bool = false
var current_remap_index: int = -1

var _buttons: Array[Button] = []


func _ready() -> void:
	if remapping_text == "...":
		remapping_text = InputConfig.keybind_remapping_text
	
	if unbound_text == "Unbound":
		unbound_text = InputConfig.keybind_unbound_text
	
	InputController.bindings_updated.connect(_update_buttons)
	
	var menu = get_parent_control()
	while menu and not "label_stretch_ratio" in menu:
		menu = menu.get_parent_control()
	
	$ActionName.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	$ActionName.size_flags_stretch_ratio = menu.label_stretch_ratio if menu else InputConfig.menu_label_stretch_ratio
	
	for child in get_children():
		if child is Button:
			_buttons.append(child)
			child.pressed.connect(_on_button_pressed.bind(_buttons.size() - 1))
			child.gui_input.connect(_on_button_gui_input.bind(_buttons.size() - 1))
			child.focus_entered.connect(_on_button_focused.bind(child))
			child.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			child.size_flags_stretch_ratio = menu.button_stretch_ratio if menu else InputConfig.menu_button_stretch_ratio
	
	set_process_input(false)


func setup(id: StringName, display_text: String, vector_dir: String = "") -> void:
	action_id = id
	direction = vector_dir
	$ActionName.text = display_text
	_update_buttons()


func _input(event: InputEvent) -> void:
	if not is_remapping:
		return
	
	if event is InputEventMouseMotion:
		return
	
	if event is InputEventWithModifiers:
		event.shift_pressed = Input.is_key_pressed(KEY_SHIFT)
		event.ctrl_pressed = Input.is_key_pressed(KEY_CTRL)
		event.alt_pressed = Input.is_key_pressed(KEY_ALT)
		event.meta_pressed = Input.is_key_pressed(KEY_META)
	
	if event.is_pressed():
		if event is InputEventKey and _is_pure_modifier(event):
			return
		
		get_viewport().set_input_as_handled()
		
		if event.is_action_pressed("ui_cancel"):
			_cancel_remap()
			return
		
		if InputController.is_event_in_list(event, InputController.unbind_inputs):
			_apply_remap_to_index(current_remap_index, null)
			return
		
		if InputController.is_valid_input(action_id, event, direction):
			_apply_remap_to_index(current_remap_index, event.duplicate())
	
	elif event is InputEventKey and _is_pure_modifier(event):
		get_viewport().set_input_as_handled()
		var e = event.duplicate()
		e.shift_pressed = false
		e.ctrl_pressed = false
		e.alt_pressed = false
		e.meta_pressed = false
		if InputController.is_valid_input(action_id, e, direction):
			_apply_remap_to_index(current_remap_index, e)


func _on_button_focused(child: Control) -> void:
	var scroll = get_parent_control()
	while scroll and not scroll is ScrollContainer:
		scroll = scroll.get_parent_control()
	
	if scroll:
		scroll.ensure_control_visible(child)


func _on_button_gui_input(event: InputEvent, index: int) -> void:
	if event.is_pressed() and InputController.is_event_in_list(event, InputController.unbind_inputs):
		if not InputController.is_index_locked(action_id, index, direction):
			get_viewport().set_input_as_handled()
			_apply_remap_to_index(index, null)


func _on_button_pressed(index: int) -> void:
	if InputController.is_remapping or InputController.is_index_locked(action_id, index, direction):
		return
	
	if InputController.modal_scene:
		_spawn_modal(index)
		return
	
	InputController.is_remapping = true
	is_remapping = true
	current_remap_index = index
	_buttons[index].text = remapping_text
	InputController.remapping_started.emit(action_id, index)
	
	for btn in _buttons:
		btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	await get_tree().process_frame
	set_process_input(true)
	_buttons[index].release_focus()


func _spawn_modal(index: int) -> void:
	var modal = InputController.modal_scene.instantiate()
	get_tree().root.add_child(modal)
	
	if modal.has_method("start_listening"):
		InputController.is_remapping = true
		var event = await modal.start_listening()
		
		if event != null:
			if InputController.is_event_in_list(event, InputController.unbind_inputs):
				_apply_remap_to_index(index, null)
			elif InputController.is_valid_input(action_id, event, direction):
				_apply_remap_to_index(index, event)
			else:
				_update_buttons()
		else:
			_update_buttons()
		
		InputController.is_remapping = false


func _is_pure_modifier(e: InputEventKey) -> bool:
	var modifiers = [KEY_SHIFT, KEY_CTRL, KEY_ALT, KEY_META, KEY_CAPSLOCK]
	return e.keycode in modifiers or e.physical_keycode in modifiers


func _apply_remap_to_index(index: int, event: InputEvent) -> void:
	if direction == "":
		InputController.remap_action(action_id, index, event)
	else:
		InputController.remap_vector(action_id, direction, index, event)
	
	InputController.remapping_finished.emit(action_id, index, event)
	InputController.save_config()
	_cleanup_remap()
	_update_buttons()


func _cancel_remap() -> void:
	_cleanup_remap()
	_update_buttons()


func _cleanup_remap() -> void:
	var target_btn = _buttons[current_remap_index] if current_remap_index != -1 else null
	is_remapping = false
	InputController.is_remapping = false
	current_remap_index = -1
	
	for btn in _buttons:
		btn.mouse_filter = Control.MOUSE_FILTER_STOP
	
	set_process_input(false)
	
	if target_btn and target_btn.is_inside_tree() and target_btn.visible:
		target_btn.grab_focus()


func _update_buttons() -> void:
	var events = InputController.get_action_events(action_id) if direction == "" else InputController.get_vector_events(action_id, direction)
	
	for i in range(_buttons.size()):
		var btn = _buttons[i]
		var is_blocked = InputController.is_index_locked(action_id, i, direction)
		btn.disabled = is_blocked
		btn.focus_mode = Control.FOCUS_NONE if is_blocked else Control.FOCUS_ALL
		
		if i >= InputController.bindings_per_action:
			btn.hide()
			continue
		
		btn.show()
		
		if i < events.size() and events[i] != null:
			_set_button_visuals(btn, events[i])
		else:
			btn.text = unbound_text
			btn.icon = null
		
		if InputController.show_conflicts and i < events.size() and events[i] != null:
			var c = InputController.find_conflicts(events[i])
			btn.modulate = Color(1, 0.3, 0.3) if c.size() > 1 else Color.WHITE
			btn.tooltip_text = "Conflict with: " + ", ".join(c) if c.size() > 1 else ""
		else:
			btn.modulate = Color.WHITE


func _set_button_visuals(btn: Button, e: InputEvent) -> void:
	var icon = InputController.get_event_icon(e)
	var mods = ""
	
	if e is InputEventWithModifiers:
		if e.ctrl_pressed: mods += "Ctrl+"
		if e.shift_pressed: mods += "Shift+"
		if e.alt_pressed: mods += "Alt+"
	
	if icon:
		btn.icon = icon
		btn.expand_icon = true
		btn.text = mods
	else:
		btn.icon = null
		btn.text = mods + InputController.get_event_name(e)