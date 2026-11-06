extends Node2D

export var object_path: NodePath = ""
export (Array, NodePath) var exclude_paths := []
export var tint_color := Color.white setget _set_tint
export var on_flag := ""
export var off_flag := ""

var _targets: Array = []
var _exclude_targets: Array = []

func _ready():
	yield(get_tree(), "idle_frame")
	for path in exclude_paths:
		var node = get_node_or_null(path)
		if node: _exclude_targets.append(node)
	var object_node = get_node_or_null(object_path)
	if object_node == global.currentScene:
		for i in global.partyObjects:
			_targets.append(_get_tinter_or_null(i))
	_collect_targets(object_node)
	_check_flags()
	object_node.connect("child_entered_tree", self, "_on_child_entered_tree")
	global.connect("flags_updated", self, "_check_flags")
	connect("tree_exiting", self, "_untint")

func _set_tint(value: Color):
	tint_color = value
	_check_flags()

func _check_flags():
	if on_flag != "" and !globaldata.flags[on_flag]:
		return
	var flag_state = globaldata.check_appear_disappear_flags(on_flag, off_flag)
	if flag_state:
		_tint()
	else:
		_untint()

func _collect_targets(node: Node):
	if node in _exclude_targets: return
	var node_to_append = node
	var tinter = _get_tinter_or_null(node)
	if tinter != null:
		node_to_append = tinter
		_targets.append(node_to_append)
	elif node is Sprite:
		_targets.append(node_to_append)
	else:
		for child in node.get_children():
			_collect_targets(child)

func _tint():
	for target in _targets:
		_tint_individual(target)

func _untint():
	for target in _targets:
		if !is_instance_valid(target): continue
		if target is CharacterTint:
			target.set_tint(Color.white)
		elif target is Sprite:
			target.modulate = Color.white

func _tint_individual(target: Node):
	if !is_instance_valid(target): return
	if target is CharacterTint:
		target.set_tint(tint_color)
	elif target is Sprite:
		target.modulate = tint_color

func _get_tinter_or_null(node: Node) -> Node:
	for child in node.get_children():
		if child is CharacterTint:
			return child
	return null

func _on_child_entered_tree(child: Node):
	if child in _exclude_targets: return
	if !globaldata.check_appear_disappear_flags(on_flag, off_flag): return
	var tinter = _get_tinter_or_null(child)
	if tinter != null:
		_targets.append(tinter)
		_tint_individual(tinter)
	elif child is Sprite:
		_targets.append(child)
		_tint_individual(child)
