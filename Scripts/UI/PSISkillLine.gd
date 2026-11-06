extends Control

const LEVEL_NAMES = "αβγΩ"

var _skill_name: String = ""
var _levels: Dictionary # key = level, value = selectable
var _box: HBoxContainer
var _name_label: Label
var _cursor

func init(skill, cursor):
	_box = $HBox
	_name_label = $Name
	_levels = {}
	_cursor = cursor

	name = skill.name
	_skill_name = skill.name
	_name_label.text = skill.name
	_name_label.modulate = uiManager.get_flavor_color(3)
	
	#reset levels
	for i in _box.get_child_count():
		var node = _box.get_child(i)
		node.text = ""
		node.hide()
	
	if !"level" in skill:
		add_level(0)
	else:
		add_level(skill.level, false)

func add_level(level: int, selectable: bool = true):
	_levels[level] = selectable
	_refresh_nodes()

func add_levels(levels: Array): # Unused
	for level in levels:
		_levels[level] = true
	_refresh_nodes()

func _refresh_nodes():
	var level_values = _levels.keys()
	level_values.sort()
	for i in level_values.size():
		var node = _box.get_child(i)
		if i < level_values.size():
			node.show()
		node.text = LEVEL_NAMES[level_values[i]]
		var selectable = _levels[level_values[i]]
		if selectable:
			node.modulate = Color.white
			_name_label.modulate = Color.white
		else:
			node.modulate = uiManager.get_flavor_color(3)
	
	if is_inside_tree():
		force_update_transform()

func get_hbox() -> HBoxContainer:
	return _box

func get_skill_name() -> String:
	return _skill_name

func get_selected_level() -> int:
	var level_values = _levels.keys()
	level_values.sort()
	return level_values[_cursor.cursor_index] if _cursor and _cursor.cursor_index < _levels.size() else -1
