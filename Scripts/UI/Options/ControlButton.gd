extends Panel

func _ready():
	focus_mode = FOCUS_CLICK
	uiManager.connect("menu_flavor_updated", self, "_update_color")
	connect("visibility_changed", self, "_update_color")
	connect("focus_entered", self, "_update_color")
	connect("focus_exited", self, "_update_color")
	_update_color()

func _update_color():
	self_modulate = uiManager.get_flavor_color(5 if has_focus() else 3)
