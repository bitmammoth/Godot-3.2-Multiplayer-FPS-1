extends Navigation
class_name RoomsGenerator

# Level generator is scrapped because Godot 3.2 can't generate navigation mesh at runtime.
# Will be back in 4.0.

# Time interval used for checking if room is overlapping
const INTERVAL = 0.07

signal level_generated

onready var room_start_scn : PackedScene = preload("res://scenes/maps/rooms/room_start.tscn")
onready var room_end_scn : PackedScene = preload("res://scenes/maps/rooms/room_end.tscn")

# Room scene and chance of spawning: type, packed scene, chance
onready var rooms = [
	[2, preload("res://scenes/maps/rooms/room_L_1.tscn"), 5],
	[3, preload("res://scenes/maps/rooms/room_L_2.tscn"), 5],
	[4, preload("res://scenes/maps/rooms/room_T.tscn"), 5],
	[5, preload("res://scenes/maps/rooms/room_1.tscn"), 1],
	[6, preload("res://scenes/maps/rooms/room_2.tscn"), 3]
]

# How many rooms to create
export var iteration_range : Vector2 = Vector2(5, 15)

# Array for all available doorways
var available_doorways = []

var room_start : RoomStart
var room_end : RoomEnd
var placed_rooms = []

# Used for sending the generated level through network
var cache : Array

onready var container = get_node("navmesh")

var thread = Thread.new()

func _ready():
#	thread.start(self, "generate_rooms")
#	generate_rooms(null)
	pass

func generate_rooms(userdata):
	# Add start room
	room_start = room_start_scn.instance()
	container.add_child(room_start)
	room_start.global_transform.origin = global_transform.origin
	add_to_available_doorways(room_start, 0)
	# Add spawnpoints to game
	game.spawn_points = room_start.get_node("spawn_points").get_children()
	# Add room to cache: index, type, transform, seals to remove
	cache.push_back([0, 1, [room_start.global_transform], []])
	yield(get_tree().create_timer(INTERVAL), "timeout")
	
	# Add rooms
	randomize()
	var iterations = rand_range(int(iteration_range.x), int(iteration_range.y))
	for i in iterations:
		var cache_index = i + 1
		
		var rand_room = get_rand_room()
		var current_room = rand_room[1].instance()
		var current_room_type = rand_room[0]
		container.add_child(current_room)
		var room_placed = false
		for adi in available_doorways.size():
			for cdi in current_room.seals.size():
				position_room_at_seal(current_room, current_room.seals[cdi], available_doorways[adi][1])
				yield(get_tree().create_timer(INTERVAL), "timeout")
				if !check_room_overlap(current_room):
					room_placed = true
					placed_rooms.push_back(current_room)
					# Add room to cache
					cache.push_back([cache_index, current_room_type, [current_room.global_transform], []])
					
					add_seals_to_cache(cache_index, current_room.seals[cdi].get_name())
					current_room.seals[cdi].queue_free()
					current_room.seals.remove(cdi)
					
					add_seals_to_cache(available_doorways[adi][0], available_doorways[adi][1].get_name())
					available_doorways[adi][1].queue_free()
					available_doorways.remove(adi)
					
					break
			if room_placed:
				add_to_available_doorways(current_room, cache_index)
				break
		if !room_placed:
			current_room.queue_free()
	
	# Add end room
	room_end = room_end_scn.instance()
	container.add_child(room_end)
	room_end.global_transform.origin = global_transform.origin
	# Add to cache
	var room_placed = false
	for adi in available_doorways.size():
		position_room_at_seal(room_end, room_end.seals[0], available_doorways[adi][1])
		yield(get_tree().create_timer(INTERVAL), "timeout")
		if !check_room_overlap(room_end):
			room_placed = true
			var cache_index = placed_rooms.size() + 1
			cache.push_back([cache_index, 0, [room_end.global_transform], []])
			add_seals_to_cache(cache_index, room_end.seals[0].get_name())
			add_seals_to_cache(available_doorways[adi][0], available_doorways[adi][1].get_name())
			# Add interest points to game
			game.interest_points = room_end.get_node("interest_points").get_children()
			room_end.seals[0].queue_free()
			available_doorways[adi][1].queue_free()
			available_doorways.remove(adi)
			break
	if !room_placed:
#		room_end.queue_free()
		# If end room can't be placed clear and regenerate all the rooms
		clear()
		generate_rooms(null)
	
	# Generate navmesh (doesn't work in 3.2)
#	thread.start(self, "generate_navmesh")
	
#	thread.wait_to_finish()
	emit_signal("level_generated")
	
func position_room_at_seal(room : Room, room_seal : Seal, target_seal : Seal):
	if is_instance_valid(room_seal) and is_instance_valid(target_seal):
		# Reset room's position and rotation
		room.global_transform.origin = Vector3.ZERO
		room.rotation = Vector3.ZERO
		
		# Rotate the room
		var target_doorway_euler = target_seal.global_transform.basis.get_euler()
		var room_seal_euler = room_seal.global_transform.basis.get_euler()
		var delta_angle = utils.delta_angle(room_seal_euler.y, target_doorway_euler.y)
		var current_room_target_rotation : Quat = Quat(Vector3.UP, delta_angle)
		room.global_transform.basis = current_room_target_rotation.inverse()
		
		# Position the room
		var room_position_offset = room_seal.global_transform.origin - room.global_transform.origin
		room.global_transform.origin = target_seal.global_transform.origin - room_position_offset

func check_room_overlap(room : Room):
	return room.overlaps

func get_rand_room():
	var total = 0
	for i in rooms.size():
		total += rooms[i][2]
	var rand = randi() % total
	for i in rooms.size():
		var room = rooms[i]
		if rand < room[2]:
			return room
		rand -= room[2]

func add_to_available_doorways(room : Room, cache_index : int):
	for d in room.seals:
		available_doorways.push_back([cache_index, d])

func clear():
	placed_rooms = []
	available_doorways = []
	for n in container.get_children():
		n.queue_free()

# Add seals to remove
func add_seals_to_cache(cache_index, seal_index):
	for i in cache.size():
		if cache[i][0] == cache_index:
			cache[i][3].push_back(seal_index)
			break

# Generate navigation mesh (doesn't work in 3.2)
func generate_navmesh(userdata):
	var navmesh_instance = get_node("navmesh")
	var navmesh = navmesh_instance.navmesh
#	NavigationMeshGenerator.clear(navmesh)
	NavigationMeshGenerator.bake(navmesh, self)
	yield(get_tree().create_timer(1), "timeout")
	navmesh_add(navmesh, navmesh_instance.global_transform)
	thread.wait_to_finish()
