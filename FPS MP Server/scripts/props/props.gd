extends Node

func _ready():
	get_tree().connect("network_peer_connected", self, "_on_player_connected")

func _on_player_connected(id):
	for n in get_children():
		if n is RigidBody:
			rpc("update_pos_rot", n.name, n.translation, n.rotation)

func _physics_process(delta):
	for n in get_children():
		if n is RigidBody:
			if n.linear_velocity.length() >= 0.1 or n.angular_velocity.length() >= 0.1:
				rpc_unreliable("update_pos_rot", n.name, n.translation, n.rotation)
