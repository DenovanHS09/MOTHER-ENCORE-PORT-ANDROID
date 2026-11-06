extends Control

export (Array, NodePath) var _melodies

const MELODY_FLAGS = [
	"doll_melody",
	"canary_melody",
	"monkey_melody",
	"piano_melody",
	"cactus_melody",
	"dragon_melody",
	"eve_melody",
	"grave_melody",
]

const MELODY_FADE_IN_DURATION := 1.0
const MELODY_FADE_IN_INTERVAL := 0.5

func _ready():
	hide()
	for i in _melodies.size():
		var melody: MelodyAnim = get_node_or_null(_melodies[i]) as MelodyAnim
		if globaldata.flags.get(MELODY_FLAGS[i], false):
			melody.init_melody(true)
			melody.colorize()
			melody.modulate.a = 0
		else:
			melody.hide()

func play_anim():
	show()
	yield(get_tree().create_timer(1), "timeout")
	for i in _melodies:
		var melody = get_node_or_null(i)
		if melody.visible:
			var tween = create_tween()
			tween.tween_property(melody, "modulate:a", 1.0, 1.0)
			yield(get_tree().create_timer(MELODY_FADE_IN_DURATION + MELODY_FADE_IN_INTERVAL), "timeout")
