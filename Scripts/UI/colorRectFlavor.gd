extends ColorRect

var old_color

func _ready():
	old_color = color
	uiManager.connect("menu_flavor_updated", self, "_set_color")
	connect("visibility_changed", self, "_set_color")
	_set_color()

func _set_color():
	for i in 7:
		if old_color == uiManager.get_flavor_color(i + 1, false):
			color = uiManager.get_flavor_color(i + 1)
