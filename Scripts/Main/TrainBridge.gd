extends Node2D

onready var animation = $AnimationPlayer
onready var train = $Objects/Path2D/PathFollow2D/Train/Camera2D

func _ready():
	animation.play("TrainMoveRight")
	global.get_player().camera.current = false
	train.current = true
	global.get_player().visible = false
