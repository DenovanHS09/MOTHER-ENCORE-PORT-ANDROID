extends Node2D

# Amount of cloud nodes desired.
export (PackedScene) var cloud_scene
export var cloud_density : int = 20
# Path of the Polygon to draw the clouds around
export var polygon2d_path: NodePath = "ViewportContainer/Viewport/Polygon2D"
# YSort path to put the clouds in. 
export var ysort_path: NodePath = "ViewportContainer/Viewport/Polygon2D/YSort"

onready var polygon2d = get_node_or_null(polygon2d_path)
onready var ysort = get_node_or_null(ysort_path)

# Called when the node enters the scene tree for the first time.
func _ready():
	# Instanciate cloud nodes as we go.
	for i in cloud_density:
		# Ugly ass statement here. oh well!
		var travel_distance : float = (i/float(cloud_density))
		_create_cloud(polygon2d.get_point_at_offset(travel_distance))
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):

	pass
	
func _create_cloud(pos: Vector2):
	print("Cloud Instanced at ", pos, " ...")
	var new_cloud = cloud_scene.instance()
	new_cloud.position = pos
	ysort.add_child(new_cloud)
