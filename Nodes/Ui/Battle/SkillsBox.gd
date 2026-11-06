extends BattleMenuBox

export (NodePath) var _info_box
export (NodePath) var spMeter

const PAGE_SIZE := Vector2(2, 3)

onready var _anim_player = $AnimationPlayer
onready var scrollbar = $Scrollbar


var _page_y_offset = 0
var _skill_list = []

var _recent_choice_pagination = {}
var _recent_choice_skill = {}
var _current_chara

func _ready():
	_info_box = get_node_or_null(_info_box)
	spMeter = get_node_or_null(spMeter)
	cursor.connect("failed_move", self, "_box_boundary_moved")
	scrollbar.nb_visible_rows = PAGE_SIZE.y
	global.connect("locale_changed", self, "_update_info_box")
	$CostLabel.set_visible(true, false)

func enter(reset := false, _action = null):
	.enter(reset, _action)
	_anim_player.play("Open")
	scrollbar.on = true
	if reset:
		_skill_list.clear()
		for skill_name in action.user.character.get_usable_skills():
			var skill = globaldata.get_battle_skill(skill_name)
			if skill.has("skill_type") and skill.skill_type == "skill":
				_skill_list.append(skill)
		_current_chara = action.user.character.get_name()
		_page_y_offset = _recent_choice_pagination.get(_current_chara, 0)
		scrollbar.position = _page_y_offset
		update_skills(_page_y_offset)
		cursor.set_cursor_from_index(_recent_choice_skill.get(_current_chara, 0), false)
	if _info_box != null and !_skill_list.empty():
		_info_box.activate()

func hide():
	if visible:
		_anim_player.play("Close")
	.hide()
	scrollbar.on = false
	if _info_box != null:
		_info_box.deactivate()
	if spMeter != null:
		spMeter.clear_preview_sp()

func _move(_dir := Vector2.ZERO):
	if _skill_list.size() - 1 < cursor.cursor_index + _page_y_offset * PAGE_SIZE.x:
		cursor.cursor_index = _skill_list.size() - _page_y_offset * PAGE_SIZE.x - 1
		cursor.set_cursor_from_index(cursor.cursor_index)
	if !_skill_list.empty():
		var skillIdx = cursor.cursor_index + _page_y_offset * PAGE_SIZE.x
		# if we move to skill that doesn't exist, move back
		if skillIdx > _skill_list.size() - 1:
			cursor.set_cursor_from_index((int(_skill_list.size()) % int(PAGE_SIZE.x)) - 1, false)
		_recent_choice_pagination[_current_chara] = _page_y_offset
		_recent_choice_skill[_current_chara] = cursor.cursor_index
	_update_info_box()

func _select(idx: int):
	if !_skill_list.empty():
		var skill = _skill_list[idx + _page_y_offset * PAGE_SIZE.x]
		if _can_be_selected(skill):
			action.skill = skill
			cursor.play_sfx("cursor2")
			emit_signal("next")
		else:
			cursor.play_sfx("restricted")

func update_skills(y_offset: float):
	_page_y_offset = y_offset
	var skills_on_page = _skill_list.slice(_page_y_offset * PAGE_SIZE.x, _page_y_offset * PAGE_SIZE.x + PAGE_SIZE.x * PAGE_SIZE.y)
	for skill_label in $GridContainer.get_children():
		if skills_on_page.empty():
			skill_label.text = ""
		else:
			var skill = skills_on_page.pop_front()
			skill_label.text = skill.name
			skill_label.set_self_modulate(Color.white if _can_be_selected(skill) else uiManager.get_flavor_color(3))
	
	_move()
	
	scrollbar.nb_rows = ceil(_skill_list.size() / float(PAGE_SIZE.x))

func _box_boundary_moved(dir: Vector2):
	var total_skills: int = _skill_list.size()
	var max_index: int = total_skills - 1
	
	var total_rows: int = ceil(float(total_skills) / float(PAGE_SIZE.x)) as int
	var max_row_offset: int = max(0, total_rows - PAGE_SIZE.y) as int
	var current_global_index: int = _page_y_offset * PAGE_SIZE.x + cursor.cursor_index
	var row: int = current_global_index / PAGE_SIZE.x
	var col: int = current_global_index % int(PAGE_SIZE.x)
	var target_global_index: int = current_global_index
	
	if dir.y != 0:
		row += int(dir.y)
		if row < 0:
			row = total_rows - 1
		elif row >= total_rows:
			row = 0
		var last_valid_col: int = min(PAGE_SIZE.x - 1, total_skills - 1 - (row * PAGE_SIZE.x)) as int
		col = clamp(col, 0, last_valid_col) as int
		target_global_index = (row * PAGE_SIZE.x) + col
	elif dir.x != 0:
		col += int(dir.x)
		if col < 0:
			col = PAGE_SIZE.x - 1
		elif col >= PAGE_SIZE.x:
			col = 0
		var row_start: int = row * PAGE_SIZE.x
		var target_item_index: int = row_start + col
		if total_skills % int(PAGE_SIZE.x) != 0 and row == total_rows - 1 and current_global_index % int(PAGE_SIZE.x) == 0 and target_item_index >= total_skills:
			target_global_index = max(0, max_index - 1) as int
		else:
			var last_valid_col: int = min(PAGE_SIZE.x - 1, total_skills - 1 - row_start) as int
			col = clamp(col, 0, last_valid_col) as int
			target_global_index = row_start + col
	
	if row < _page_y_offset:
		_page_y_offset = row
	elif row > _page_y_offset + PAGE_SIZE.y - 1:
		_page_y_offset = row - (PAGE_SIZE.y - 1)
	else:
		int(clamp(_page_y_offset, 0, max_row_offset))
	
	var page_start: int = _page_y_offset * PAGE_SIZE.x
	var visible_count: int = min(PAGE_SIZE.y * PAGE_SIZE.x, total_skills - page_start) as int
	var local_index: int = clamp(target_global_index - page_start, 0, max(0, visible_count - 1)) as int
	
	if current_global_index != target_global_index:
		cursor.play_sfx("cursor1")
	cursor.set_cursor_from_index(local_index, false)
	update_skills(_page_y_offset)
	scrollbar.position = _page_y_offset
	_update_info_box()

func _update_info_box():
	if visible and _info_box != null:
		var skill = _skill_list[cursor.cursor_index + _page_y_offset * PAGE_SIZE.x]
		_info_box.update_info(tr(skill.description))
		_update_sp_cost(skill)
		_update_sp_preview(skill)

func _update_sp_cost(skill: Dictionary):
	$CostLabel.set_cost(skill.get("sp_cost", 0))

func _update_sp_preview(skill: Dictionary):
	if spMeter == null:
		return
	var preview_sp = skill.get("sp_cost", 0) * spMeter.NOTCH_STEP
	spMeter.set_preview_sp(preview_sp)

func _can_be_selected(skill: Dictionary) -> bool:
	# Check if we have enough sp
	return skill.get("sp_cost", 0) <= spMeter.get_filled_bars()
