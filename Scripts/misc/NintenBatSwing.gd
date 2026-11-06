extends Sprite

onready var special:SpriteDataFetcher = get_node_or_null("../../SpriteDataFetcher2")

# Really quick and hacky script for Ninten's bat to
# render as a seperate object.

func _process(delta):
	if global.get_player().get_current_skill_action() == "swing":
		visible = true;
	else:
		visible = false;
	if (special):
		frame = special.get_frames()
