extends Character
class_name PartyNPC

var _untargetable := false
var _skills := []

const CANARY_CHICK := "canarychick"
const FLYING_MAN := "flyingman"
const EVE := "eve"

func _init(data := {}, constant_data := {}):
	init_from_dict(data)
	init_from_dict(constant_data)

func init_from_dict(dict: Dictionary):
	if dict:
		.init_from_dict(dict)
		_untargetable = dict.get("untargetable", false)
		_set_skills(dict.get("skills", []))

func _set_skills(skills: Array):
	_skills = []
	for skill in skills:
		if skill is Dictionary and globaldata.does_battle_skill_exist(skill.get("skill")):
			_skills.append(EnemySkill.new(skill))

# Override
func get_character_type() -> int:
	return Type.PARTY_NPC

func get_nickname() -> String:
	return "[tr:NAME_" + _name.to_upper() + "]"

func get_skills() -> Array:
	return _skills

func is_targetable() -> bool:
	return !_untargetable
