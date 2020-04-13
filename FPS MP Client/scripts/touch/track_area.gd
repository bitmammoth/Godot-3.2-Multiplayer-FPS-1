extends Control

# Hides the track pad if user is not touching the screen.

var alpha = 0.0
var alpha_target = 0.0
onready var track = get_node("track")

func _process(delta):
	alpha = lerp(alpha, alpha_target, delta * 5)
	track.modulate = Color(1, 1, 1, alpha)

func _gui_input(event):
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		alpha_target = 1.0
	
	if event is InputEventScreenTouch and !event.is_pressed():
		alpha_target = 0.0
	
	if event is InputEventScreenTouch and event.is_pressed():
		track.position = event.position
