extends Control

const WRIGGLE_PERIOD := 0.5
const TIME_BEFORE_WRIGGLE := 1

var _active := false
var _wriggle := false
var _ninten_bp: BattleParticipant
var _tween: SceneTreeTween
var _appearing_tween: SceneTreeTween
var _wriggling_tween: SceneTreeTween
var _battle_system
var _before_wriggle_time := 0.0
var _darkinator

func init(battle_system, party, darkinator):
	_darkinator = darkinator.duplicate()
	set_process(false)
	$Label.bbcode_text = TextTools.replace_text($Label.bbcode_text)
	$Label.modulate.a = 0.0; $Label.show()
	_battle_system = battle_system
	_battle_system.connect("battle_ended", self, "_unset_flag")
	for bp in party:
		if bp.character.get_name() == PartyMember.NINTEN:
			_ninten_bp = bp
			break
	
	global.connect("flags_updated", self, "_check_tutorial_flag")

func _process(delta: float):
	_battle_system.sp_meter.glowAnimNode.set_speed_scale(1 / Engine.time_scale)
	
	if _wriggle:
		if !_wriggling_tween or !_wriggling_tween.is_running():
			_wriggling_tween = create_tween().set_loops()
			_wriggling_tween.tween_property($Label, "rect_position:y", $Label.rect_position.y - 1, WRIGGLE_PERIOD)
			_wriggling_tween.tween_property($Label, "rect_position:y", $Label.rect_position.y, WRIGGLE_PERIOD)
		else:
			_wriggling_tween.set_speed_scale(1 / Engine.time_scale)
	
	if _appearing_tween and _appearing_tween.is_running():
		_appearing_tween.set_speed_scale(1 / Engine.time_scale)
		return
	
	_before_wriggle_time += delta / Engine.time_scale
	if _before_wriggle_time >= TIME_BEFORE_WRIGGLE:
		_before_wriggle_time = 0.0
		_appearing_tween = create_tween()
		_appearing_tween.tween_property($Label, "modulate:a", 1.0, 0.7)
		_appearing_tween.tween_callback(self, "set", ["_wriggle", true])

func _set_darkener():
	var control = Control.new()
	var parent = _battle_system.sp_meter.get_parent()
	parent.add_child(control)
	parent.move_child(control, parent.get_children().find(_battle_system.sp_meter))
	control.add_child(_darkinator)
	_darkinator.darken_bg()
	_darkinator.rect_position = Vector2.ONE * -1000
	_darkinator.rect_size = Vector2.ONE * 3000

func _check_tutorial_flag():
	if globaldata.flags.get("encore_tutorial"):
		_ninten_bp.connect("before_action", self, "_try_tutorial")

func _try_tutorial(action):
	if action.has_trait("guard") or _battle_system.sp_meter.get_sp() < _battle_system.SP_TYPE.ENCORE:
		return
	var yield_object = _battle_system
	var yield_signal = "battle_paused"
	var pause_sprite := true
	
	if action is _battle_system.SkillAction:
		match action.skill.get("action_type", ""):
			_battle_system.ActionType.DAMAGE:
				yield_object = _ninten_bp.get_sprite()
				yield_signal = "apply_damage"
			_battle_system.ActionType.STAT, _battle_system.ActionType.AILMENT, _battle_system.ActionType.OTHER:
				pause_sprite = false
	
	globaldata.flags["encore_tutorial"] = false
	_ninten_bp.disconnect("before_action", self, "_try_tutorial")
	_battle_system.connect("encore_activated", self, "_stop", ["", ""])
	_ninten_bp.connect("defeated", self, "_stop")
	_battle_system.pause_battle()
	if pause_sprite: _ninten_bp.get_sprite().pause_in_next_pause_frame()
	yield(yield_object, yield_signal)
	
	set_process(true)
	_active = true
	_tween = create_tween()
	_tween.tween_property(Engine, "time_scale", 0, 0.7).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	_tween.parallel().tween_callback(self, "_set_darkener").set_delay(0.55)

func _stop(_useless_needed_param, _useless_needed_param2):
	if _tween and _tween.is_running(): _tween.kill()
	Engine.time_scale = 1
	_battle_system.sp_meter.glowAnimNode.set_speed_scale(1)
	_unset_flag("")
	
	set_process(false)
	_battle_system.unpause_battle("")
	if _active:
		_ninten_bp.get_sprite().play("lookIntoYourSoul", true)
	_ninten_bp.get_sprite().resume()
	
	if _darkinator: _darkinator.queue_free()
	queue_free()

func _unset_flag(_param): # In case you manage to avoid the tutorial so it doesn't trigger in the following battles
	globaldata.flags["encore_tutorial"] = false
