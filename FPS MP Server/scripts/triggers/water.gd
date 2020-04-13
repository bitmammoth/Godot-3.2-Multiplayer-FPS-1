extends Area

func _ready():
	var _body_entered = connect("body_entered", self, "_on_body_entered")
	var _body_exited = connect("body_exited", self, "_on_body_exited")

func _on_body_entered(body):
	if body is Prop:
		body.set_state("water", true)
	elif body is Player:
		body.set_state("water", true)
	elif body is PhysicalBone:
		body.linear_velocity = Vector2.UP

func _on_body_exited(body):
	if body is Prop:
		body.set_state("water", false)
	if body is Player:
		body.set_state("water", false)
