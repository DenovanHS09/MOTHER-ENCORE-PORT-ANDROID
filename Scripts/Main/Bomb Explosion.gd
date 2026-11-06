extends Area2D

func _ready():
	$AnimationPlayer.play("Explosion")
#	global.get_player().hit_stop(0.07, 0, true, 0.5)
#	global.start_slowmo(0.9, 0.1)
	global.currentCamera.shake_camera(8, 0.3, Vector2.ZERO)

func _on_Explosion_body_entered(body):
	if body is PartyObject:
		if !global.get_player().is_paused():
			body.damage(30, 5, self.global_position.direction_to(body.global_position) * 5)

func _on_AudioStreamPlayer2D_finished():
	queue_free()
