extends TwoStatesSyncedSwitch

func _on_Area2D_area_entered(area):
	_operate_manually()
	if area.get_collision_layer_bit(2) == true: # Lloyd’s laser beam impact
		area.get_parent().create_spark("Explosion")
		area.get_parent().disappear()

