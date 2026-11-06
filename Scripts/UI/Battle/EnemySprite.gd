extends TextureRect
class_name EnemyBattleSprite

signal apply_damage
signal start_boss_defeat_flash

onready var _sprite = $Sprite
onready var _speech_bubble = $SpeechZIndex/SpeechBubble
onready var _stat_info_res = preload("res://Nodes/Ui/Battle/DebugStatInfo.tscn")

var _transition_tween: SceneTreeTween
var _static := false
var status_bubble: Control
var status_bubble_offset: Vector2
var stat_info = null

func _ready():
	rect_pivot_offset = rect_size/2
	set_speech_bubble_pos()
	$AnimationPlayer.play("appear")
	$AnimationPlayer.advance(0)
	$AnimationPlayer.stop()

func move(new_position: Vector2, transition: bool, callback: FuncRef, cb_params: Array):
	if transition:
		transition(new_position, callback, cb_params)
	else:
		rect_position = new_position
	move_status_bubble(new_position, transition)

func transition(new_position: Vector2, callback: FuncRef, cb_params: Array):
	if _transition_tween: _transition_tween.kill()
	_transition_tween = create_tween().set_parallel().set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	
	_transition_tween.tween_property(self, "rect_position", new_position, 0.4)
	_transition_tween.tween_callback(callback, "call_funcv", [cb_params]).set_delay(0.4)

func move_status_bubble(new_position: Vector2, transition: bool):
	var new_bubble_height = new_position.y + status_bubble_offset.y - status_bubble.get_height()
	var fixed_height = status_bubble.MAX_HEIGHT + status_bubble.get_height() - new_position.y
	if new_bubble_height >= status_bubble.MAX_HEIGHT:
		fixed_height = 24 - rect_size.y / 2
	
	if transition and _transition_tween:
		_transition_tween.tween_property(status_bubble, "rect_position:y", fixed_height, 0.4)
	else:
		status_bubble.rect_position.y = fixed_height

func get_sprite() -> Sprite:
	return _sprite

func get_speech_bubble() -> Control:
	return _speech_bubble

func set_texture(full_path):
	_sprite.texture = load(full_path)
	rect_size = _sprite.texture.get_size()
	_sprite.position = rect_size/2
	rect_pivot_offset = rect_size/2

func appear():
	rect_pivot_offset = rect_size/2
	$AnimationPlayer.play("appear")

func flash():
	$AnimationPlayer.play("flash")
	
func flash_psi():
	$AnimationPlayer.play("psiFlash")

func set_psi_flash_color(color: Color):
	var animation = $AnimationPlayer.get_animation("psiFlash")
	animation.track_set_key_value(0, 0, Color(color))

func disappear():
	$AnimationPlayer.play_backwards("appear")

func select(dark := false):
	material.set_shader_param("flash_color", Color.white if dark else Color.black)
	material.set_shader_param("glow_modifier", 0.25)

func deselect():
	material.set_shader_param("glow_modifier", 0.0)

func attack():
	var tween = create_tween().set_trans(Tween.TRANS_QUART)
	tween.tween_property(_sprite, "offset:y", -10, 0.1).set_ease(Tween.EASE_OUT)
	tween.tween_property(_sprite, "offset:y", _sprite.offset.y, 0.1).set_ease(Tween.EASE_IN)
	yield(tween, "finished")
	emit_signal("apply_damage")

func dodge():
	var movement := 8
	if (randi()%2+0) == 1: movement *= -1
	
	var tween = create_tween().set_trans(Tween.TRANS_QUART)
	tween.tween_property(self, "rect_position:x", rect_position.x + movement, 0.1).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "rect_position:x", rect_position.x, 0.1).set_ease(Tween.EASE_IN)

func hit():
	$AnimationPlayer.play("hit")

func flee():
	var dest_pos := - rect_size.x
	if rect_position.x + rect_size.x / 2 >= 160:
		dest_pos = 320 - dest_pos
	var duration := abs(dest_pos - rect_size.x) / 320
	
	create_tween().tween_property(self, "rect_position:x", dest_pos, duration) \
			.set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_OUT)

func defeat(boss := false, silent := false):
	if silent:
		print("hiding")
		hide()
	else:
		if boss: $AnimationPlayer.play("bossDefeat")
		else:
			$AnimationPlayer.play("defeat")
		$AnimationPlayer.connect("animation_finished", self, "hide", [], CONNECT_ONESHOT)

func shake(mag:= 1.0, length:= 0.4, interval:= 0.02):
	var shake = Shaker.new($Sprite, "offset")\
	.set_shake_magnitude(mag)\
	.set_shake_length(length)\
	.set_shake_interval(interval)\
	.set_shake_diminish(false).start()

func start_boss_defeat_flash():
	emit_signal("start_boss_defeat_flash")

func hide(anim := ""):
	.hide()

func is_static() -> bool:
	return _static

func set_speech_bubble_pos(dir := _speech_bubble.tail_pos * -1):
	var rect_size = _sprite.texture.get_size()
	match dir:
		Vector2.RIGHT:
			_speech_bubble.rect_position = Vector2(rect_size.x, rect_size.y/2)
		Vector2.LEFT:
			_speech_bubble.rect_position = Vector2(0, rect_size.y/2)
		Vector2.UP:
			_speech_bubble.rect_position = Vector2(rect_size.x/2, 0)
		Vector2.DOWN:
			_speech_bubble.rect_position = Vector2(rect_size.x/2, rect_size.y)
	_speech_bubble.set_tail(dir * -1)

func add_status_bubble(bubble: Control):
	status_bubble = bubble
	add_child(status_bubble)
	status_bubble_offset = Vector2(rect_size.x / 2, 24 - rect_size.y / 2)
	status_bubble.rect_position = status_bubble_offset
	move_status_bubble(rect_position, false)

func add_debug_stat_info(bp):
	stat_info = _stat_info_res.instance()
	add_child(stat_info)
	stat_info.set_bp_data(bp)
