extends YSort


func reorganize(enemies_to_reorganize: Array, is_boss: bool, new_enemies: Array, transition: bool): # suspend func
	for i in range(enemies_to_reorganize.size()):
		var enemy: BattleParticipant = enemies_to_reorganize[i]
		var battlesprite: EnemyBattleSprite = enemy.get_sprite()
		if battlesprite.is_static():
			continue
		
		var new_position = _get_new_position(enemy, i, enemies_to_reorganize, is_boss)
		battlesprite.move(new_position, transition, funcref(self, "_on_reorganize_enemy_tween"), [battlesprite, enemy, new_enemies])
	
	if transition:
		yield(get_tree().create_timer(.65), "timeout")
		new_enemies.clear()
	else:
		yield(get_tree(), "idle_frame")

func _get_new_position(enemy: BattleParticipant, enemy_index: int, enemies_to_reorganize: Array, is_boss: bool) -> Vector2: # the ALGORITHm
	var new_position := Vector2(320, 147)
	if !enemy.is_boss():
		var enemy_count = enemies_to_reorganize.size()
		if is_boss and enemies_to_reorganize.size() > 2:
			for j in range(enemies_to_reorganize.size()):
				if enemies_to_reorganize[j].is_boss():
					enemy_count -= 1; enemy_index -= 1
		new_position.x /=  (enemy_count + 1)
		var top_pos = Vector2(new_position.x * (int(enemies_to_reorganize.size()/2.0) + 1), 147)
		var bottom_pos = Vector2(new_position.x, 147)
		new_position.x *= (enemy_index + 1)
		
		var height_diff = _get_y_curve_position(bottom_pos) - _get_y_curve_position(top_pos)
		new_position.y = _get_y_curve_position(new_position) - height_diff/3
		if is_boss:
			new_position.y -= 16
	else:
		new_position /= 2
		if enemies_to_reorganize.size() > 1:
			new_position.y += 16
	var texture_offset = enemy.get_sprite().rect_size / 2
	return new_position - texture_offset

func _get_y_curve_position(new_position: Vector2) -> float:
	var curve = 400
	return new_position.y / 2 + pow((160 - new_position.x), 2) / (curve)

func _on_reorganize_enemy_tween(battlesprite: EnemyBattleSprite, enemyBP: BattleParticipant, new_enemies: Array):
	if enemyBP in new_enemies:
		battlesprite.appear()
