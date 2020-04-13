extends BasePlayer
class_name Player

# Here we are executing commands to the remote player on the server.

var MOUSE_SENSITIVITY = 0.05
var TOUCH_SENSITIVITY = 1.75
var INVERSION = -1

onready var holder = get_node("head/holder")

# Touch screen
onready var right_ball = get_node("touch/track_right/track/ball")
onready var left_ball = get_node("touch/track_left/track/ball")

# Aim helper. Used in the mobile version. Basically an auto-aim.
var aim_target : BasePlayer
const AIM_RAY = 1000

func _ready():
	$character.set_visible_to_camera(false)
	var _state_changed = connect("state_changed", self, "_on_state_changed")
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	touch_mode = OS.has_touchscreen_ui_hint()
	if touch_mode:
		rpc_id(1, "set_touch_mode", true)

func _physics_process(delta):
	if !state.kicking:
		process_input(delta)
	
	# Aim helper
	if touch_mode and aim_target != null:
		if !aim_target.state.dead:
			var t = camera.global_transform.looking_at(aim_target.translation + Vector3(0, 0.5, 0), Vector3.UP)
			var view_target_rot = t.basis.get_euler()
			head.rotation.x = lerp_angle(head.rotation.x, view_target_rot.x, delta * 10)
			rotation.y = lerp_angle(self.rotation.y, view_target_rot.y, delta * 10)
		else:
			aim_target = null
		
func _on_state_changed(s, _b):
	match s:
		"dead":
			holder.visible = !state[s]
			if state[s]:
				game.main_scene.display_message("You are dead! Respawning...")
#				enable_ragdoll_collisions(true)
				$character.set_visible_to_camera(true)
#				$character/skeleton.physical_bones_start_simulation()
#				$character/skeleton/physical_bone_hips.apply_central_impulse(last_impulse)
				$shape.disabled = true
				aim_target = null
			else:
#				enable_ragdoll_collisions(false)
				$character.set_visible_to_camera(false)
#				$character/skeleton.physical_bones_stop_simulation()
				$shape.disabled = false
		"water":
			if state[s] and !$sounds/water.playing:
				$sounds/water.play()
				AudioServer.set_bus_effect_enabled(1, 0, true)
			else:
				$sounds/water.stop()
				AudioServer.set_bus_effect_enabled(1, 0, false)

puppet func update_puppet(_pos : Vector3, _rot : Vector3, _h_rot : Vector3, _v : Vector3, _a : float, _imv : Vector2):
	pass

func process_input(_delta):
	# Input
	if Input.is_action_pressed("move_forward"):
		cmd.move_forward = true
		rpc_unreliable_id(1, "execute_command", "move_forward", true)
	else:
		cmd.move_forward = false
		rpc_unreliable_id(1, "execute_command", "move_forward", false)
	if Input.is_action_pressed("move_backward"):
		cmd.move_backward = true
		rpc_unreliable_id(1, "execute_command", "move_backward", true)
	else:
		cmd.move_backward = false
		rpc_unreliable_id(1, "execute_command", "move_backward", false)
	if Input.is_action_pressed("move_left"):
		cmd.move_left = true
		rpc_unreliable_id(1, "execute_command", "move_left", true)
	else:
		cmd.move_left = false
		rpc_unreliable_id(1, "execute_command", "move_left", false)
	if Input.is_action_pressed("move_right"):
		cmd.move_right = true
		rpc_unreliable_id(1, "execute_command", "move_right", true)
	else:
		cmd.move_right = false
		rpc_unreliable_id(1, "execute_command", "move_right", false)
	if Input.is_action_pressed("move_jump"):
		cmd.move_jump = true
		rpc_unreliable_id(1, "execute_command", "move_jump", true)
	else:
		cmd.move_jump = false
		rpc_unreliable_id(1, "execute_command", "move_jump", false)
	if Input.is_action_pressed("primary_fire"):
		rpc_unreliable_id(1, "execute_command", "primary_fire", true)
	else:
		rpc_unreliable_id(1, "execute_command", "primary_fire", false)
	if Input.is_action_pressed("secondary_fire"):
		rpc_unreliable_id(1, "execute_command", "secondary_fire", true)
	else:
		rpc_unreliable_id(1, "execute_command", "secondary_fire", false)
	if Input.is_action_just_released("next_weapon"):
		rpc_unreliable_id(1, "execute_command", "next_weapon", true)
	if Input.is_action_pressed("dance"):
		rpc_unreliable_id(1, "execute_command", "dance", true)
	else:
		rpc_unreliable_id(1, "execute_command", "dance", false)
	if Input.is_action_pressed("kick"):
		rpc_unreliable_id(1, "execute_command", "kick", true)
	else:
		rpc_unreliable_id(1, "execute_command", "kick", false)
	if Input.is_action_pressed("wave"):
		rpc_unreliable_id(1, "execute_command", "wave", true)
	else:
		rpc_unreliable_id(1, "execute_command", "wave", false)
	
	# Capturing/freeing the cursor
	if Input.is_action_just_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# Recapture the mouse on left click
	if Input.is_action_just_pressed("primary_fire") and Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# Touch movement
	if touch_mode:
		input_movement_vector.x = left_ball.get_value().x
		input_movement_vector.y = -left_ball.get_value().y
		var v = right_ball.get_value()
		process_rotations(v.x * TOUCH_SENSITIVITY * INVERSION, v.y * TOUCH_SENSITIVITY * INVERSION)
		rpc_unreliable_id(1, "touch_movement", left_ball.get_value().x, -left_ball.get_value().y)
	
func _input(event):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED and !touch_mode:
		process_rotations(event.relative.x * MOUSE_SENSITIVITY * INVERSION, event.relative.y * MOUSE_SENSITIVITY * INVERSION)
	
	# Aim helper
	if touch_mode and !state.dead:
		if event != InputEventScreenDrag and event is InputEventScreenTouch:
#			var screen_center = get_viewport().size / 2
			var state = get_world().direct_space_state
			var from = camera.project_ray_origin(event.position)
			var to = from + camera.project_ray_normal(event.position) * AIM_RAY
			var result = state.intersect_ray(from, to, [self], 1, true, false)
			if result:
				if result.collider is BasePlayer:
					aim_target = result.collider
