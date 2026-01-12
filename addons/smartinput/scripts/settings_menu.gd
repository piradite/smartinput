extends VBoxContainer


@export_group("Functionality")
@export var show_search: bool = true
@export var column_titles: Array[String] = ["PRIMARY", "SECONDARY", "TERTIARY"]

@export_group("Layout")
@export var label_stretch_ratio: float = 2.0
@export var button_stretch_ratio: float = 1.0

@export_group("Templates")
@export var keybind_scene_override: PackedScene
@export var category_header_scene: PackedScene
@export var action_header_scene: PackedScene
@export var column_header_scene: PackedScene
@export var search_bar_scene: PackedScene
@export var footer_scene: PackedScene

@export_group("Localization")
@export var search_placeholder: String = "Search actions..."
@export var restore_label: String = "RESTORE ALL DEFAULTS"

@export_group("Visibility")
@export var show_column_headers: bool = true
@export var show_category_headers: bool = true
@export var show_action_headers: bool = true
@export var show_separators: bool = true

var _search_query: String = ""
var _search_edit: LineEdit
var _rows_container: VBoxContainer
var _last_focused: Control


func _ready() -> void:
	if show_search:
		show_search = InputConfig.menu_show_search
	
	if column_titles == ["PRIMARY", "SECONDARY", "TERTIARY"]:
		column_titles = InputConfig.menu_column_titles
	
	if label_stretch_ratio == 2.0:
		label_stretch_ratio = InputConfig.menu_label_stretch_ratio
	
	if button_stretch_ratio == 1.0:
		button_stretch_ratio = InputConfig.menu_button_stretch_ratio
	
	if search_placeholder == "Search actions...":
		search_placeholder = InputConfig.menu_search_placeholder
	
	if restore_label == "RESTORE ALL DEFAULTS":
		restore_label = InputConfig.menu_restore_label
	
	show_column_headers = InputConfig.menu_show_column_headers
	show_category_headers = InputConfig.menu_show_category_headers
	show_action_headers = InputConfig.menu_show_action_headers
	show_separators = InputConfig.menu_show_separators

	if not keybind_scene_override and InputConfig.menu_keybind_scene_override:
		keybind_scene_override = InputConfig.menu_keybind_scene_override
	
	if not category_header_scene and InputConfig.menu_category_header_scene:
		category_header_scene = InputConfig.menu_category_header_scene
	
	if not action_header_scene and InputConfig.menu_action_header_scene:
		action_header_scene = InputConfig.menu_action_header_scene
	
	if not column_header_scene and InputConfig.menu_column_header_scene:
		column_header_scene = InputConfig.menu_column_header_scene
	
	if not search_bar_scene:
		if InputConfig.menu_search_bar_scene:
			search_bar_scene = InputConfig.menu_search_bar_scene
		else:
			search_bar_scene = load("res://addons/smartinput/ui/search.tscn")
	
	if not footer_scene and InputConfig.menu_footer_scene:
		footer_scene = InputConfig.menu_footer_scene
	
	add_to_group("SmartInputMenu")
	InputController.request_menu_build.connect(_build_menu)
	get_viewport().gui_focus_changed.connect(_on_focus_changed)
	
	var scroll = get_parent()
	if scroll is ScrollContainer:
		scroll.follow_focus = true
	
	_rows_container = VBoxContainer.new()
	_rows_container.size_flags_horizontal = SIZE_EXPAND_FILL
	add_child(_rows_container)
	_build_menu()


func _input(event: InputEvent) -> void:
	if not get_viewport().gui_get_focus_owner():
		if event.is_action_pressed("ui_up") or event.is_action_pressed("ui_down") or \
		   event.is_action_pressed("ui_left") or event.is_action_pressed("ui_right"):
			if _last_focused and _last_focused.is_inside_tree() and _last_focused.visible:
				_last_focused.grab_focus()
			elif _search_edit and _search_edit.visible:
				_search_edit.grab_focus()
			else:
				_focus_first_button()
			get_viewport().set_input_as_handled()


func _on_focus_changed(control: Control) -> void:
	if control and is_ancestor_of(control):
		_last_focused = control


func _build_menu() -> void:
	if InputConfig.menu_show_search != show_search:
		show_search = InputConfig.menu_show_search
	
	if show_search:
		if not _search_edit:
			_create_search_bar()
		else:
			if _search_edit is Control:
				_search_edit.show()
	else:
		if _search_edit:
			if _search_edit is Control:
				_search_edit.hide()
			_search_query = ""
	
	if not _rows_container:
		return
	
	for child in _rows_container.get_children(): 
		child.queue_free()
	
	if show_column_headers:
		_create_column_headers()
	
	var categories = InputController.get_categories()
	for category in categories:
		var actions = InputController.get_actions_in_category(category)
		var filtered = actions.filter(func(a):
			if InputController.is_action_hidden(a.id):
				return false
			var query = _search_query.to_lower()
			if query.is_empty():
				return true
			
			var d_name = InputController.get_display_name(a.id)
			if d_name.to_lower().contains(query) or str(a.id).to_lower().contains(query) or category.to_lower().contains(query):
				return true
			
			if a.behavior == InputAction.Behavior.VECTOR_2:
				if a.up_display_name.to_lower().contains(query) or \
				   a.down_display_name.to_lower().contains(query) or \
				   a.left_display_name.to_lower().contains(query) or \
				   a.right_display_name.to_lower().contains(query):
					return true
			
			if a.behavior == InputAction.Behavior.PRESS:
				var all_events = InputController.get_action_events(a.id)
				for i in range(min(all_events.size(), InputController.bindings_per_action)):
					var e = all_events[i]
					if e and _get_event_search_text(e).contains(query):
						return true
			elif a.behavior == InputAction.Behavior.VECTOR_2:
				for dir in ["up", "down", "left", "right"]:
					var all_events = InputController.get_vector_events(a.id, dir)
					for i in range(min(all_events.size(), InputController.bindings_per_action)):
						var e = all_events[i]
						if e and _get_event_search_text(e).contains(query):
							return true
			
			return false
		)
		
		if filtered.is_empty():
			continue
		
		if show_category_headers:
			_create_category_header(category)
		
		for action in filtered:
			if action.behavior == InputAction.Behavior.PRESS:
				_spawn_row(action.id, action.display_name)
			elif action.behavior == InputAction.Behavior.VECTOR_2:
				var query = _search_query.to_lower()
				var up_vis = not InputController.is_action_hidden(action.id, "up") and _is_row_search_match(action, "up", query, category)
				var down_vis = not InputController.is_action_hidden(action.id, "down") and _is_row_search_match(action, "down", query, category)
				var left_vis = not InputController.is_action_hidden(action.id, "left") and _is_row_search_match(action, "left", query, category)
				var right_vis = not InputController.is_action_hidden(action.id, "right") and _is_row_search_match(action, "right", query, category)
				
				if up_vis or down_vis or left_vis or right_vis:
					if show_action_headers:
						_create_action_header(action.display_name)
					if up_vis: _spawn_row(action.id, action.up_display_name, "up")
					if down_vis: _spawn_row(action.id, action.down_display_name, "down")
					if left_vis: _spawn_row(action.id, action.left_display_name, "left")
					if right_vis: _spawn_row(action.id, action.right_display_name, "right")
	
	_create_footer()


func _create_search_bar() -> void:
	var node = null
	if search_bar_scene:
		node = search_bar_scene.instantiate()
		add_child(node)
		_search_edit = node if node is LineEdit else node.find_child("*", true, false)
	else:
		_search_edit = LineEdit.new()
		_search_edit.placeholder_text = search_placeholder
		_search_edit.clear_button_enabled = true
		add_child(_search_edit)
		node = _search_edit
		
	move_child(node, 0)
	
	if _search_edit:
		var on_text_changed = func(t):
			_search_query = t
			_build_menu()
		_search_edit.text_changed.connect(on_text_changed)
		
		var on_gui_input = func(e):
			if e.is_action_pressed("ui_down"):
				_focus_first_button()
				get_viewport().set_input_as_handled()
		_search_edit.gui_input.connect(on_gui_input)


func _focus_first_button() -> void:
	for row in _rows_container.get_children():
		for child in row.get_children():
			if child is Button and child.focus_mode != Control.FOCUS_NONE:
				child.grab_focus()
				return


func _create_footer() -> void:
	if footer_scene:
		_rows_container.add_child(footer_scene.instantiate())
	elif InputController.show_restore_defaults and InputConfig.menu_show_restore_defaults:
		var btn = Button.new()
		btn.text = restore_label
		btn.pressed.connect(func(): InputController.restore_defaults())
		_rows_container.add_child(btn)


func _create_column_headers() -> void:
	if column_header_scene:
		_rows_container.add_child(column_header_scene.instantiate())
		return
	
	var header = HBoxContainer.new()
	var lbl_name = Label.new()
	lbl_name.text = " ACTION"
	lbl_name.size_flags_horizontal = SIZE_EXPAND_FILL
	lbl_name.size_flags_stretch_ratio = label_stretch_ratio
	header.add_child(lbl_name)
	
	for i in range(InputController.bindings_per_action):
		var lbl = Label.new()
		lbl.text = column_titles[i] if i < column_titles.size() else ""
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.size_flags_horizontal = SIZE_EXPAND_FILL
		header.add_child(lbl)
	
	_rows_container.add_child(header)


func _create_category_header(text: String) -> void:
	if category_header_scene:
		var node = category_header_scene.instantiate()
		if node.has_method("set_text"):
			node.set_text(text)
		_rows_container.add_child(node)
	else:
		if show_separators:
			_rows_container.add_child(HSeparator.new())
		var lbl = Label.new()
		lbl.text = text.to_upper()
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_rows_container.add_child(lbl)


func _create_action_header(text: String) -> void:
	if action_header_scene:
		var node = action_header_scene.instantiate()
		if node.has_method("set_text"):
			node.set_text(text)
		_rows_container.add_child(node)
	else:
		var lbl = Label.new()
		lbl.text = text
		_rows_container.add_child(lbl)


func _is_row_search_match(a: InputAction, dir: String, query: String, category: String) -> bool:
	if query.is_empty():
		return true
	if category.to_lower().contains(query):
		return true
	var d_name = InputController.get_display_name(a.id)
	if d_name.to_lower().contains(query) or str(a.id).to_lower().contains(query):
		return true
	if not dir.is_empty():
		var dir_name = a.get(dir + "_display_name")
		if dir_name.to_lower().contains(query):
			return true
	var events = InputController.get_action_events(a.id) if dir.is_empty() else InputController.get_vector_events(a.id, dir)
	for i in range(min(events.size(), InputController.bindings_per_action)):
		var e = events[i]
		if e and _get_event_search_text(e).contains(query):
			return true
	return false


func _spawn_row(id: StringName, label_text: String, direction: String = "") -> void:
	InputController._spawn_row(_rows_container, id, label_text, direction, keybind_scene_override)


func _get_event_search_text(e: InputEvent) -> String:
	return InputController.get_event_name(e).to_lower()


func _add_menu_spacer(thick: bool) -> void:
	var control = Control.new()
	control.custom_minimum_size.y = 10 if thick else 2
	_rows_container.add_child(control)