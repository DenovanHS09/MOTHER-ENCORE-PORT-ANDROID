class_name EnemySkill

var skill_id: String
var weight: int
var cooldown: int = 0
var remaining_cooldown: int = 0

func _init(data: Dictionary):
	skill_id = data.get("skill", "bash")
	weight = data.get("weight", 0)
	cooldown = data.get("cooldown", 0)

func can_be_used() -> bool:
	return remaining_cooldown == 0

func try_start_cooldown():
	if cooldown > 0:
		remaining_cooldown = cooldown + 1

func try_tick_cooldown(_turns_count):
	if remaining_cooldown > 0:
		remaining_cooldown -= 1
