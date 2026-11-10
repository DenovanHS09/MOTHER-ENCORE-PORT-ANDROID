extends CanvasLayer
# Controles tactiles v12 para MOTHER: Encore (Godot 3.6)
# DEBUG = true: muestra 2 lineas de rendimiento arriba a la izquierda y los botones B y N.
#   B = inspecciona los fondos de combate (parametros del shader; pulsa de nuevo para el siguiente nodo)
#   N = cuenta nodos por clase y scripts que se ejecutan cada frame
# DEBUG = false: no se ve ningun texto de diagnostico ni los botones B y N.
# - Los toques se manejan aqui y se emulan como TECLADO real (y como acciones).
# - La cruceta es una ZONA: puedes deslizar el dedo de una direccion a otra
#   sin soltar, y se admiten diagonales.
# - Boton Sh = tecla Shift (accion ui_toggle del juego, usada para correr).
# - Se mantiene al final del arbol para recibir los toques antes que los menus.
# - Al perder el foco de la app (o cancelarse un toque) se sueltan todos los botones.

const DEBUG = true

# true = los eventos de toque/arrastre se consumen aqui (el juego no los necesita: usa
# teclado y botones). Evita que cada arrastre del dedo recorra todo el juego.
const CONSUME_TOUCH = true

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
	["ui_scope", "Ct", KEY_CONTROL, 288, 68, 26, 26],  # Ctrl: modo camara
	["ui_toggle", "Sh", KEY_SHIFT, 288, 98, 26, 26],
	["ui_map", "M", KEY_TAB, 292, 4, 24, 16],  # KEY_TAB = 16777218 (el valor que usabas)
	["ui_focus_prev", "A", KEY_A, 4, 4, 24, 16],
	["ui_focus_next", "S", KEY_S, 262, 4, 24, 16],
	["debug_scan", "B", 0, 150, 4, 24, 16],  # solo DEBUG: inspecciona fondos de combate
	["debug_nodes", "N", 0, 178, 4, 24, 16],  # solo DEBUG: cuenta nodos y scripts activos
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

# Dialogo de salida (boton Atras de Android)
const EXIT_YES = Rect2(50, 96, 100, 30)
const EXIT_NO = Rect2(170, 96, 100, 30)

var rects = []
var panels = []
var pressed = []
var touches = {}
var dpad_finger = -1
var debug_label5
var debug_label7
var debug_label8
var debug_bg0
var debug_bg7
var debug_bg8
var _bbg_index = 0
var _fps_min = 999
var _dt_max = 0.0
var _touch_max = 0
var _stat_timer = 0.0
var _proc_max = 0.0
var _phys_max = 0.0
var _exit_panel
var _exit_open = false
var _exit_was_paused = false


func _ready():
	layer = 100
	pause_mode = PAUSE_MODE_PROCESS
	for b in BUTTONS:
		var r = Rect2(b[3], b[4], b[5], b[6])
		var hidden = (not DEBUG) and str(b[0]).begins_with("debug_")
		if hidden:
			r = Rect2(-100, -100, 1, 1)
		rects.append(r)
		pressed.append(false)
		var panel = ColorRect.new()
		panel.rect_position = r.position
		panel.rect_size = r.size
		panel.color = COLOR_IDLE
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.visible = not hidden
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
		debug_bg0 = ColorRect.new()
		debug_bg0.color = Color(0, 0, 0, 0.5)
		debug_bg0.rect_position = Vector2(0, 0)
		debug_bg0.rect_size = Vector2(250, 26)
		debug_bg0.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(debug_bg0)
		debug_label5 = Label.new()
		debug_label5.rect_position = Vector2(2, 1)
		debug_label5.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(debug_label5)
		debug_bg7 = ColorRect.new()
		debug_bg7.color = Color(0, 0, 0, 0.7)
		debug_bg7.rect_position = Vector2(0, 28)
		debug_bg7.rect_size = Vector2(320, 62)
		debug_bg7.mouse_filter = Control.MOUSE_FILTER_IGNORE
		debug_bg7.visible = false
		add_child(debug_bg7)
		debug_label7 = Label.new()
		debug_label7.rect_position = Vector2(2, 29)
		debug_label7.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(debug_label7)
		debug_bg8 = ColorRect.new()
		debug_bg8.color = Color(0, 0, 0, 0.7)
		debug_bg8.rect_position = Vector2(0, 92)
		debug_bg8.rect_size = Vector2(320, 62)
		debug_bg8.mouse_filter = Control.MOUSE_FILTER_IGNORE
		debug_bg8.visible = false
		add_child(debug_bg8)
		debug_label8 = Label.new()
		debug_label8.rect_position = Vector2(2, 93)
		debug_label8.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(debug_label8)
	_build_exit_panel()
	# El boton Atras de Android ya no cierra el juego: pide confirmacion
	get_tree().set_quit_on_go_back(false)
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


func _process(delta):
	# Rendimiento: peor FPS, peor tiempo de frame, peor tiempo del manejo de toques (ultimos 3 s)
	var fps = Engine.get_frames_per_second()
	if fps < _fps_min:
		_fps_min = fps
	if delta > _dt_max:
		_dt_max = delta
	var pt = Performance.get_monitor(Performance.TIME_PROCESS)
	if pt > _proc_max:
		_proc_max = pt
	var ph = Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)
	if ph > _phys_max:
		_phys_max = ph
	_stat_timer += delta
	if _stat_timer > 3.0:
		debug_label5.text = "fps_min=" + str(_fps_min) + " dt_max=" + str(int(_dt_max * 1000)) + "ms touch=" + str(_touch_max / 1000) + "ms\nproc=" + str(int(_proc_max * 1000)) + "ms phys=" + str(int(_phys_max * 1000)) + "ms nodos=" + str(int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)))
		_fps_min = 999
		_dt_max = 0.0
		_touch_max = 0
		_proc_max = 0.0
		_phys_max = 0.0
		_stat_timer = 0.0


# Boton B (solo DEBUG): muestra un nodo con el shader de los fondos (Distortionator) y sus
# parametros de animacion que NO estan en cero. Pulsa de nuevo para ver el siguiente nodo.
func _scan_bbg():
	var found = []
	_collect_shader_nodes(get_tree().root, found)
	debug_bg7.visible = true
	if found.size() == 0:
		debug_label7.text = "bbg: 0 nodos con shader"
		return
	if _bbg_index >= found.size():
		_bbg_index = 0
	var c = found[_bbg_index]
	var m = c.material
	var parts = []
	for p in m.get_property_list():
		var pname = str(p["name"])
		if not pname.begins_with("shader_param/"):
			continue
		var nm = pname.substr(13)
		if nm in ["opacity", "blending", "screen_size"]:
			continue
		var v = m.get_shader_param(nm)
		if v == null or typeof(v) == TYPE_OBJECT:
			continue
		if _is_zero(v):
			continue
		parts.append(nm + "=" + _fmt(v))
	var estado = " ON" if c.is_visible_in_tree() else " off"
	var head = "bbg " + str(_bbg_index + 1) + "/" + str(found.size()) + ": " + str(c.name) + estado + " op=" + str(m.get_shader_param("opacity")) + " bl=" + str(m.get_shader_param("blending"))
	var body = "(todos los parametros de movimiento en 0)"
	if parts.size() > 0:
		body = PoolStringArray(parts).join(" ")
	debug_label7.text = head + "\n" + _wrap(body, 40, 4)
	_bbg_index += 1


# Boton N (solo DEBUG): cuenta nodos por clase y scripts que se ejecutan en cada frame
func _scan_nodes():
	var classes = {}
	var scripts = {}
	var st = {"total": 0, "proc": 0, "phys": 0}
	_count_nodes(get_tree().root, classes, scripts, st)
	debug_bg8.visible = true
	debug_label8.text = "nodos=" + str(st["total"]) + " proc=" + str(st["proc"]) + " phys=" + str(st["phys"]) + "\n" + _wrap(_top(classes, 8), 40, 2) + "\n" + _wrap(_top(scripts, 8), 40, 2)


func _is_zero(v):
	match typeof(v):
		TYPE_INT, TYPE_REAL:
			return v == 0
		TYPE_BOOL:
			return v == false
		TYPE_VECTOR2:
			return v == Vector2.ZERO
	return false


func _fmt(v):
	if typeof(v) == TYPE_VECTOR2:
		return "(" + str(stepify(v.x, 0.001)) + "," + str(stepify(v.y, 0.001)) + ")"
	if typeof(v) == TYPE_REAL:
		return str(stepify(v, 0.001))
	return str(v)


# Parte un texto en lineas de maximo "width" caracteres (hasta "max_lines" lineas)
func _wrap(text, width, max_lines):
	var lines = []
	var cur = ""
	for w in text.split(" "):
		if cur != "" and cur.length() + 1 + w.length() > width:
			lines.append(cur)
			cur = w
		elif cur == "":
			cur = w
		else:
			cur += " " + w
	if cur != "":
		lines.append(cur)
	var out = []
	for i in range(lines.size()):
		if i >= max_lines:
			out[max_lines - 1] += " ..."
			break
		out.append(lines[i])
	return PoolStringArray(out).join("\n")


func _count_nodes(node, classes, scripts, st):
	st["total"] += 1
	var cn = node.get_class()
	classes[cn] = classes.get(cn, 0) + 1
	var active = false
	if node.is_processing():
		st["proc"] += 1
		active = true
	if node.is_physics_processing():
		st["phys"] += 1
		active = true
	if active:
		var key = "(motor)"
		var sc = node.get_script()
		if sc != null:
			key = str(sc.resource_path).get_file()
		scripts[key] = scripts.get(key, 0) + 1
	for ch in node.get_children():
		_count_nodes(ch, classes, scripts, st)


func _top(d, n):
	var arr = []
	for k in d.keys():
		arr.append([k, d[k]])
	arr.sort_custom(self, "_cmp_desc")
	var out = []
	for i in range(min(n, arr.size())):
		out.append(str(arr[i][0]) + "=" + str(arr[i][1]))
	return PoolStringArray(out).join(" ")


func _cmp_desc(a, b):
	return a[1] > b[1]


func _collect_shader_nodes(node, out):
	if node is CanvasItem and node.material is ShaderMaterial and node.material.shader != null:
		if "ping_pong_speed" in node.material.shader.code:
			out.append(node)
	for ch in node.get_children():
		_collect_shader_nodes(ch, out)


# Evita botones "pegados" si la app pierde el foco o se minimiza.
func _notification(what):
	if what == MainLoop.NOTIFICATION_WM_FOCUS_OUT or what == MainLoop.NOTIFICATION_APP_PAUSED:
		_release_all()
	elif what == MainLoop.NOTIFICATION_WM_GO_BACK_REQUEST:
		_toggle_exit()


func _input(event):
	var t0 = OS.get_ticks_usec()
	if _exit_open:
		if event is InputEventScreenTouch and event.pressed:
			var ep = _to_virtual(event.position)
			if EXIT_YES.has_point(ep):
				get_tree().quit()
			elif EXIT_NO.has_point(ep):
				_close_exit()
		get_tree().set_input_as_handled()
		return
	if event is InputEventScreenTouch:
		var p = _to_virtual(event.position)
		if event.pressed:
			_touch(event.index, p)
		else:
			_release_finger(event.index)
		if CONSUME_TOUCH:
			get_tree().set_input_as_handled()
	elif event is InputEventScreenDrag:
		_touch(event.index, _to_virtual(event.position))
		if CONSUME_TOUCH:
			get_tree().set_input_as_handled()
	if DEBUG:
		var us = OS.get_ticks_usec() - t0
		if us > _touch_max:
			_touch_max = us


# Dialogo "¿Salir del juego?" (se abre con el boton Atras de Android)
func _build_exit_panel():
	_exit_panel = ColorRect.new()
	_exit_panel.color = Color(0, 0, 0, 0.75)
	_exit_panel.rect_position = Vector2.ZERO
	_exit_panel.rect_size = VIEW_SIZE
	_exit_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_exit_panel.visible = false
	add_child(_exit_panel)
	var title = Label.new()
	title.text = "¿Salir del juego?"
	title.rect_position = Vector2(0, 62)
	title.rect_size = Vector2(VIEW_SIZE.x, 20)
	title.align = Label.ALIGN_CENTER
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_exit_panel.add_child(title)
	_add_exit_button(EXIT_YES, "Salir")
	_add_exit_button(EXIT_NO, "Cancelar")


func _add_exit_button(r, text):
	var box = ColorRect.new()
	box.color = Color(1, 1, 1, 0.3)
	box.rect_position = r.position
	box.rect_size = r.size
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_exit_panel.add_child(box)
	var lbl = Label.new()
	lbl.text = text
	lbl.rect_size = r.size
	lbl.align = Label.ALIGN_CENTER
	lbl.valign = Label.VALIGN_CENTER
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(lbl)


func _toggle_exit():
	if _exit_panel == null:
		return
	if _exit_open:
		_close_exit()
		return
	_release_all()
	_exit_open = true
	_exit_was_paused = get_tree().paused
	get_tree().paused = true
	_exit_panel.visible = true


func _close_exit():
	_exit_open = false
	_exit_panel.visible = false
	get_tree().paused = _exit_was_paused


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
	if b[0] == "debug_scan":
		if down:
			_scan_bbg()
		return
	if b[0] == "debug_nodes":
		if down:
			_scan_nodes()
		return
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


