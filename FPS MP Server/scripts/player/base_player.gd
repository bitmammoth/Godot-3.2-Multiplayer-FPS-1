extends KinematicBody
class_name BasePlayer

const MAX_HEALTH = 100
var health setget set_health

const FOOTSTEP_TIMEOUT_GROUND = 0.35
const FOOTSTEP_TIMEOUT_LADDER = 0.5

var vars = {
	GRAVITY = -24.8,
	MAX_SPEED = 4,
	MAX_FORWARD_SPEED = 6,
	JUMP_SPEED = 7,
	ACCEL = 5,
	DEACCEL = 10,
	MAX_FLY_SPEED = 10,
	FLY_ACCEL = 5,
	MAX_WATER_SPEED = 3,
	WATER_ACCEL = 2,
	MAX_CLIMB_SPEED = 4,
	CLIMB_ACCEL = 10,
	MAX_SLOPE_ANGLE = 40
}

var input_movement_vector : Vector2 = Vector2.ZERO
var vel : Vector3
var pvel : Vector3
var dir : Vector3
var accel : float

var camera
var head

var state = {
	dead = false,
	undead = false,
	water = false,
	climbing = false,
	grounded = false,
	flying = false,
	firing = false,
	dancing = false,
	kicking = false,
	waving = false,
	agony = false
}

var cmd = {
	move_forward = false,
	move_backward = false,
	move_left = false,
	move_right = false,
	move_jump = false,
	primary_fire = false,
	secondary_fire = false,
	next_weapon = false,
	dance = false,
	kick = false,
	wave = false
}

var score : int setget set_score, get_score
var last_damage_dealer

# Footsteps
var can_footstep_play : bool = true
var time_in_air : float = 0.0

# Network
var can_send_pos : bool = true
onready var send_pos_timer = get_node("timers/send_pos")
const CORRECTION_THRESHOLD = 0.25
var can_send_puppet : bool = true
onready var send_puppet_timer = get_node("timers/send_puppet")
var touch_mode : bool = false

# Kicking
var kick_moment : bool = false

# Weapons
var active_weapon
var active_weapon_index : int = 0
var weapons : Array = []

func _ready():
	camera = get_node("head/camera")
	head = get_node("head")
	set_health(MAX_HEALTH)
	var _respawn_timeout = get_node("timers/respawn").connect("timeout", self, "_on_respawn_timeout")
	var _footstep_timeout = get_node("timers/footstep").connect("timeout", self, "_on_footstep_timeout")
	var _send_pos_timeout = get_node("timers/send_pos").connect("timeout", self, "_on_send_pos_timeout")
	var _send_puppet_timeout = get_node("timers/send_puppet").connect("timeout", self, "_on_send_puppet_timeout")
	var _player_connected = get_tree().connect("network_peer_connected", self, "_on_player_connected")
	rpc("update_vars", vars)
	weapons = get_node("head/holder").get_children()
	equip_weapon(active_weapon_index)

func _physics_process(delta):
	process_commands(delta)
	process_movement(delta)
	
	# Fall damage
	if vel.y - pvel.y >= 30:
		hit(100, null, null)
	pvel = vel
	
	# Footsteps
	if vel.length() > 1 and (state.grounded or state.climbing) and !state.flying and can_footstep_play:
		can_footstep_play = false
		if state.climbing:
			$timers/footstep.wait_time = FOOTSTEP_TIMEOUT_LADDER
		else:
			$timers/footstep.wait_time = FOOTSTEP_TIMEOUT_GROUND
		$timers/footstep.start()
		play_footstep()
	if state.grounded and time_in_air > 0.2:
		play_footstep()
		time_in_air = 0.0
		
	
	# Dancing and kicking
	if cmd.kick and !state.dead and state.grounded:
		set_state("kicking", true)
	
	if cmd.dance and !state.dead and state.grounded:
		set_state("dancing", true)
	else:
		set_state("dancing", false)
	
	if cmd.wave and !state.dead and state.grounded:
		set_state("waving", true)
	else:
		set_state("waving", false)
	
	if kick_moment:
		kick_moment = false
		kick()
	
	# Update other player representations
	update_puppets()
	
func process_commands(_delta):
	dir = Vector3()
	var cam_xform = camera.get_global_transform()
	if !touch_mode:
		input_movement_vector = Vector2.ZERO
	if cmd.move_forward:
		input_movement_vector.y += 1
	if cmd.move_backward:
		input_movement_vector.y -= 1
	if cmd.move_left:
		input_movement_vector.x -= 1
	if cmd.move_right:
		input_movement_vector.x += 1
	input_movement_vector = input_movement_vector.normalized()
	dir += -cam_xform.basis.z * input_movement_vector.y
	dir += cam_xform.basis.x * input_movement_vector.x
	
	# Jumping
	if state.grounded and !state.flying:
		if cmd.move_jump:
			vel.y = vars.JUMP_SPEED
			play_footstep()

func process_movement(delta):
	if state.flying:
		dir = dir.normalized()
		var target = dir
		target *= vars.MAX_FLY_SPEED
		vel = vel.linear_interpolate(target, vars.FLY_ACCEL * delta)
		vel = move_and_slide(vel)
	elif state.water:
		dir = dir.normalized()
		var target = dir
		target *= vars.MAX_WATER_SPEED
		vel = vel.linear_interpolate(target, vars.WATER_ACCEL * delta)
		vel = move_and_slide(vel)
	elif state.climbing:
		dir = dir.normalized()
		var target = dir
		target *= vars.MAX_CLIMB_SPEED
		vel = vel.linear_interpolate(target, vars.CLIMB_ACCEL * delta)
		vel = move_and_slide(vel)
	else:
		dir.y = 0
		dir = dir.normalized()
		
		# Ground detection and gravity
		if $rays/ground.is_colliding() == true:
			set_state("grounded", true)
			var ground_normal = $rays/ground.get_collision_normal()
			var ground_angle = rad2deg(acos(ground_normal.dot(Vector3.UP)))
			if ground_angle > vars.MAX_SLOPE_ANGLE:
				vel.y += delta * vars.GRAVITY
		else:
			set_state("grounded", false)
			vel.y += delta * vars.GRAVITY
			time_in_air += delta
		
		var hvel = vel
		hvel.y = 0
		var target = dir
		if input_movement_vector.y > 0:
			target *= vars.MAX_FORWARD_SPEED
		else:
			target *= vars.MAX_SPEED
		if dir.dot(hvel) > 0:
			accel = vars.ACCEL
		else:
			accel = vars.DEACCEL
		
		hvel = hvel.linear_interpolate(target, accel * delta)
		vel.x = hvel.x
		vel.z = hvel.z
		vel = move_and_slide(vel, Vector3.UP, 0.05, 4, deg2rad(vars.MAX_SLOPE_ANGLE))

func play_footstep():
	if state.climbing:
		rpc_unreliable("play_footstep", "ladder")
	else:
		var collider = $rays/ground.get_collider()
		if collider is StaticBody or collider is RigidBody:
			if collider.physics_material_override:
				rpc_unreliable("play_footstep", collider.physics_material_override.get_name())
			else:
				rpc_unreliable("play_footstep", "generic")

func set_health(value):
	health = clamp(value, 0, MAX_HEALTH)
	if health <= 0 and !state.dead:
		die()

func hit(damage, dealer, pos):
	set_health(health - damage)
	rpc("hit")
	rpc_unreliable("create_blood", pos)
	if dealer:
		last_damage_dealer = dealer
		var knockback = 5
		if active_weapon in dealer:
			knockback = dealer.active_weapon.KNOCKBACK
		rpc_unreliable("set_last_impulse", (pos - dealer.global_transform.origin).normalized() * knockback * 10)

func die():
	if !state.dead:
		if is_instance_valid(last_damage_dealer) and last_damage_dealer != null:
			if last_damage_dealer.has_method("set_score"):
				last_damage_dealer.set_score(last_damage_dealer.get_score() + 1)
		set_state("dead", true)
		set_state("flying", true)
		vel = Vector3.ZERO
		$shape.set_deferred("disabled", true)
		collision_layer = 2
		$timers/respawn.start()
		
func respawn():
	if state.dead:
		set_state("flying", false)
		set_state("dead", false)
		set_health(MAX_HEALTH)
		vel = Vector3.ZERO
		$shape.set_deferred("disabled", false)
		collision_layer = 1
		global_transform.origin = game.spawn_points[randi() % game.spawn_points.size()].global_transform.origin
		rpc_unreliable("correct_pos", translation)

func _on_footstep_timeout():
	can_footstep_play = true

func _on_respawn_timeout():
	respawn()

func _on_send_pos_timeout():
	can_send_pos = true

func set_state(s : String, b : bool):
	state[s] = b
	rpc("update_state", s, b)

func set_score(value):
	score = value
	rpc("update_score", value)
	
func get_score():
	return score

func set_velocity(v : Vector3):
	vel = v
	rpc_unreliable("update_velocity", v)

remote func update_rotation(rot : Vector3, head_rot : Vector3):
	if int(name) == get_tree().get_rpc_sender_id():
		rotation = rot
		head.rotation = head_rot
		
remote func execute_command(a, b):
	if int(name) == get_tree().get_rpc_sender_id():
		cmd[a] = b

remote func check_pos(pos):
	if int(name) == get_tree().get_rpc_sender_id():
		if global_transform.origin.distance_to(pos) > CORRECTION_THRESHOLD and can_send_pos and !state.dead:
			rpc_unreliable("correct_pos", global_transform.origin)
			can_send_pos = false
			send_pos_timer.start()

remote func touch_movement(x, y):
	if int(name) == get_tree().get_rpc_sender_id():
		input_movement_vector.x = x
		input_movement_vector.y = y

remote func set_touch_mode(b):
	if int(name) == get_tree().get_rpc_sender_id():
		touch_mode = b

remote func register_kick():
	kick_moment = true
	set_state("kicking", false)
	
func kick():
	var screen_center = get_viewport().size / 2
	var space_state = get_world().direct_space_state
	var from : Vector3
	var to : Vector3
	if has_method("check_player"):
		from = camera.project_ray_origin(screen_center)
		to = from + camera.project_ray_normal(screen_center) * 1
	if has_method("check_bot"):
		from = camera.global_transform.origin
		to = from + camera.global_transform.basis.z * -1
	var result = space_state.intersect_ray(from, to, [self, active_weapon], 1, true, false)
	if result:
		var dir = -camera.global_transform.basis.z.normalized()
		var pos = (global_transform.origin - result.collider.global_transform.origin).normalized()
		if result.collider is PhysicalBone:
			result.collider.apply_impulse(pos, dir * 2)
		if result.collider is RigidBody:
			result.collider.apply_impulse(pos, dir * 2)
		if result.collider is KinematicBody and result.collider.has_method("hit"):
			result.collider.hit(100, self, result.position)
			result.collider.set_velocity(dir * 2)

func update_puppets():
	if can_send_puppet and !state.dead:
		rpc_unreliable("update_puppet", global_transform.origin, rotation, head.rotation, vel, accel, input_movement_vector)
		can_send_puppet = false
		send_puppet_timer.start()

func _on_send_puppet_timeout():
	can_send_puppet = true

func equip_weapon(index):
	for i in weapons.size():
		weapons[i].visible = false
	weapons[index].visible = true
	active_weapon = weapons[index]
	active_weapon_index = index
	rpc("equip_weapon", index)

func _on_player_connected(_id):
	rpc("update_states", state)
	rpc("equip_weapon", active_weapon_index)
