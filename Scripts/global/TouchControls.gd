extends CanvasLayer
# Controles tactiles v10 para MOTHER: Encore (Godot 3.6)
# (v9 + los toques y arrastres de pantalla NO se pasan al resto del juego)
# Pon DEBUG = false cuando todo funcione para ocultar los textos de diagnostico.
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

# Shaders de prueba (solo DEBUG): 8 cuadritos abajo en el centro, de izquierda a derecha.
# Un cuadrito que CAMBIA DE COLOR = ese shader funciona en el telefono.
# Uno gris y quieto = ese shader falla.
const TEST_SHADERS = [
	"shader_type canvas_item;\nvoid fragment() { COLOR = vec4(fract(TIME * 0.5), 0.0, 0.0, 1.0); }",
	"shader_type canvas_item;\nvoid fragment() { highp float t = TIME * 0.5; COLOR = vec4(0.0, fract(t), 0.0, 1.0); }",
	"shader_type canvas_item;\nvoid fragment() { float k = step(1.0, mod(floor(TIME), 2.0)); COLOR = vec4(0.0, 0.0, 0.3 + 0.7 * k, 1.0); }",
	"shader_type canvas_item;\nvoid fragment() { float k = 0.3; if (int(TIME) % 2 == 0) { k = 1.0; } COLOR = vec4(k, k, 0.0, 1.0); }",
	"shader_type canvas_item;\nvoid fragment() { vec4 c = textureLod(TEXTURE, UV, 0.0); COLOR = vec4(c.rgb * fract(TIME * 0.5), 1.0); }",
	"shader_type canvas_item;\nvoid fragment() { vec4 c = texture(TEXTURE, UV); COLOR = vec4(c.rgb * fract(TIME * 0.5), 1.0); }",
	"shader_type canvas_item;\nuniform bool on = true;\nuniform int n = 2;\nvoid fragment() { float k = 0.3; if (on && n > 1) { k = fract(TIME * 0.5); } COLOR = vec4(k, 0.0, k, 1.0); }",
	"shader_type canvas_item;\nvoid fragment() { vec4 s = texture(SCREEN_TEXTURE, SCREEN_UV); COLOR = vec4(fract(TIME * 0.5), 0.5 + s.g * 0.0, 0.5, 1.0); }",
]

var rects = []
var panels = []
var pressed = []
var touches = {}
var dpad_finger = -1
var debug_label
var debug_label2
var debug_label3
var debug_label4
var debug_label5
var n_events = 0
var _dbg_timer = 0.0
var _fps_min = 999
var _dt_max = 0.0
var _touch_max = 0
var _stat_timer = 0.0
var _proc_max = 0.0
var _phys_max = 0.0
var debug_label6
var debug_label7
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
		debug_label = Label.new()
		debug_label.rect_position = Vector2(2, 2)
		debug_label.text = "touch: -"
		debug_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(debug_label)
		debug_label2 = Label.new()
		debug_label2.rect_position = Vector2(2, 14)
		debug_label2.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(debug_label2)
		debug_label3 = Label.new()
		debug_label3.rect_position = Vector2(2, 26)
		debug_label3.mouse_filter = Control.MOUSE_FILTER_IGNORE
		debug_label3.text = OS.get_video_driver_name(OS.get_current_video_driver()) + " | " + VisualServer.get_video_adapter_name() + " | " + VisualServer.get_video_adapter_vendor()
		add_child(debug_label3)
		debug_label4 = Label.new()
		debug_label4.rect_position = Vector2(2, 38)
		debug_label4.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(debug_label4)
		debug_label5 = Label.new()
		debug_label5.rect_position = Vector2(2, 50)
		debug_label5.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(debug_label5)
		debug_label6 = Label.new()
		debug_label6.rect_position = Vector2(2, 62)
		debug_label6.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(debug_label6)
		debug_label7 = Label.new()
		debug_label7.rect_position = Vector2(2, 74)
		debug_label7.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(debug_label7)
		_build_shader_tests()
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
	debug_label2.text = "paused=" + str(get_tree().paused) + " ev=" + str(n_events) + " dis=" + str(get_viewport().is_input_disabled())
	_dbg_timer += delta
	if _dbg_timer > 0.5:
		_dbg_timer = 0.0
		_update_cloud_info()
	# Rendimiento: peor FPS, peor tiempo de frame y peor tiempo del manejo de toques (ultimos 3 s)
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
		debug_label5.text = "fps_min=" + str(_fps_min) + " dt_max=" + str(int(_dt_max * 1000)) + "ms touch_max=" + str(_touch_max / 1000) + "ms"
		debug_label6.text = "proc=" + str(int(_proc_max * 1000)) + "ms phys=" + str(int(_phys_max * 1000)) + "ms nodos=" + str(int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))) + " vmem=" + str(int(Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576)) + "MB"
		_fps_min = 999
		_dt_max = 0.0
		_touch_max = 0
		_proc_max = 0.0
		_phys_max = 0.0
		_stat_timer = 0.0


# Boton B (solo DEBUG): busca nodos que usan el shader de Distortionator (fondos de combate)
# y muestra cuantos hay y que parametros tienen distintos del valor por defecto.
func _scan_bbg():
	var found = []
	_collect_shader_nodes(get_tree().root, found)
	var txt = "bbg: " + str(found.size()) + " nodos"
	if found.size() > 0:
		var c = found[0]
		var m = c.material
		txt += " | " + str(c.name) + " vis=" + str(c.is_visible_in_tree())
		var rid = m.shader.get_rid()
		var parts = []
		for u in m.shader.get_shader_uniform_list():
			var nm = u["name"]
			var v = m.get_shader_param(nm)
			if v == null or typeof(v) == TYPE_OBJECT:
				continue
			var d = VisualServer.shader_get_param_default(rid, nm)
			if v != d:
				parts.append(nm + "=" + str(v))
		txt += "\n" + PoolStringArray(parts).join(" ")
	debug_label7.text = txt


func _collect_shader_nodes(node, out):
	if node is CanvasItem and node.material is ShaderMaterial and node.material.shader != null:
		if "ping_pong_speed" in node.material.shader.code:
			out.append(node)
	for ch in node.get_children():
		_collect_shader_nodes(ch, out)


# Cuadritos con shaders de prueba (gris de fondo: si el shader falla, se queda gris)
func _build_shader_tests():
	var i = 0
	for code in TEST_SHADERS:
		var back = ColorRect.new()
		back.color = Color(0.5, 0.5, 0.5, 1)
		back.rect_position = Vector2(90 + i * 16, 163)
		back.rect_size = Vector2(14, 14)
		back.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(back)
		var t = ColorRect.new()
		t.rect_position = Vector2(1, 1)
		t.rect_size = Vector2(12, 12)
		t.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var sh = Shader.new()
		sh.code = code
		var mat = ShaderMaterial.new()
		mat.shader = sh
		t.material = mat
		back.add_child(t)
		i += 1


# Muestra el estado del Sprite "Cloud" (nube del Monte Itoi) si existe en la escena
func _update_cloud_info():
	var sc = get_tree().current_scene
	var c = null
	if sc:
		c = sc.find_node("Cloud", true, false)
	if c and c is Sprite and c.texture:
		var ts = c.texture.get_size()
		debug_label4.text = "cloud tex=" + str(int(ts.x)) + "x" + str(int(ts.y)) + " h=" + str(c.hframes) + " v=" + str(c.vframes) + " f=" + str(c.frame) + " vis=" + str(c.is_visible_in_tree()) + " sc=" + str(c.scale)
	else:
		debug_label4.text = ""


# Evita botones "pegados" si la app pierde el foco o se minimiza.
func _notification(what):
	if what == MainLoop.NOTIFICATION_WM_FOCUS_OUT or what == MainLoop.NOTIFICATION_APP_PAUSED:
		_release_all()
	elif what == MainLoop.NOTIFICATION_WM_GO_BACK_REQUEST:
		_toggle_exit()


func _input(event):
	var t0 = OS.get_ticks_usec()
	if DEBUG:
		n_events += 1
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
			if DEBUG:
				var extra = " | PAUSA" if get_tree().paused else ""
				debug_label.text = "raw " + str(int(event.position.x)) + "," + str(int(event.position.y)) + " -> " + str(int(p.x)) + "," + str(int(p.y)) + " | " + _scene_name() + extra
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
