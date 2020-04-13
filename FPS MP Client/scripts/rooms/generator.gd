extends Spatial

# This script creates rooms from the cache sent from server.

onready var container = get_node("navmesh")

# Room scenes: type and packed scene
onready var rooms = [
	preload("res://scenes/maps/rooms/room_end.tscn"),
	preload("res://scenes/maps/rooms/room_start.tscn"),
	preload("res://scenes/maps/rooms/room_L_1.tscn"),
	preload("res://scenes/maps/rooms/room_L_2.tscn"),
	preload("res://scenes/maps/rooms/room_T.tscn"),
	preload("res://scenes/maps/rooms/room_1.tscn"),
	preload("res://scenes/maps/rooms/room_2.tscn")
]

# Generate level from server cache
puppet func generate_level(cache):
	for i in cache.size():
		if cache[i] is Array:
			var type = cache[i][1]
			var trans = cache[i][2][0]
			var seals_to_remove : Array = cache[i][3]
			
			var room = rooms[type].instance()
			container.add_child(room)
			room.global_transform = trans
			var seals = room.get_node("seals").get_children()
			for j in seals.size():
				if seals_to_remove.has(seals[j].get_name()):
					seals[j].queue_free()
