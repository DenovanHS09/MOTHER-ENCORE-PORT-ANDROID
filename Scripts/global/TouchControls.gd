extends CanvasLayer
# Controles tactiles para MOTHER: Encore (Godot 3.6)
# Se carga como autoload. Cada boton dispara una accion del Input Map.

# [accion, texto, x, y, ancho, alto]  (pantalla virtual de 320x180)
const BUTTONS = [
	["ui_up", "^", 28, 100, 24, 24],
	["ui_left", "<", 4, 124, 24, 24],
	["ui_right", ">", 52, 124, 24, 24],
	["ui_down", "v", 28, 148, 24, 24],
	["ui_accept", "Z", 288, 128, 26, 26],
	["ui_cancel", "X", 258, 146, 26, 26],
	["ui_select", "C", 258, 112, 26, 26],
	["ui_map", "M", 292, 4, 24, 16],
]


func _ready():
	layer = 100
	pause_mode = PAUSE_MODE_PROCESS
	for b in BUTTONS:
		_add_button(b[0], b[1], Vector2(b[2], b[3]), Vector2(b[4], b[5]))


func _add_button(action, text, pos, size):
	var btn = TouchScreenButton.new()
	btn.action = action
	btn.position = pos
	btn.normal = _make_texture(int(size.x), int(size.y))
	btn.passby_press = true
	btn.visibility_mode = TouchScreenButton.VISIBILITY_TOUCHSCREEN_ONLY
	add_child(btn)

	var lbl = Label.new()
	lbl.text = text
	lbl.rect_position = Vector2.ZERO
	lbl.rect_size = size
	lbl.align = Label.ALIGN_CENTER
	lbl.valign = Label.VALIGN_CENTER
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(lbl)


func _make_texture(w, h):
	var img = Image.new()
	img.create(w, h, false, Image.FORMAT_RGBA8)
	img.lock()
	for x in range(w):
		for y in range(h):
			var edge = x == 0 or y == 0 or x == w - 1 or y == h - 1
			img.set_pixel(x, y, Color(1, 1, 1, 0.6 if edge else 0.22))
	img.unlock()
	var tex = ImageTexture.new()
	tex.create_from_image(img, 0)
	return tex
