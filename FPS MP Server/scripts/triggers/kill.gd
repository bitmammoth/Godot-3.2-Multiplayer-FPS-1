extends Area

# Level bounds that kills the player and respawns props

func _ready():
	var _body_entered = connect("body_entered", self, "_on_body_entered")

func _on_body_entered(body):
	if body is Prop:
		body.global_transform.origin = body.start_pos
		body.linear_velocity = Vector3.ZERO
		body.angular_velocity = Vector3.ZERO
	elif body is Player:
		body.die()
	else:
		body.queue_free()
