extends Spatial
class_name Prop

# This is used for updating the position and rotations of a prop.
# And it creates slide and hit sounds.

onready var hit_player : AudioStreamPlayer3D = get_node("hit")
onready var slide_player : AudioStreamPlayer3D = get_node("slide")

func _ready():
	pass

# Update the position and rotation
puppet func update(pos : Vector3, rot : Vector3):
	translation = pos
	rotation = rot

# Emit sound when object has hit something.
puppet func play_hit_sound(_lvl : float, material_name : String):
	var new_hit_player = AudioStreamPlayer3D.new()
	add_child(new_hit_player)
	new_hit_player.global_transform.origin = global_transform.origin
#	new_hit_player.unit_size = _lvl
	new_hit_player.stream = preloader.hit_sounds[material_name][randi() % preloader.hit_sounds[material_name].size() - 1]
	new_hit_player.play()
	yield(get_tree().create_timer(5), "timeout")
	new_hit_player.queue_free()

# Sliding sounds
puppet func play_slide_sound(stop : bool, lvl : float, material_name : String):
	if !stop:
		slide_player.unit_size = lvl
		if !slide_player.playing:
			slide_player.stream = preloader.slide_sounds[material_name]
			slide_player.play()
	else:
		slide_player.stop()
