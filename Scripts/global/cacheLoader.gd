extends Node

var cache_ := []
var material_cache_ := []
var materials := ["res://Shaders/Fade.shader","res://Shaders/Transition.shader","res://Shaders/Video Drug.shader"]#"res://Shaders/palLimit.shader"]

var thread_ = Thread.new()

func _ready():
	thread_.start(self,"load_stuff","no_use")

func load_stuff(no_use) -> void:
	
	_load_materials()
	
	var load_maps := [
		"res://Maps/podunk/podunk.tscn",
		#"res://Scenes/Knowhere/Benche/bencheForestOne.tscn",
		#"res://Scenes/Knowhere/Benche/bencheForestTwo.tscn"
		]
	
	var load_ui := [
		#"res://Nodes/Ui/EnemySprite.tscn",
		"res://Nodes/Ui/Pause menu.tscn"
		]
	
	for i in load_maps.size():
		cache_.push_back(load(load_maps[i]))
	
	for i in load_ui.size():
		cache_.push_back(load(load_ui[i]))

func _exit_tree():
	thread_.wait_to_finish()

func _load_materials():
	var sprites = []
	for material in materials:
		var sprite = Sprite.new()
		sprite.texture = ImageTexture.new()
		var mat = load(material)
		sprite.material = mat
		add_child(sprite)
		sprites.append(sprite)
		material_cache_.append(mat)
	
	# Remove the sprites after being rendered
	yield(get_tree().create_timer(0.2),"timeout")
	for sprite in sprites:
		sprite.queue_free()
		materials.remove(0)
