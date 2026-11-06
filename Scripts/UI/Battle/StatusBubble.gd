extends Control

const MAX_HEIGHT = 20.5

onready var bubble = $Bubble
export var fps = 5
export var loops_before_cycle = 4
var status = []
var index = 0

var t = 0.0
var frame = 0
var loops = 0

func _ready():
	bubble.hide()

func _process(delta: float):
	t += delta
	var frame_time = 1.0 / fps
	while t >= frame_time:
		t -= frame_time
		frame = (frame + 1) % (bubble.hframes * bubble.vframes)
		if frame == 0:
			loops += 1
			# Rotate status, if we have any
			if loops >= loops_before_cycle:
				loops = 0
				if !status.empty(): _rotate_status()
		bubble.frame_coords = Vector2(frame % bubble.hframes, frame / bubble.hframes)

func _set_status_shown(status_to_show: String):
	var dir = globaldata.get_ailment_data(status_to_show).get("status_bubble")
	bubble.texture = load("res://Graphics/UI/Battle/StatusBubble/" + dir + ".png")
	bubble.show()

func add_status(new_status: String):
	if status.has(new_status):
		return
	var ailment_info = globaldata.get_ailment_data(new_status)
	if ailment_info.get("status_bubble") and !ailment_info.get("hidden"):
		status.append(new_status)
		_set_status_shown(status[index])

func remove_status(new_status: String):
	if !status.has(new_status):
		return
	var i = status.find(new_status)
	status.remove(i)
	if status.empty():
		index = 0
		bubble.hide()
	elif i == index:
		index -= 1
		_rotate_status()

func _rotate_status():
	index = wrapi(index + 1, 0, status.size())
	_set_status_shown(status[index])

func get_height() -> int:
	return bubble.texture.get_height()
