extends Control
class_name SPMeter

export var progressBar: NodePath
export var progressBarUnder: NodePath
export var progressBarGlow: NodePath
export var previewBar: NodePath
export var missingBar: NodePath
export var glowAnim: NodePath
export var previewAnim: NodePath
export var missingAnim: NodePath

onready var progressBarNode : TextureProgress = get_node_or_null(progressBar)
onready var progressBarUnderNode : TextureProgress = get_node_or_null(progressBarUnder)
onready var progressBarGlowNode : TextureProgress = get_node_or_null(progressBarGlow)
onready var previewBarNode: TextureProgress = get_node_or_null(previewBar)
onready var missingBarNode: TextureProgress = get_node_or_null(missingBar)
onready var glowAnimNode : AnimationPlayer = get_node_or_null(glowAnim)
onready var previewAnimNode : AnimationPlayer = get_node_or_null(previewAnim)
onready var missingAnimNode : AnimationPlayer = get_node_or_null(missingAnim)

var _tween: SceneTreeTween
var _sp := 0
var _encore_cost := 4
# encores can only be activated once it reaches a certain amount
const SP_MAX := 100
const NOTCH_STEP := 10

func _ready():
	_update_bar_instantly()

func get_filled_bars() -> int:
	return _sp / 10

func _set_bar_glow(enabled: bool) -> void:
	glowAnimNode.play("Glowing" if enabled else "NotGlowing")

func add_sp(amt: int, multiplied:= false) -> void:
	if multiplied: amt = _get_multiplied_amt(amt)
	_sp += amt
	_update_sp()

func remove_sp(amt: int, multiplied:= false) -> void:
	if multiplied: amt = _get_multiplied_amt(amt)
	_sp -= amt
	_update_sp()

func set_sp(amt: int) -> void:
	_sp = amt
	_update_sp()

func get_sp() -> int:
	return _sp

func _update_sp() -> void:
	_sp = int(max(0, min(_sp, SP_MAX)))
	_update_bar()

func _update_bar() -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween().set_parallel().set_ease(Tween.EASE_OUT)
	if progressBarNode.value < _sp:
		_tween.tween_property(progressBarUnderNode, "value", _sp, 0.3).set_trans(Tween.TRANS_QUART)
		_tween.tween_property(progressBarNode, "value", _sp, 0.6).set_trans(Tween.TRANS_SINE)
		_tween.tween_property(progressBarGlowNode, "value", _sp, 0.6).set_trans(Tween.TRANS_SINE)
		_tween.tween_property(previewBarNode, "value", _sp, 0.6).set_trans(Tween.TRANS_SINE)
	elif progressBarUnderNode.value > _sp:
		_tween.tween_property(progressBarUnderNode, "value", _sp, 0.6).set_trans(Tween.TRANS_SINE)
		_tween.tween_property(progressBarNode, "value", _sp, 0.3).set_trans(Tween.TRANS_QUART)
		_tween.tween_property(progressBarGlowNode, "value", _sp, 0.3).set_trans(Tween.TRANS_QUART)
		_tween.tween_property(previewBarNode, "value", _sp, 0.3).set_trans(Tween.TRANS_QUART)
	_set_bar_glow(_sp >= _get_multiplied_amt(_encore_cost))

func _update_bar_instantly() -> void:
	progressBarUnderNode.value = _sp
	progressBarNode.value = _sp
	progressBarGlowNode.value = _sp
	previewBarNode.value = _sp
	
	_set_bar_glow(_sp >= _get_multiplied_amt(_encore_cost))


func set_preview_sp(amt: int, guard_preview = false) -> void:
	var start_time: float = 0.0
	if missingAnimNode.current_animation == "Previewing":
		start_time = missingAnimNode.current_animation_position
	elif previewAnimNode.current_animation == "Previewing":
		start_time = previewAnimNode.current_animation_position
	elif glowAnimNode.current_animation == "Glowing":
		start_time = glowAnimNode.current_animation_position / 4
	clear_preview_sp()
	if _sp < amt and !guard_preview:
		missingBarNode.value = amt
		missingAnimNode.play("Previewing")
		missingAnimNode.seek(start_time)
	else:
		if guard_preview:
			previewBarNode.value = _sp + amt
		else:
			progressBarUnderNode.value = _sp - amt
			progressBarNode.value = _sp - amt
			progressBarGlowNode.value = _sp - amt
			previewBarNode.value = _sp
		
		previewAnimNode.play("Previewing")
		previewAnimNode.seek(start_time)
	
	if _sp - amt < _get_multiplied_amt(_encore_cost):
		_set_bar_glow(false)
	elif glowAnimNode.current_animation != "Glowing":
		_set_bar_glow(true)

func clear_preview_sp():
	_update_bar_instantly()
	previewBarNode.value = 0
	previewAnimNode.play("NotPreviewing")
	missingAnimNode.play("NotPreviewing")
	_set_bar_glow(_sp >= _get_multiplied_amt(_encore_cost))


func set_encore_cost(amt: int) -> void:
	_encore_cost = amt
	_update_sp()

func _get_multiplied_amt(amt) -> int:
	return amt * NOTCH_STEP
