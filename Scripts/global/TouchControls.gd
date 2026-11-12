extends CanvasLayer
# Controles tactiles v16 para MOTHER: Encore (Godot 3.6)
# DEBUG = true: muestra 2 lineas de rendimiento arriba a la izquierda y los botones B, N, V y E.
#   B = inspecciona los fondos de combate (shader, viewport y parametros; pulsa de nuevo para el siguiente nodo)
#   N = cuenta nodos por clase y scripts que se ejecutan cada frame
#   V = recorre vistas de los fondos: todos ocultos, solo cada capa, todos visibles (pulsa varias veces)
#   E = experimentos sobre el fondo de combate (4 pasos, pulsa varias veces; ver instrucciones en pantalla)
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
	["debug_vis", "V", 0, 206, 4, 24, 16],  # solo DEBUG: oculta/muestra fondos
	["debug_exp", "E", 0, 234, 4, 24, 16],  # solo DEBUG: experimentos de shader en el fondo
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
var _vis_mode = 0
var _exp_step = 0
var _id_2d_items = ClassDB.class_get_integer_constant("Performance", "RENDER_2D_ITEMS_IN_FRAME")
var _id_2d_dc = ClassDB.class_get_integer_constant("Performance", "RENDER_2D_DRAW_CALLS_IN_FRAME")
var _dc_max = 0
var _items_max = 0
var _exp_nodes = []
var _exp_orig = []
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
		debug_bg0.rect_size = Vector2(250, 38)
		debug_bg0.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(debug_bg0)
		debug_label5 = Label.new()
		debug_label5.rect_position = Vector2(2, 1)
		debug_label5.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(debug_label5)
		debug_bg7 = ColorRect.new()
		debug_bg7.color = Color(0, 0, 0, 0.7)
		debug_bg7.rect_position = Vector2(0, 40)
		debug_bg7.rect_size = Vector2(320, 110)
		debug_bg7.mouse_filter = Control.MOUSE_FILTER_IGNORE
		debug_bg7.visible = false
		add_child(debug_bg7)
		debug_label7 = Label.new()
		debug_label7.rect_position = Vector2(2, 41)
		debug_label7.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(debug_label7)
		debug_bg8 = ColorRect.new()
		debug_bg8.color = Color(0, 0, 0, 0.7)
		debug_bg8.rect_position = Vector2(0, 40)
		debug_bg8.rect_size = Vector2(320, 110)
		debug_bg8.mouse_filter = Control.MOUSE_FILTER_IGNORE
		debug_bg8.visible = false
		add_child(debug_bg8)
		debug_label8 = Label.new()
		debug_label8.rect_position = Vector2(2, 41)
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
	if _id_2d_dc != 0:
		var dc = int(Performance.get_monitor(_id_2d_dc))
		if dc > _dc_max:
			_dc_max = dc
	if _id_2d_items != 0:
		var itn = int(Performance.get_monitor(_id_2d_items))
		if itn > _items_max:
			_items_max = itn
	_stat_timer += delta
	if _stat_timer > 3.0:
		debug_label5.text = "fps_min=" + str(_fps_min) + " dt_max=" + str(int(_dt_max * 1000)) + "ms touch=" + str(_touch_max / 1000) + "ms\nproc=" + str(int(_proc_max * 1000)) + "ms phys=" + str(int(_phys_max * 1000)) + "ms nodos=" + str(int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))) + "\ndibujo: llamadas=" + str(_dc_max) + " items=" + str(_items_max)
		_fps_min = 999
		_dt_max = 0.0
		_touch_max = 0
		_proc_max = 0.0
		_phys_max = 0.0
		_dc_max = 0
		_items_max = 0
		_stat_timer = 0.0


# Boton B (solo DEBUG): muestra un nodo con el shader de los fondos (Distortionator) y sus
# parametros de animacion que NO estan en cero. Pulsa de nuevo para ver el siguiente nodo.
func _scan_bbg():
	var found = []
	_collect_shader_nodes(get_tree().root, found)
	debug_bg7.visible = true
	debug_bg8.visible = false
	debug_label8.text = ""
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
	var vp = c.get_viewport()
	var vpinfo = "vp=root"
	if vp != get_tree().root:
		vpinfo = "vp=" + str(vp.name) + " " + str(vp.size) + " upd=" + str(vp.render_target_update_mode)
	var texinfo = "tex=?"
	if "texture" in c and c.texture != null:
		texinfo = "tex=" + str(c.texture.resource_path).get_file() + " " + str(c.texture.get_size())
	var body = "(todos los parametros de movimiento en 0)"
	if parts.size() > 0:
		body = PoolStringArray(parts).join(" ")
	debug_label7.text = head + "\n" + _wrap(vpinfo + " " + texinfo, 40, 2) + "\n" + _wrap(body, 40, 5)
	_bbg_index += 1


# Boton E (solo DEBUG): 4 experimentos sobre los nodos de los fondos de combate.
# Pulsa E una vez por paso y dime que ves en cada uno.
#  1 = tinte rojo (shader minimo)          -> comprueba que estos nodos dibujan el fondo
#  2 = scroll con TIME (shader minimo)     -> comprueba que TIME avanza en estos nodos
#  3 = shader ORIGINAL con move=(0.3,0)    -> comprueba el shader completo
#  4 = restaura el fondo original
func _run_experiment():
	debug_bg7.visible = true
	debug_bg8.visible = false
	debug_label8.text = ""
	var valid = _exp_nodes.size() > 0
	for n in _exp_nodes:
		if not is_instance_valid(n):
			valid = false
	if not valid:
		_exp_nodes = []
		_exp_orig = []
		_collect_shader_nodes(get_tree().root, _exp_nodes)
		for n in _exp_nodes:
			_exp_orig.append(n.material)
		_exp_step = 0
	if _exp_nodes.size() == 0:
		debug_label7.text = "E: no hay fondos con shader en esta escena"
		return
	var txt = ""
	match _exp_step:
		0:
			_apply_exp_shader("shader_type canvas_item;\nvoid fragment() { COLOR = texture(TEXTURE, UV); COLOR.rgb = COLOR.rgb * vec3(1.0, 0.2, 0.2); }")
			txt = "E 1/4: tinte ROJO.\nSe ve el fondo rojizo?"
		1:
			_apply_exp_shader("shader_type canvas_item;\nvoid fragment() { COLOR = texture(TEXTURE, UV + vec2(TIME * 0.3, 0.0)); }")
			txt = "E 2/4: scroll con TIME (shader minimo).\nSe mueve? Se estira en rayas?"
		2:
			for i in range(_exp_nodes.size()):
				var m = _exp_orig[i].duplicate()
				m.set_shader_param("move", Vector2(0.3, 0.0))
				m.set_shader_param("ping_pong_speed", Vector2.ZERO)
				m.set_shader_param("oscillation_amplitude", Vector2.ZERO)
				_exp_nodes[i].material = m
			txt = "E 3/4: shader ORIGINAL con move=(0.3,0).\nSe mueve?"
		_:
			for i in range(_exp_nodes.size()):
				_exp_nodes[i].material = _exp_orig[i]
			txt = "E 4/4: fondo restaurado."
	debug_label7.text = txt
	_exp_step = (_exp_step + 1) % 4


func _apply_exp_shader(code):
	var sh = Shader.new()
	sh.code = code
	for n in _exp_nodes:
		var m = ShaderMaterial.new()
		m.shader = sh
		n.material = m


# Boton V (solo DEBUG): oculta o muestra los nodos de los fondos de combate.
# Si al ocultarlos el fondo que se ve NO desaparece, no lo estan dibujando ellos.
func _toggle_bbg_visibility():
	var found = []
	_collect_shader_nodes(get_tree().root, found)
	debug_bg7.visible = true
	debug_bg8.visible = false
	debug_label8.text = ""
	if found.size() == 0:
		debug_label7.text = "V: no hay fondos con shader"
		return
	# 0 = todos visibles, 1 = todos ocultos, 2.. = solo una capa
	_vis_mode = (_vis_mode + 1) % (found.size() + 2)
	for i in range(found.size()):
		var show = false
		if _vis_mode == 0:
			show = true
		elif _vis_mode >= 2 and i == _vis_mode - 2:
			show = true
		found[i].visible = show
	var txt = "V: TODOS visibles"
	if _vis_mode == 1:
		txt = "V: TODOS ocultos"
	elif _vis_mode >= 2:
		txt = "V: solo " + str(found[_vis_mode - 2].name)
	debug_label7.text = txt + " (" + str(_vis_mode) + "/" + str(found.size() + 1) + ")"


# Boton N (solo DEBUG): cuenta nodos por clase y scripts que se ejecutan en cada frame
func _scan_nodes():
	var classes = {}
	var scripts = {}
	var st = {"total": 0, "proc": 0, "phys": 0, "anim": 0, "timer": 0, "atree": 0}
	_count_nodes(get_tree().root, classes, scripts, st)
	debug_bg8.visible = true
	debug_bg7.visible = false
	debug_label7.text = ""
	debug_label8.text = "nodos=" + str(st["total"]) + " proc=" + str(st["proc"]) + " phys=" + str(st["phys"]) + "\nanims=" + str(st["anim"]) + " timers=" + str(st["timer"]) + " atrees=" + str(st["atree"]) + "\n" + _wrap(_top(classes, 10), 40, 3) + "\n" + _wrap(_top(scripts, 10), 40, 3)


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
	if node is AnimationPlayer:
		if node.is_playing():
			st["anim"] += 1
	elif node is Timer:
		if not node.is_stopped():
			st["timer"] += 1
	elif node is AnimationTree:
		if node.active:
			st["atree"] += 1
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
	if b[0] == "debug_vis":
		if down:
			_toggle_bbg_visibility()
		return
	if b[0] == "debug_exp":
		if down:
			_run_experiment()
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


