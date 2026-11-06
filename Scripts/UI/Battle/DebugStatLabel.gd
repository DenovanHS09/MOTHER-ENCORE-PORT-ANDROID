extends Label
class_name DebugStatLabel

var mod = 0
var base_val = 0
var max_val = 0 

func set_val(val: int, m_val: int = 0):
	base_val = val
	max_val = m_val
	update_text()

func set_mod(val: int):
	mod = val
	update_text()

func update_text():
	text = "%s: %s" % [name, base_val]
	if mod != 0:
		if mod > 0: text += " +%s" % mod
		else: text += " %s" % mod
	if max_val != 0: text += "/%s" % max_val
