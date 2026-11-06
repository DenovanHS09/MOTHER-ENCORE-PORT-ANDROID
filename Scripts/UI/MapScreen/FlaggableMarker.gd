extends FlaggableObject
class_name FlaggableMarker


func _ready():
	update()
	global.connect("scene_changed", self, "_on_flags_updated")
	global.connect("flags_updated", self, "_on_flags_updated")

# Overriden
func update():
	pass

func _on_flags_updated():
	update()
