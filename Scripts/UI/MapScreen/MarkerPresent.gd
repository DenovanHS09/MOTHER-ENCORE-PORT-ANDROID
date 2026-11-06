tool
extends FlaggableMarker
class_name MarkerPresent

export (String, "item", "map") var type = "item" setget _set_type 

# Override
func update():
	if !Engine.is_editor_hint() and _get_flag_status():
		frame_coords.x = 1
	else:
		frame_coords.x = 0

func _set_type(sprite):
	type = sprite
	_update_sprite()

func _update_sprite():
	if is_inside_tree():
		match type:
			"item":
				frame_coords.y = 0
			"map":
				frame_coords.y = 1
