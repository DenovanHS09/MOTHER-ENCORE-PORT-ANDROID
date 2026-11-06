extends Area2D
class_name Door

signal done
signal entered
signal moved_player

export var targetX := 0
export var targetY := 0
export var dir := Vector2.ZERO
export (String, "None", "M3/door_open.wav", "Stairs_Up.mp3", "Stairs_Down.mp3") var sound := "None"
export (String, "None", "Door_Short.mp3") var end_sound := "None"
export (String, "Fade", "Circle", "Circle Focus", "Circle Pop", "Cut") var transit_in_anim := "Fade"
export (String, "Fade", "Circle", "Circle Focus", "Circle Pop", "Cut") var transit_out_anim := "Fade"
export var transit_in_color := Color.black
export var transit_out_color := Color.black
export var fade_in_speed := 1.5
export var fade_out_speed := 1.5
export var fadeout_music_on_scene_change := true
export var fadeout_music_length := 0.8
export (String) var targetScene := ""
export (Array) var _target_scene_params := []
export var set_respawn := false
export var set_crumbs := false # Unused
export var unpause_player := true
export var show_player_after_warp := true
export (String) var flag_set := ""
export (bool) var set_flag_state := true

var _player = null

onready var _new_pos = $Position2D
onready var audio_player = $AudioStreamPlayer

func _on_Door_body_entered(body):
	if body != global.get_player() or global.entering_door:
		return
	global.get_player().pause(false, true)
	yield(get_tree(), "idle_frame")
	enter(body)

func enter(player := global.get_player()):
	if global.entering_door:
		return

	global.entering_door = true

	if uiManager.is_in_cutscene():
		return
	_player = player
	_set_flag()

	global.scene_transition.start_door_transition(self, _player)

func change_scene():
	global.add_persistent(self)
	global.scene_transition.goto_scene("res://Maps/" + targetScene + ".tscn", Vector2(targetX, targetY - 7), Vector2(0, 0), _target_scene_params)
	uiManager.clear_on_screen_enemies()

func goto_player():
	_player.global_position = _new_pos.global_position - Vector2(0, 7)
	emit_signal("moved_player")

func _set_flag():
	if flag_set != "" and globaldata.flags.has(flag_set):
		globaldata.flags[flag_set] = set_flag_state

#Ao oni spawner
func _special_guest(new_scene := true):
	var check_scene = global.currentScene
	if !check_scene.get_name() in ["Disclaimer", "Title screen", "SaveSelect", "Control", "Naming screen", "Introduction"]:
		var _special_guest = load("res://Nodes/Overworld/Enemies/AoOni.tscn").instance()
		if !new_scene:
			yield(self, "moved_player")
		check_scene.get_node("Objects").add_child(_special_guest)
