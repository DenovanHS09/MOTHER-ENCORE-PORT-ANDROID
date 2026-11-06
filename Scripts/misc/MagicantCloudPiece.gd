extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
export var amplitude: float = 5
export var frequency: float = 2
export var max_offset: float = 5
var init_x: float
var offset: float
var base_offset_x: float
var time_elapsed: float

func _ready():
	randomize()
	$Sprite.offset.y = rand_range(-(max_offset), max_offset);
	#randomize()
	#base_offset_x = rand_range(-(max_offset), max_offset);
	offset = rand_range(0, TAU)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	time_elapsed += delta
	var new_x = init_x + sin(time_elapsed * frequency + offset) * amplitude
	$Sprite.offset.x = new_x + base_offset_x
