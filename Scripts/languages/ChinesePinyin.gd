class_name ChinesePinyin

const PINYIN_RES_PATH = "res://Scripts/languages/pinyin_data_zh_CN.res"
const PAGE_SIZE = 55   # 每页55个候选字 (30+25)

static func _load_pinyin_data(txt_path: String):
	var data = load(txt_path)
	if data.has_meta("pinyin_to_hanzi") and data.has_meta("valid_pinyins") and data.has_meta("initial_to_hanzi"):
		var pinyin_to_hanzi = data.get_meta("pinyin_to_hanzi")
		var valid_pinyins = data.get_meta("valid_pinyins")
		var initial_to_hanzi = data.get_meta("initial_to_hanzi")
		#print("从内置资源加载成功，拼音数: ", pinyin_to_hanzi.size())
		return [pinyin_to_hanzi, valid_pinyins, initial_to_hanzi]

# 根据整个输入字符串获取候选汉字列表
static func get_candidates_for_input(s: String) -> Array:
	var result = _load_pinyin_data(PINYIN_RES_PATH)
	var pinyin_to_hanzi = result[0]
	var valid_pinyins = result[1]
	var initial_to_hanzi = result[2]
	
	if s.empty():
		return []
	# 先尝试作为完整拼音
	if valid_pinyins.has(s):
		return pinyin_to_hanzi[s]
	# 再尝试作为单字母首字母
	if s.length() == 1 and s[0] >= 'a' and s[0] <= 'z':
		return initial_to_hanzi.get(s, [])
	return []

static func show_candidates_on_grid(candidates: Array, pinyin_page: int, _keyboard_grid_1: GridContainer, _keyboard_grid_2: GridContainer, _keyboard_grid_3: GridContainer):
	var start = PAGE_SIZE * pinyin_page
	var total = candidates.size()
	
	if total > PAGE_SIZE:
		var first_given = false
		var already_has = false
		for i in range(_keyboard_grid_1.get_child_count()):
			var label = _keyboard_grid_1.get_child(i)
			if label.get_child(0).text in ["◂", "▸"]:
				already_has = true
				break
		if !already_has:
			for i in range(_keyboard_grid_1.get_child_count()):
				var label = _keyboard_grid_1.get_child(i)
				if label.text == "A":
					continue
				if label.get_child(0).text in ["◂", "▸"]:
					break
				else:
					if !first_given:
						label.text = "A"
						label.get_child(0).text = "◂"
						first_given = true
					else:
						label.text = "A"
						label.get_child(0).text = "▸"
						break
	else:
		# 没有分页需求，清除分页按钮，从最后一个开始减少计算
		var first_cleared = false
		for i in range(_keyboard_grid_1.get_child_count() - 1, -1, -1):
			var label = _keyboard_grid_1.get_child(i)
			if label.text == "A" and label.get_child(0).text in ["◂", "▸"]:
				label.text = ""
				label.get_child(0).text = ""
				if !first_cleared:
					first_cleared = true
				else:
					break

	# 填充第一个网格（第1-30个候选）
	var grid2 = _keyboard_grid_2
	var cells2 = grid2.get_child_count()  # 应为30
	for i in range(cells2):
		var label = grid2.get_child(i)
		var lower_label = label.get_child(0)
		var idx = start + i
		lower_label.text = candidates[idx] if idx < total else ""
		label.text = "A" if lower_label.text != "" else ""
	
	# 填充第二个网格（第31-55个候选）
	var grid3 = _keyboard_grid_3
	var cells3 = grid3.get_child_count()  # 应为25
	for i in range(cells3):
		var label = grid3.get_child(i)
		var lower_label = label.get_child(0)
		var idx = start + 30 + i   # 偏移30
		lower_label.text = candidates[idx] if idx < total else ""
		label.text = "A" if lower_label.text != "" else ""

static func is_pinyin_char(character: String) -> bool:
	var allowed_upper = "ABCDEFGHIJKLMNOPQRSTUÜWXYZ"
	return character in allowed_upper

static func compare_page(pinyin_page: int, character: String, candidates: Array) -> int:
	match character:
		"◂":
			if pinyin_page > 0:
				return pinyin_page - 1
			elif candidates.size() > 0:
				return int((candidates.size() - 1) / PAGE_SIZE)
			else:
				return 0
		"▸":
			if candidates.size() > PAGE_SIZE * (pinyin_page + 1):
				return pinyin_page + 1
			else:
				return 0
	return pinyin_page
