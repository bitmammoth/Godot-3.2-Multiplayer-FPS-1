extends RigidBody
class_name Prop

var start_pos : Vector3
var grabbed : bool = false

var lvl : float
var plvl : float
var avl : float

var state = {
	water = false
}

var material_name : String = "concrete"

func _ready():
	start_pos = global_transform.origin
	var _player_connected = get_tree().connect("network_peer_connected", self, "_on_player_connected")
	if physics_material_override:
		material_name = physics_material_override.get_name()

func _physics_process(_delta):
	lvl = linear_velocity.length()
	avl = angular_velocity.length()
	if lvl >= 0.1 or avl >= 0.1 or grabbed:
		rpc_unreliable("update", translation, rotation)
	
	# Water
	if state.water:
		linear_velocity = Vector3.UP
	
	# Sounds
	if get_colliding_bodies().size() > 0:
		if lvl >= 0.15:
			rpc_unreliable("play_slide_sound", false, lvl, material_name)
		else:
			rpc_unreliable("play_slide_sound", true, lvl, material_name)
	else:
		rpc_unreliable("play_slide_sound", true, lvl, material_name)
	
	plvl = lvl

func set_state(s, b):
	state[s] = b

func _on_player_connected(_id):
	rpc_unreliable("update", translation, rotation)

func _integrate_forces(physics_state):
	if(physics_state.get_contact_count() >= 1):
		var collider = physics_state.get_contact_collider_object(0)
		if collider is StaticBody or collider is RigidBody or collider is KinematicBody:
			# Sounds
			var lvl = physics_state.linear_velocity.length()
			if (plvl - lvl) >= 0.25:
				rpc_unreliable("play_hit_sound", lvl, material_name)
			plvl = lvl
		if collider is BasePlayer:
			var player = physics_state.get_contact_collider_object(0)
			var pos = global_transform.origin + physics_state.get_contact_local_position(0)
			if linear_velocity.length() > 3.0:
				player.hit(int(linear_velocity.length() * 10), self, pos)
