extends Node

export (NodePath) onready var animationPlayer = get_node(animationPlayer)
export (NodePath) onready var transition = get_node(transition)


signal done

func _ready():
	animationPlayer.play("Start")

#func update_bg_color():
#	if global.currentScene is AreaRoom:
#		blackBG.color = 

func set_color(color):
	var material = $Sprite.get_material()
	material.set_shader_param("NEWCOLOR", color)


func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "Start":
		queue_free()
		emit_signal("done")
