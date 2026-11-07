extends CanvasLayer
# Controles tactiles v5 para MOTHER: Encore (Godot 3.6)
# (unifica v3 + v4 y añade mejoras de robustez)
# Pon DEBUG = false cuando todo funcione para ocultar los textos de diagnostico.
# - Los toques se manejan aqui y se emulan como TECLADO real (y como acciones).
# - La cruceta es una ZONA: puedes deslizar el dedo de una direccion a otra
#   sin soltar, y se admiten diagonales.
# - Boton Sh = tecla Shift (accion ui_toggle del juego, usada para correr).
# - Se mantiene al final del arbol para recibir los toques antes que los menus.
# - Al perder el foco de la app (o cancelarse un toque) se sueltan todos los botones.

const DEBUG = true

# [accion, texto, tecla, x, y, ancho, alto]  (pantalla virtual 320x180)
# Los 4 primeros son la cruceta (0 arriba, 1 izquierda, 2 derecha, 3 abajo).
const BUTTONS = [
	["ui_up", "^", KEY_UP, 28, 100, 24, 24],
	["ui_left", "<", KEY_LEFT, 4, 124, 24, 24],
	["ui_right", ">", KEY_RIGHT, 52, 124, 24, 24],
	["ui_down", "v", KEY_DOWN, 28, 148, 24, 24],
	["ui_accept", "Z", KEY_Z, 288, 128, 26, 26],
	["ui_cancel", "X", KEY_X, 258, 146, 26, 26],
	["ui_select", "C", KEY_C, 258, 112, 26, 26],
	["ui_toggle", "Sh", KEY_SHIFT, 288, 98, 26, 26],
	["ui_map", "M", KEY_TAB, 292, 4, 24, 16],  # KEY_TAB = 16777218 (el valor que usabas)
	["ui_focus_prev", "A", KEY_A, 4, 4, 24, 16],
	["ui_focus_next", "S", KEY_S, 262, 4, 24, 16],
]

const DPAD_COUNT = 4
const COLOR_IDLE = Color(1, 1, 1, 0.25)
const COLOR_DOWN = Color(1, 1, 1, 0.6)

# Zona de la cruceta
const DPAD_CENTER = Vector2(40, 136)
const DPAD_RECT = Rect2(0, 96, 80, 80)
const DPAD_DEAD = 7.0

# Tamaño de la pantalla virtual del juego
const VIEW_SIZE = Vector2(320, 180)

var rects = []
var panels = []
var pressed = []
var touches = {}
var dpad_finger = -1
var debug_label
var debug_label2
var n_events = 0


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
		panel.color = COLOR_IDLE
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
	if DEBUG:
		debug_label = Label.new()
		debug_label.rect_position = Vector2(2, 2)
		debug_label.text = "touch: -"
		debug_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(debug_label)
		debug_label2 = Label.new()
		debug_label2.rect_position = Vector2(2, 14)
		debug_label2.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(debug_label2)
	set_process(DEBUG)
	# Quedarse siempre al final del arbol (asi recibimos los toques primero)
	get_tree().root.connect("child_entered_tree", self, "_on_root_child")
	call_deferred("_move_last")


func _on_root_child(node):
	if node != self:
		call_deferred("_move_last")


func _move_last():
	var root = get_tree().root
	var n = root.get_child_count()
	if n > 0 and root.get_child(n - 1) != self:
		root.move_child(self, n - 1)


func _process(_delta):
	debug_label2.text = "paused=" + str(get_tree().paused) + " ev=" + str(n_events) + " dis=" + str(get_viewport().is_input_disabled())


# Evita botones "pegados" si la app pierde el foco o se minimiza.
func _notification(what):
	if what == MainLoop.NOTIFICATION_WM_FOCUS_OUT or what == MainLoop.NOTIFICATION_APP_PAUSED:
		_release_all()


func _input(event):
	if DEBUG:
		n_events += 1
	if event is InputEventScreenTouch:
		var p = _to_virtual(event.position)
		if event.pressed:
			if DEBUG:
				var extra = " | PAUSA" if get_tree().paused else ""
				debug_label.text = "raw " + str(int(event.position.x)) + "," + str(int(event.position.y)) + " -> " + str(int(p.x)) + "," + str(int(p.y)) + " | " + _scene_name() + extra
			_touch(event.index, p)
		else:
			_release_finger(event.index)
	elif event is InputEventScreenDrag:
		_touch(event.index, _to_virtual(event.position))


# Si el toque llega en pixeles reales de pantalla (fuera del rango 320x180),
# lo convierte a la pantalla virtual del juego.
func _to_virtual(pos):
	if pos.x > VIEW_SIZE.x + 10 or pos.y > VIEW_SIZE.y + 10:
		var win = OS.window_size
		var s = min(win.x / VIEW_SIZE.x, win.y / VIEW_SIZE.y)
		var off = (win - VIEW_SIZE * s) / 2
		return (pos - off) / s
	return pos


func _touch(index, pos):
	# Dedo que ya controla la cruceta: sigue al dedo aunque salga de la zona.
	if index == dpad_finger:
		_update_dpad(pos)
		return
	var prev = touches.get(index, -1)
	# Dedo libre que cae (o se desliza) sobre la cruceta: la captura.
	if prev == -1 and dpad_finger == -1 and DPAD_RECT.has_point(pos):
		dpad_finger = index
		_update_dpad(pos)
		return
	# Resto de botones (los primeros son la cruceta y no se tocan aqui).
	var hit = -1
	for i in range(DPAD_COUNT, rects.size()):
		if rects[i].has_point(pos):
			hit = i
			break
	if hit == prev:
		return
	if prev != -1:
		_set_pressed(prev, false)
		touches.erase(index)
	if hit != -1:
		touches[index] = hit
		_set_pressed(hit, true)


# Calcula las direcciones segun donde esta el dedo respecto al centro.
# Cerca de un eje = una direccion; en la zona intermedia = diagonal.
func _update_dpad(pos):
	var d = pos - DPAD_CENTER
	var ax = abs(d.x)
	var ay = abs(d.y)
	var up = false
	var left = false
	var right = false
	var down = false
	if max(ax, ay) > DPAD_DEAD:
		if ax > ay * 0.5:
			left = d.x < 0
			right = d.x > 0
		if ay > ax * 0.5:
			up = d.y < 0
			down = d.y > 0
	_set_pressed(0, up)
	_set_pressed(1, left)
	_set_pressed(2, right)
	_set_pressed(3, down)


func _release_finger(index):
	if index == dpad_finger:
		dpad_finger = -1
		for i in range(DPAD_COUNT):
			_set_pressed(i, false)
	if touches.has(index):
		_set_pressed(touches[index], false)
		touches.erase(index)


func _release_all():
	dpad_finger = -1
	touches.clear()
	for i in range(pressed.size()):
		_set_pressed(i, false)


func _set_pressed(i, down):
	if pressed[i] == down:
		return
	pressed[i] = down
	panels[i].color = COLOR_DOWN if down else COLOR_IDLE
	var b = BUTTONS[i]
	if down:
		Input.action_press(b[0])
	else:
		Input.action_release(b[0])
	var ev = InputEventKey.new()
	ev.scancode = b[2]
	ev.pressed = down
	if b[2] == KEY_SHIFT:
		ev.shift = true
	elif b[2] == KEY_CONTROL:
		ev.control = true
	Input.parse_input_event(ev)


func _scene_name():
	var sc = get_tree().current_scene
	return sc.name if sc else "?"
