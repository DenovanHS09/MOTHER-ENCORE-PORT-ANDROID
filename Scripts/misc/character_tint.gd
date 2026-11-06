class_name CharacterTint
extends Node

signal changed_tint(color)

export (Array, NodePath) var sprite_paths := []

var _targets: Array = []
var _tint := Color.white

func _ready():
	_set_targets()

func _set_targets():
	for node_path in sprite_paths:
		var node = get_node_or_null(node_path)
		if node: _targets.append(node)

func connect_tint(character_tint: CharacterTint):
	connect("changed_tint", character_tint, "set_tint")
	character_tint.set_tint(_tint)

func set_tint(color: Color):
	_tint = color
	if !_targets: _set_targets()
	for node in _targets:
		node.self_modulate = _tint
	emit_signal("changed_tint", _tint)
