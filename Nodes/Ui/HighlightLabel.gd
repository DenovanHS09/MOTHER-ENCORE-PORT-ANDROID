extends Label


onready var _highlighter = get("custom_styles/normal")
var _old_color
var _old_modulate
var _tween: SceneTreeTween
var blinking := false
var equipped := false

var _width: int

func _ready():
	_width = rect_size.x
	_old_color = _highlighter.bg_color
	_old_modulate = self_modulate
	uiManager.connect("menu_flavor_updated", self, "_set_color")
	_highlighter = _highlighter.duplicate()
	self.set('custom_styles/normal', _highlighter)
	_set_color()
	highlight(0)

func set_text(new_text: String): # Special way of setting text that will send an error if a name is too long
	var size = rect_size.x
	text = new_text
	rect_size.x = 0 # Force the size to update
	if rect_size.x > _width:
		push_error("Text '%s' for label of name '%s' is too long." % [text, name])
	rect_size.x = size # Restore the original size

func _set_color():
	var highlight_value = _highlighter.bg_color.a
	for i in 5:
		if str(_old_modulate) == str(uiManager.get_flavor_color(i + 1, false)):
			self_modulate = uiManager.get_flavor_color(i + 1)
		if str(_old_color) == str(uiManager.get_flavor_color(i + 1, false)):
			_highlighter.bg_color = uiManager.get_flavor_color(i + 1)
	highlight(highlight_value)

func set_self_modulate(color: Color):
	self_modulate = color
	for i in 5:
		if str(color) == str(uiManager.get_flavor_color(i + 1, false)):
			self_modulate = uiManager.get_flavor_color(i + 1)

func highlight(val: float):
	_highlighter.bg_color.a = val
	if get_node_or_null("Equipped_spr"):
		$Equipped_spr.visible = false if val > 0 else equipped

func blink(val: bool):
	blinking = val
	if val: 
		_start_blinking()
		if get_node_or_null("Equipped_spr"):
			$Equipped_spr.hide()
	else:
		if _tween: _tween.kill()
		highlight(0)

func _start_blinking():
	if blinking and (!_tween or !_tween.is_running()):
		_tween = create_tween().set_loops().set_ease(Tween.EASE_IN_OUT)
		_tween.tween_property(_highlighter, "bg_color:a", 0.5, 0.3).from(0.8)
		_tween.tween_property(_highlighter, "bg_color:a", 0.8, 0.3)

func show_equipped(val: bool):
	if get_node_or_null("Equipped_spr"):
		equipped = val
		$Equipped_spr.visible = equipped
