extends PanelContainer
class_name DebugStatInfo

export (NodePath) onready var hp_label = get_node_or_null(hp_label) as DebugStatLabel
export (NodePath) onready var pp_label = get_node_or_null(pp_label) as DebugStatLabel
export (NodePath) onready var ofe_label = get_node_or_null(ofe_label) as DebugStatLabel
export (NodePath) onready var def_label = get_node_or_null(def_label) as DebugStatLabel
export (NodePath) onready var spd_label = get_node_or_null(spd_label) as DebugStatLabel
export (NodePath) onready var gut_label = get_node_or_null(gut_label) as DebugStatLabel
export (NodePath) onready var iq_label = get_node_or_null(iq_label) as DebugStatLabel
export (NodePath) onready var lvl_label = get_node_or_null(lvl_label) as DebugStatLabel
export (NodePath) onready var exp_label = get_node_or_null(exp_label) as DebugStatLabel
export (NodePath) onready var cash_label = get_node_or_null(cash_label) as DebugStatLabel

onready var labels = [hp_label, pp_label, ofe_label, def_label, spd_label, gut_label, iq_label, lvl_label, exp_label, cash_label]

onready var state_0_labels = [hp_label, pp_label]
onready var state_1_labels = [hp_label, pp_label, ofe_label, def_label]
onready var state_2_labels = [hp_label, pp_label, ofe_label, def_label, spd_label, gut_label, iq_label, lvl_label]

onready var stat_labels = {
	Character.HP: hp_label,
	Character.PP: pp_label,
	Character.OFFENSE: ofe_label,
	Character.DEFENSE: def_label,
	Character.SPEED: spd_label,
	Character.GUTS: gut_label,
	Character.IQ: iq_label,
}



func _ready():
	rect_size = Vector2.ZERO
	_on_debug_stat_state_updated(Debug.stat_state)
	Debug.connect("stat_state_updated", self, "_on_debug_stat_state_updated")

func set_bp_data(bp):
	var character = bp.character
	hp_label.set_val(character.get_hp(), character.get_max_hp())
	pp_label.set_val(character.get_pp(), character.get_max_pp())
	ofe_label.set_val(character.get_base_stat(Character.OFFENSE))
	def_label.set_val(character.get_base_stat(Character.DEFENSE))
	spd_label.set_val(character.get_base_stat(Character.SPEED))
	gut_label.set_val(character.get_base_stat(Character.GUTS))
	iq_label.set_val(character.get_base_stat(Character.IQ))
	lvl_label.set_val(character.get_level())
	exp_label.set_val(character.get_exp())
	cash_label.set_val(character.get_cash())
	bp.connect("stat_mod_added", self, "_on_bp_stat_mod_added")
	character.connect("stat_changed", self, "_on_character_stat_changed")

# For when the base value is changed
func _on_character_stat_changed(stat, value, max_value):
	var label = stat_labels[stat] as DebugStatLabel
	label.set_val(value, max_value)

# For stuff like buffs/debuffs
func _on_bp_stat_mod_added(stat, value):
	var label = stat_labels[stat] as DebugStatLabel
	label.set_mod(value)

func _on_debug_stat_state_updated(state):
	if state == 4:
		hide()
	else:
		show()
		for label in labels:
			var state_labels = get("state_%s_labels" % state)
			if (state_labels and label in state_labels) or state == 3:
				label.show()
			else:
				label.hide()
	rect_size = Vector2.ZERO
