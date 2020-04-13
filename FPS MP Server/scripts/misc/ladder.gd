extends Spatial

func _ready():
	var _body_entered = get_node("area").connect("body_entered", self, "_on_body_entered")
	var _body_exited = get_node("area").connect("body_exited", self, "_on_body_exited")

func _on_body_entered(body):
	if body is Player:
		body.set_state("climbing", true)

func _on_body_exited(body):
	if body is Player:
		body.set_state("climbing", false)
