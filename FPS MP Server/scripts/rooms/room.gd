extends Spatial
class_name Room

var seals = []
var bounds : Area
var overlaps : bool = false

func _ready():
	seals = get_node("seals").get_children()
	bounds = get_node("bounds")

func _process(delta):
	if bounds.get_overlapping_areas().size() > 0:
		overlaps = true
	else:
		overlaps = false
