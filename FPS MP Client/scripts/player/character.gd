extends Spatial
class_name Character

# This is a scene used to represent a character mesh for players and bots.
# Has some states used by the animation player. 
# Sets a hit moment in a kick animation, for example.

var actor : BasePlayer
var visible_to_camera : bool setget set_visible_to_camera
var state = {
	kick_hit = false
}
signal char_state_changed

func _ready():
	actor = get_owner()
	set_visible_to_camera(true)

func set_state(s : String, b : bool):
	state[s] = b
	emit_signal("char_state_changed", s, b)

# Set mesh visibility to player's camera.
# Because we don't want to see the player's mesh by default.
# Only in ragdoll state.
func set_visible_to_camera(b):
	if has_node("mesh"):
		$mesh.set_layer_mask_bit(0, b)
		$mesh.set_layer_mask_bit(10, !b)
