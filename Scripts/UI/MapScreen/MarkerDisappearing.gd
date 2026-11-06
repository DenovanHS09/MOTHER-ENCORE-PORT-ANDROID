extends FlaggableMarker
class_name MarkerDisappearing

# Override
func update():
	if _get_flag_status():
		modulate = Color.transparent
	else:
		modulate = Color.white
