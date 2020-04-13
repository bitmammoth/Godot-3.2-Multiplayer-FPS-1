extends BaseWeapon
class_name Grabbity

onready var fire_sound = get_node("sounds/fire")
onready var loop_sound = get_node("sounds/loop")
onready var grab_sound = get_node("sounds/grab")

puppet func grab(a, b, c):
	if a:
		if !loop_sound.playing:
			loop_sound.play()
	else:
		loop_sound.stop()
	if b:
		grab_sound.play()
	if c:
		fire_sound.play()
		loop_sound.stop()
