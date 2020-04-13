extends BasePlayer
class_name Bot

export var undead : bool = false

var brain : StackFSM

const FOV = 90
const PERCEPTION_RANGE = 100
const ATTACK_RANGE = 20
const CLOSE_ATTACK_RANGE = 1.5

var bots_container : Node
var players_container : Node
var bots : Array = []
var players : Array = []
var all_enemies : Array = []
var closest_enemy : KinematicBody

var action_time : float = 0.0

var thinking : bool = false
onready var think_timer : Timer = get_node("timers/think")

var navigation : Navigation
var point_set : bool = false
var point : Vector3
var path : PoolVector3Array

func _ready():
	var _think_timeout = think_timer.connect("timeout", self, "_on_think_end")
	brain = StackFSM.new()
	add_child(brain)
	brain.push_state("idle", null)
	set_health(100)
	navigation = game.world.get_node("map/mesh")
	var random_weapon_index = randi() % 2 + 1
	equip_weapon(random_weapon_index)
	if undead:
		set_state("undead", true)
		vars.MAX_SPEED = 3
		vars.MAX_FORWARD_SPEED = 3
		get_node("timers/footstep").wait_time = 0.5
	bots_container = game.world.get_node("bots")
	players_container = game.world.get_node("players")

func _process(_delta):
	pass

func _physics_process(delta):
	bots = bots_container.get_children()
	players = players_container.get_children()
	all_enemies = players + bots
	var closest : Array = []
	for e in all_enemies:
		if is_instance_valid(e):
			if global_transform.origin.distance_to(e.global_transform.origin) <= PERCEPTION_RANGE and !e.state.dead and e != self:
				closest.push_back([int(global_transform.origin.distance_to(e.global_transform.origin)), e])
	closest.sort_custom(Sorter, "sort")
#	game.main_scene.message.text = str(closest)
	closest_enemy = null
	if closest.size() > 1:
		closest_enemy = closest[0][1]
	
	# Brain stack
#	game.main_scene.message.text = str(brain.stack)
	
	# Face camera direction
	rotation.y = lerp_angle(rotation.y, camera.global_transform.basis.get_euler().y, delta * 5)

func process_movement(delta):
	for n in bots:
		if is_instance_valid(n):
			if translation.distance_squared_to(n.translation) <= 0.5:
				dir += translation - n.translation
	.process_movement(delta)

func idle():
	cmd.move_forward = false
	head.global_transform.basis = global_transform.basis
	if !is_instance_valid(closest_enemy) or closest_enemy == null:
		brain.push_state("roam", null)
	elif target_is_visible(closest_enemy, FOV, PERCEPTION_RANGE) and !closest_enemy.state.dead and !state.dead:
		brain.push_state("aware", closest_enemy)
	else:
		brain.push_state("roam", null)

func roam():
	if is_instance_valid(closest_enemy) and closest_enemy != null:
		if target_is_visible(closest_enemy, FOV, PERCEPTION_RANGE) and !closest_enemy.state.dead and !state.dead:
			brain.push_state("aware", closest_enemy)
	if point_set == false:
		randomize()
		point = game.interest_points[randi() % game.interest_points.size()].global_transform.origin
		point_set = true
	else:
		path = navigation.get_simple_path(global_transform.origin, point)
		if path:
			path.remove(0)
			if global_transform.origin.distance_to(point) > 1:
				look_at_point(path[0])
				cmd.move_forward = true
			else:
				point_set = false
				if !undead:
					brain.push_state("dance", rand_range(5, 15))
				else:
					brain.push_state("agony", rand_range(5, 15))
		else:
#			point_set = false
#			brain.pop_state()
			cmd.forward = true

func dance(timeout):
	action_time += get_physics_process_delta_time()
	cmd.move_forward = false
	head.global_transform.basis = global_transform.basis
	cmd.dance = true
	if is_instance_valid(closest_enemy) and closest_enemy != null:
		if target_is_visible(closest_enemy, FOV, PERCEPTION_RANGE) and !closest_enemy.state.dead and !state.dead:
			cmd.dance = false
			brain.push_state("aware", closest_enemy)
	if action_time >= timeout:
		action_time = 0.0
		cmd.dance = false
		brain.pop_state()

func agony(timeout):
	action_time += get_physics_process_delta_time()
	cmd.move_forward = false
	head.global_transform.basis = global_transform.basis
	if !state.agony:
		set_state("agony", true)
	if is_instance_valid(closest_enemy) and closest_enemy != null:
		if target_is_visible(closest_enemy, FOV, PERCEPTION_RANGE) and !closest_enemy.state.dead and !state.dead:
			set_state("agony", false)
			brain.push_state("aware", closest_enemy)
	if action_time >= timeout:
		action_time = 0.0
		set_state("agony", false)
		brain.pop_state()

func aware(target):
	cmd.move_forward = false
	look_at_target(target)
	if !is_instance_valid(target) or target == null:
		brain.pop_state()
	else:
		if target_is_visible(target, FOV, PERCEPTION_RANGE):
			brain.push_state("chase", target)
		if !target_is_visible(target, FOV, PERCEPTION_RANGE) or target.state.dead or state.dead:
			brain.pop_state()

func chase(target):
	if !is_instance_valid(target) or target == null:
		brain.pop_state()
	else:
		if global_transform.origin.distance_to(target.global_transform.origin) > PERCEPTION_RANGE or target.state.dead or state.dead:
			brain.pop_state()
		if global_transform.origin.distance_to(target.global_transform.origin) > CLOSE_ATTACK_RANGE:
			var path = navigation.get_simple_path(global_transform.origin, target.global_transform.origin)
			if path:
				path.remove(0)
				look_at_point(path[0])
				cmd.move_forward = true
			else:
				brain.pop_state()
		if target_is_visible(target, FOV, ATTACK_RANGE) and !state.undead:
			brain.push_state("shoot", target)
		if target_is_visible(target, FOV, CLOSE_ATTACK_RANGE):
			brain.push_state("attack", target)

func shoot(target):
	cmd.move_forward = false
	if !is_instance_valid(target) or target == null:
		brain.pop_state()
	else:
		look_at_target(target)
		if !thinking:
			active_weapon.cmd.primary_fire = true
			thinking = true
			randomize()
			think_timer.wait_time = rand_range(0.1, 2)
			think_timer.start()
		else:
			active_weapon.cmd.primary_fire = false
		if !target_is_visible(target, FOV, ATTACK_RANGE) or target.state.dead or state.dead:
			active_weapon.cmd.primary_fire = false
			brain.pop_state()
		if target_is_visible(target, FOV, CLOSE_ATTACK_RANGE):
			brain.push_state("attack", target)

func attack(target):
	cmd.move_forward = false
	head.global_transform.basis = global_transform.basis
	if !is_instance_valid(target):
		brain.pop_state()
	else:
		look_at_target(target)
		if !thinking:
			cmd.kick = true
			thinking = true
			randomize()
			think_timer.wait_time = rand_range(0.1, 2)
			think_timer.start()
		else:
			cmd.kick = false
		if !target_is_visible(target, FOV, CLOSE_ATTACK_RANGE) or target.state.dead or state.dead:
			cmd.kick = false
			brain.pop_state()

func hit(damage, dealer, pos):
	.hit(damage, dealer, pos)
	if dealer is KinematicBody and !brain.has_state("aware"):
		brain.push_state("aware", dealer)

func die():
	.die()
	for i in cmd.size():
		cmd[i] = false

func target_is_visible(target, fov, distance):
	if is_instance_valid(target):
		var facing = -camera.global_transform.basis.z
		var to_target = target.translation - camera.global_transform.origin
		var space_state = get_world().direct_space_state
		var result = space_state.intersect_ray(camera.global_transform.origin, target.global_transform.origin, [self])
		var result_target : Node
		if result:
			if result.collider is KinematicBody or result.collider is RigidBody:
				result_target = result.collider
		return rad2deg(facing.angle_to(to_target)) < fov and camera.global_transform.origin.distance_to(target.global_transform.origin) <= distance and result_target == target

func look_at_target(target):
	if is_instance_valid(target):
		head.look_at(Vector3(target.translation.x, target.translation.y, target.translation.z), Vector3.UP)

func look_at_point(p):
	head.look_at(Vector3(p.x, translation.y, p.z), Vector3.UP)

func _on_think_end():
	thinking = false

# For type checking
func check_bot():
	return true

# For sorting
class Sorter:
	static func sort(a, b):
		if a[0] < b[0]:
			return true
		return false
