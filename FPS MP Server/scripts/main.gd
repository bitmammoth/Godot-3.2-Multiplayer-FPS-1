extends Node

# Port can be changed. Make sure your ISP doesn't block it. Also open it in the router settings.
const PORT = 27015
const MAX_PLAYERS = 32

onready var message = $ui/message
onready var world = $world

var spawn_points = []

var level_generated = false
var player_generated = []
var player_buffer = []

# onready var generator = get_node("world/map/generator")

onready var bot_scene = preload("res://scenes/player/bot.tscn")
var bots = []

func _ready():
	var server = NetworkedMultiplayerENet.new()
	server.create_server(PORT, MAX_PLAYERS)
	get_tree().set_network_peer(server)
	
	var _client_connected = get_tree().connect("network_peer_connected", self, "_on_client_connected")
	var _client_disconnected = get_tree().connect("network_peer_disconnected", self, "_on_client_disconnected")
	
#	generator.connect("level_generated", self, "_on_level_generated")
	
	# Get spawn points for players
	game.spawn_points = get_node("world/map/spawn_points").get_children()
	game.interest_points = get_node("world/map/interest_points").get_children()
	
	# Create bots
	for b in 6:
		var bot = bot_scene.instance()
		world.get_node("bots").add_child(bot)
		bot.global_transform.origin = game.spawn_points[randi() % game.spawn_points.size()].global_transform.origin
		bot.name = str(world.get_node("bots").get_children().size())
		bots.push_back(bot.name)

func _on_client_connected(id):
	message.text = "Client " + str(id) + " connected."
	var player = load("res://scenes/player/player.tscn").instance()
	player.set_name(str(id))
	world.get_node("players").add_child(player)
	player.global_transform.origin = game.spawn_points[randi() % game.spawn_points.size()].global_transform.origin
	
	# Create bot representations for player
	rpc_id(id, "create_bots", bots)
	
# Used with level generator.
#	if level_generated:
#		generator.rpc_id(id, "generate_level", generator.cache)
#		rpc_id(id, "create_bots", bots)
#		world.get_node("players").add_child(player)
#		player.global_transform.origin = game.spawn_points[randi() % game.spawn_points.size()].global_transform.origin
#	else:
#		# Push player to buffer for later spawning
#		player_buffer.push_back(player)

func _on_client_disconnected(id):
	message.text = "Client " + str(id) + " disconnected."
	for p in world.get_node("players").get_children():
		if int(p.name) == id:
			world.get_node("players").remove_child(p)
			p.queue_free()


#func _on_level_generated():
#	level_generated = true
#	for p in player_buffer:
#		world.get_node("players").add_child(p)
#		p.global_transform.origin = game.spawn_points[randi() % game.spawn_points.size()].global_transform.origin
#	generator.rpc("generate_level", generator.cache)
#	# Create bots
#	for b in 2:
#		var bot = bot_scene.instance()
#		world.get_node("bots").add_child(bot)
#		bot.global_transform.origin = game.spawn_points[randi() % game.spawn_points.size()].global_transform.origin
#		bot.name = str(world.get_node("bots").get_children().size())
#		bots.push_back(bot.name)
