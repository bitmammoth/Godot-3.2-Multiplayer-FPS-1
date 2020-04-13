extends KinematicBody
class_name BasePlayer

# Base player class used by players and bots.

export var blood_color : Color

var input_movement_vector : Vector2
var vel : Vector3
var pvel : Vector3
var dir : Vector3
var accel : float

# We are getting this numbers from the server.
var vars = {
	GRAVITY = 0.0,
	MAX_SPEED = 0.0,
	MAX_FORWARD_SPEED = 0.0,
	JUMP_SPEED = 0.0,
	ACCEL = 0.0,
	DEACCEL = 0.0,
	MAX_FLY_SPEED = 0.0,
	FLY_ACCEL = 0.0,
	MAX_WATER_SPEED = 0.0,
	WATER_ACCEL = 0.0,
	MAX_CLIMB_SPEED = 0.0,
	CLIMB_ACCEL = 0.0,
	MAX_SLOPE_ANGLE = 0.0
}

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

signal state_changed

onready var head = get_node("head")
onready var camera = get_node("head/camera")
onready var character = get_node("character")

# Weapons
var active_weapon
var active_weapon_index : int = 0
var weapons : Array = []

# Animations
#onready var anim_tree = get_node("character/animation_tree")
#onready var anim_state_machine = anim_tree["parameters/state_machine/playback"]

# Last received impulse. Used for ragdolls.
var last_impulse : Vector3

# Networking
var can_send : bool = true
onready var send_timer = get_node("timers/send")

# Touch
var touch_mode : bool = false

# Score
var score : int

func _ready():
	weapons = get_node("head/holder").get_children()
#	anim_tree.active = true
	send_timer.connect("timeout", self, "_on_send_timeout")
	character.connect("char_state_changed", self, "_on_char_state_changed")
#	enable_ragdoll_collisions(false)

func _physics_process(delta):
	process_commands(delta)
	process_movement(delta)
#	process_animations(delta)
	
	check_pos_on_server()

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

		if $rays/ground.is_colliding() == true:
			set_state("grounded", true)
			var ground_normal = $rays/ground.get_collision_normal()
			var ground_angle = rad2deg(acos(ground_normal.dot(Vector3.UP)))
			if ground_angle > vars.MAX_SLOPE_ANGLE:
				vel.y += delta * vars.GRAVITY
		else:
			set_state("grounded", false)
			vel.y += delta * vars.GRAVITY
		
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

func set_state(s : String, b : bool):
	state[s] = b

func check_pos_on_server():
	rpc_unreliable_id(1, "check_pos", translation)

puppet func hit():
	get_node("sounds/impact").play()

puppet func update_vars(v):
	vars = v

puppet func correct_pos(pos : Vector3):
#	vel = Vector3.ZERO
	global_transform.origin = pos

puppet func update_velocity(v : Vector3):
	vel = v

puppet func update_state(s, b):
	state[s] = b
	emit_signal("state_changed", s, b)

puppet func equip_weapon(index):
	for i in weapons.size():
		weapons[i].visible = false
	weapons[index].visible = true
	if state.undead:
		for i in weapons.size():
			weapons[i].visible = false

puppet func update_states(s):
	state = s

puppet func set_last_impulse(i : Vector3):
	last_impulse = i

puppet func play_footstep(material):
	$sounds/footstep.stream = preloader.footsteps[material][randi() % preloader.footsteps[material].size()]
	$sounds/footstep.play()

puppet func update_score(value):
	score = value
	if has_node("hud/score"):
		get_node("hud/score").text = "Score: " + str(score)

puppet func create_blood(pos):
	if pos == null:
		pos = self.global_transform.origin
	var splatter = preloader.splatter.instance()
	splatter.color = blood_color
	game.world.add_child(splatter)
	splatter.global_transform.origin = pos
	for i in 4:
		var state = get_world().direct_space_state
		randomize()
		var rand_dir = Vector3(pos.x + rand_range(-100, 100), pos.y - 100, pos.z + rand_range(-100, 100))
		var result = state.intersect_ray(pos, rand_dir)
		if result:
			if result.collider is StaticBody:
				var stain = preloader.stain.instance()
				stain.color = blood_color
				game.world.add_child(stain)
				stain.global_transform.origin = result.position + result.normal * 0.01
				stain.look_at(result.position - result.normal, Vector3(1, 1, 0))
				stain.rotation.y = (stain.translation - pos).x
				var rand_scale = randi() % 2 + 0.5
				stain.scale = Vector3(rand_scale, rand_scale, rand_scale)

func process_rotations(x : float, y : float):
	head.rotate_x(deg2rad(y))
	rotate_y(deg2rad(x))
	var camera_rot = head.rotation_degrees
	camera_rot.x = clamp(camera_rot.x, -85, 85)
	head.rotation_degrees = camera_rot
	if can_send:
		rpc_unreliable_id(1, "update_rotation", rotation, head.rotation)
		can_send = false
		send_timer.start()

#func process_animations(delta):
#	if state.undead:
#		if state.kicking:
#			anim_state_machine.travel("zombie_attack_" + str(randi() % 6 + 1))
#		elif state.agony:
#			anim_state_machine.travel("zombie_agony")
#		else:
#			anim_state_machine.travel("zombie_loco")
#		anim_tree["parameters/state_machine/zombie_loco/blend_position"] = lerp(anim_tree["parameters/state_machine/zombie_loco/blend_position"], input_movement_vector.y, delta * accel)
#	elif state.water:
#		anim_state_machine.travel("water_loco")
#		anim_tree["parameters/state_machine/water_loco/blend_position"] = lerp(anim_tree["parameters/state_machine/water_loco/blend_position"], input_movement_vector.y, delta * accel)
#	elif state.climbing:
#		anim_state_machine.travel("climb_loco")
#		anim_tree["parameters/state_machine/climb_loco/blend_position"] = lerp(anim_tree["parameters/state_machine/climb_loco/blend_position"], input_movement_vector.y, delta * accel)
#	elif state.flying:
#		anim_state_machine.travel("t_pose")
#	elif !state.grounded:
#		anim_state_machine.travel("rifle_jump_loop")
#	else:
#		if state.dancing:
#			anim_state_machine.travel("dance")
#		elif state.kicking:
#			anim_state_machine.travel("kick")
#		elif state.waving:
#			anim_state_machine.travel("wave")
#		else:
#			anim_state_machine.travel("rifle_loco")
#		anim_tree["parameters/state_machine/rifle_loco/blend_position"] = anim_tree["parameters/state_machine/rifle_loco/blend_position"].linear_interpolate(input_movement_vector, delta * accel)

func _on_send_timeout():
	can_send = true

func _on_char_state_changed(s, b):
	if s == "kick_hit" and b == true:
		rpc_id(1, "register_kick")
		set_state("kicking", false)

#func enable_ragdoll_collisions(b):
#	for i in character.get_node("skeleton").get_children():
#		if i is PhysicalBone:
#			i.get_node("collision_shape").disabled = !b
