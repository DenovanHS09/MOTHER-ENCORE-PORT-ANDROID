extends Node2D

export (String) var music
export (String) var loop

func _ready():
	if loop != "":
		globaldata.musicLoop = loop 
	else:
		globaldata.musicLoop = null
	
	if music != null:
		
		global.play_music(music)
