extends Control

onready var _fade = $CanvasLayer/Fade
onready var _door = $Objects/DoorToTitle
onready var _disclaimer1 = $CanvasLayer/VBoxContainer/Disclaimer1
onready var _disclaimer2 = $CanvasLayer/VBoxContainer/Disclaimer2

const DISCLAIMER1_TEXT = "DISCLAIMER_PART_1"
const DISCLAIMER2_TEXT = "DISCLAIMER_PART_2"

func _init():
	if OS.has_feature("dialogue_tester"):
		global.scene_transition.goto_scene("res://Maps/Testing/DialogueTester.tscn")

func _ready():
	_disclaimer1.bbcode_text = TextTools.replace_text(DISCLAIMER1_TEXT)
	_disclaimer2.bbcode_text = TextTools.replace_text(DISCLAIMER2_TEXT)
	global.get_player().pause(true)
	create_tween().tween_property(_fade, "modulate", Color.transparent, 3) \
			.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN_OUT)

func _input(event: InputEvent):
	if (!event is InputEventKey and !event is InputEventJoypadButton) or !event.pressed:
		return
	if OS.is_debug_build():
		for action in InputMap.get_actions():
			if (event is InputEventKey and event.is_action_pressed(action) and
					(action in ["ui_load", "ui_translate", "ui_F11", "ui_F12"] or event.alt)):
				return
	_door.enter()
