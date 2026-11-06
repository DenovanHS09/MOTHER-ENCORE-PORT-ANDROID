extends BattleMenuBox

export (NodePath) var _info_box

const ITEM_PAGE_SIZE_X := 2
const ITEM_PAGE_SIZE_Y := 5

onready var _anim_player: AnimationPlayer = $AnimationPlayer
onready var _scrollbar: EncoreScrollBar = $Scrollbar

var _item_page_y_offset := 0
var _item_list := []

var _user: BattleParticipant

func _ready():
	_info_box = get_node_or_null(_info_box)
	cursor.connect("failed_move", self, "_box_boundary_moved")
	_scrollbar.nb_visible_rows = ITEM_PAGE_SIZE_Y
	global.connect("locale_changed", self, "_update_info_box")

func enter(reset := false, _action = null):
	.enter(reset, _action)
	_anim_player.play("Open")
	_scrollbar.on = true
	_user = action.user
	if reset:
		_item_list.clear()
		_item_list.append_array(_user.character.inv.get_items())
		cursor.set_cursor_from_index(0, false)
		_item_page_y_offset = 0
		_scrollbar.position = _item_page_y_offset
		_update_items(0)
		_update_info_box()
	if _info_box and !_item_list.empty():
		_info_box.activate()

func hide():
	if visible: _anim_player.play("Close")
	.hide()
	_scrollbar.on = false
	if _info_box: _info_box.deactivate()

func _move(dir: Vector2):
	var page_start: int = _item_page_y_offset * ITEM_PAGE_SIZE_X
	var item_idx: int = page_start + cursor.cursor_index
	if _item_list.size() - 1 < item_idx:
		cursor.cursor_index = _item_list.size() - page_start - 1
		cursor.set_cursor_from_index(cursor.cursor_index)
	if !_item_list.empty() and dir != Vector2.ZERO:
		item_idx = page_start + cursor.cursor_index
		if item_idx > _item_list.size() - 1:
			cursor.set_cursor_from_index(max(0, (_item_list.size() - page_start) % ITEM_PAGE_SIZE_X - 1), false)
		_update_info_box()

func _select(idx: int):
	var i := idx + _item_page_y_offset * ITEM_PAGE_SIZE_X
	if !globaldata.does_item_exist(_item_list[i].item_name) or !_can_be_selected(_item_list[i]):
		cursor.play_sfx("restricted")
	else:
		cursor.play_sfx("cursor2")
		action.item = _item_list[i]
		action.inv_idx = i
		emit_signal("next")

func _update_items(y_offset: int):
	var total_rows := int(ceil(float(_item_list.size()) / float(ITEM_PAGE_SIZE_X)))
	var max_row_offset := max(0, total_rows - ITEM_PAGE_SIZE_Y)
	_item_page_y_offset = int(clamp(y_offset, 0, max_row_offset))
	var page_start := _item_page_y_offset * ITEM_PAGE_SIZE_X
	var page_end := page_start + ITEM_PAGE_SIZE_X * ITEM_PAGE_SIZE_Y
	var items_on_page = _item_list.slice(page_start, page_end)
	for item_label in $GridContainer.get_children():
		if items_on_page.empty():
			item_label.text = ""
			item_label.show_equipped(false)
		else:
			var item = items_on_page.pop_front()
			item_label.text = TextTools.replace_text(item.get_data()["name"])
			item_label.set_self_modulate(Color.white if _can_be_selected(item) else uiManager.get_flavor_color(3))
			item_label.show_equipped(item.equipped)
	_move(Vector2.ZERO)
	_scrollbar.nb_rows = total_rows

func _box_boundary_moved(dir: Vector2):
	var total_items: int = _item_list.size()
	var max_index: int = total_items - 1
	
	var total_rows: int = ceil(float(total_items) / float(ITEM_PAGE_SIZE_X)) as int
	var max_row_offset: int = max(0, total_rows - ITEM_PAGE_SIZE_Y) as int
	var current_global_index: int = _item_page_y_offset * ITEM_PAGE_SIZE_X + cursor.cursor_index
	var row: int = current_global_index / ITEM_PAGE_SIZE_X
	var col: int = current_global_index % ITEM_PAGE_SIZE_X
	var target_global_index: int = current_global_index
	
	if dir.y != 0:
		row += int(dir.y)
		if row < 0:
			row = total_rows - 1
		elif row >= total_rows:
			row = 0
		var last_valid_col: int = min(ITEM_PAGE_SIZE_X - 1, total_items - 1 - (row * ITEM_PAGE_SIZE_X)) as int
		col = clamp(col, 0, last_valid_col) as int
		target_global_index = (row * ITEM_PAGE_SIZE_X) + col
	elif dir.x != 0:
		col += int(dir.x)
		if col < 0:
			col = ITEM_PAGE_SIZE_X - 1
		elif col >= ITEM_PAGE_SIZE_X:
			col = 0
		var row_start: int = row * ITEM_PAGE_SIZE_X
		var target_item_index: int = row_start + col
		if total_items % ITEM_PAGE_SIZE_X != 0 and row == total_rows - 1 and current_global_index % ITEM_PAGE_SIZE_X == 0 and target_item_index >= total_items:
			target_global_index = max(0, max_index - 1) as int
		else:
			var last_valid_col: int = min(ITEM_PAGE_SIZE_X - 1, total_items - 1 - row_start) as int
			col = clamp(col, 0, last_valid_col) as int
			target_global_index = row_start + col
	
	_item_page_y_offset = row if row < _item_page_y_offset else row - (ITEM_PAGE_SIZE_Y - 1) if row > _item_page_y_offset + ITEM_PAGE_SIZE_Y - 1 \
			else int(clamp(_item_page_y_offset, 0, max_row_offset))
	
	var page_start: int = _item_page_y_offset * ITEM_PAGE_SIZE_X
	var visible_count: int = min(ITEM_PAGE_SIZE_Y * ITEM_PAGE_SIZE_X, total_items - page_start) as int
	var local_index: int = clamp(target_global_index - page_start, 0, max(0, visible_count - 1)) as int
	
	if current_global_index != target_global_index:
		cursor.play_sfx("cursor1")
	cursor.set_cursor_from_index(local_index, false)
	_update_items(_item_page_y_offset)
	_scrollbar.position = _item_page_y_offset
	_update_info_box()

func _update_info_box():
	if visible and _info_box:
		var item_idx: int = cursor.cursor_index + _item_page_y_offset * ITEM_PAGE_SIZE_X
		if item_idx >= 0 and item_idx < _item_list.size():
			var item = _item_list[item_idx]
			if !globaldata.does_item_exist(item.item_name):
				return
			_info_box.update_item(item)
		else:
			_info_box.update_item(null)

func _can_be_selected(item: Item) -> bool:
	return item.is_battle_usable() and _user.character.can_use_item(item)

func _on_Arrow_moved(_dir: Vector2):
	_update_info_box()
