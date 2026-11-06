extends CanvasLayer
# Controles tactiles v2 para MOTHER: Encore (Godot 3.6)
# Maneja los toques por su cuenta y emula el TECLADO real del juego
# (Z, X, C, flechas), ademas de las acciones del Input Map.

# [accion, texto, tecla, x, y, ancho, alto]  (pantalla virtual 320x180)
const BUTTONS = [
	["ui_up", "^", KEY_UP, 28, 100, 24, 24],
	["ui_left", "<", KEY_LEFT, 4, 124, 24, 24],
	["ui_right", ">", KEY_RIGHT, 52, 124, 24, 24],
	["ui_down", "v", KEY_DOWN, 28, 148, 24, 24],
	["ui_accept", "Z", KEY_Z, 288, 128, 26, 26],
	["ui_cancel", "X", KEY_X, 258, 146, 26, 26],
	["ui_select", "C", KEY_C, 258, 112, 26, 26],
	["ui_map", "M", 16777218, 292, 4, 24, 16],
]

var rects = []
var panels = []
var pressed = []
var touches = {}
var debug_label


func _ready():
	layer = 100
	pause_mode = PAUSE_MODE_PROCESS
	for b in BUTTONS:
		var r = Rect2(b[3], b[4], b[5], b[6])
		rects.append(r)
		pressed.append(false)
		var panel = ColorRect.new()
		panel.rect_position = r.position
		panel.rect_size = r.size
		panel.color = Color(1, 1, 1, 0.25)
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(panel)
		var lbl = Label.new()
		lbl.text = b[1]
		lbl.rect_size = r.size
		lbl.align = Label.ALIGN_CENTER
		lbl.valign = Label.VALIGN_CENTER
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(lbl)
		panels.append(panel)
	# Texto de diagnostico (arriba a la izquierda). Borra estas 5 lineas cuando todo funcione.
	debug_label = Label.new()
	debug_label.rect_position = Vector2(2, 2)
	debug_label.text = "touch: -"
	debug_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(debug_label)


func _input(event):
	if event is InputEventScreenTouch:
		var p = _to_virtual(event.position)
		if event.pressed:
			debug_label.text = "raw " + str(int(event.position.x)) + "," + str(int(event.position.y)) + " -> " + str(int(p.x)) + "," + str(int(p.y))
			_touch(event.index, p)
		else:
			_release_finger(event.index)
	elif event is InputEventScreenDrag:
		_touch(event.index, _to_virtual(event.position))


# Si el toque llega en pixeles reales de pantalla (fuera del rango 320x180),
# lo convierte a la pantalla virtual del juego.
func _to_virtual(pos):
	if pos.x > 330 or pos.y > 190:
		var win = OS.window_size
		var s = min(win.x / 320.0, win.y / 180.0)
		var off = (win - Vector2(320, 180) * s) / 2
		return (pos - off) / s
	return pos


func _touch(index, pos):
	var hit = -1
	for i in range(rects.size()):
		if rects[i].has_point(pos):
			hit = i
			break
	var prev = touches.get(index, -1)
	if hit == prev:
		return
	if prev != -1:
		_set_pressed(prev, false)
		touches.erase(index)
	if hit != -1:
		touches[index] = hit
		_set_pressed(hit, true)


func _release_finger(index):
	if touches.has(index):
		_set_pressed(touches[index], false)
		touches.erase(index)


func _set_pressed(i, down):
	if pressed[i] == down:
		return
	pressed[i] = down
	panels[i].color = Color(1, 1, 1, 0.6) if down else Color(1, 1, 1, 0.25)
	var b = BUTTONS[i]
	if down:
		Input.action_press(b[0])
	else:
		Input.action_release(b[0])
	var ev = InputEventKey.new()
	ev.scancode = b[2]
	ev.pressed = down
	Input.parse_input_event(ev)
