extends BaseWeapon
class_name Grabbity

const RAY_LENGTH = 50

onready var pin = get_node("pin")
onready var joint = get_node("pin/joint")
onready var grabbity_cooldown = get_node("cooldown")
var can_grab : bool = true
var can_release : bool = false
var grabbity_target : RigidBody

func _ready():
	var _grabbity_timeout = grabbity_cooldown.connect("timeout", self, "_on_grabbity_timeout")

func _physics_process(_delta):
	# Firing
	process_commands()
	process_grabbity()

func process_commands():
	if visible:
		if cmd.primary_fire:
			grab(false, false, true)
		if cmd.secondary_fire:
			if grabbity_target == null:
				can_release = false
				grab(true, false, false)
			elif can_release:
				grab(false, true, false)
		else:
			can_release = true
			rpc_unreliable("grab", false, false, false)
	else:
		grab(false, true, false)
	if shooter.state.dead:
		grab(false, true, false)

func grab(pull : bool, release : bool, throw : bool):
	if pull:
		if grabbity_target == null:
			var screen_center = get_viewport().size / 2
			var state = get_world().direct_space_state
			var from = camera.project_ray_origin(screen_center)
			var to = from + camera.project_ray_normal(screen_center) * RAY_LENGTH
			var result = state.intersect_ray(from, to, [self, shooter], 1, true, false)
			if result:
				if result.collider is RigidBody:
					var dir = pin.global_transform.basis.z.normalized()
#					var pos = (global_transform.origin - result.collider.global_transform.origin).normalized()
					if result.collider.global_transform.origin.distance_to(shooter.global_transform.origin) > 3:
						result.collider.linear_velocity = dir * 8
						rpc_unreliable("grab", true, false, false)
					elif can_grab:
						result.collider.global_transform.origin = pin.global_transform.origin
#						result.collider.mode = RigidBody.MODE_STATIC
						joint.set_node_a(pin.get_path())
						joint.set_node_b(result.collider.get_path())
						grabbity_target = result.collider
						rpc_unreliable("grab", false, true, false)
						can_grab = false
						grabbity_cooldown.start()
					else:
						rpc_unreliable("grab", false, false, false)
	else:
		rpc_unreliable("grab", false, false, false)
	if release and grabbity_target:
		grabbity_target.mode = RigidBody.MODE_RIGID
		grabbity_target.grabbed = false
		joint.set_node_a("")
		joint.set_node_b("")
		rpc_unreliable("grab", false, false, false)
		grabbity_target = null
		can_grab = false
		grabbity_cooldown.start()
	if throw and grabbity_target:
		grabbity_target.mode = RigidBody.MODE_RIGID
		grabbity_target.grabbed = false
		grabbity_target.apply_central_impulse(-camera.global_transform.basis.z * 50)
		joint.set_node_a("")
		joint.set_node_b("")
		rpc_unreliable("grab", false, false, true)
		grabbity_target = null
		can_grab = false
		grabbity_cooldown.start()

func process_grabbity():
	if grabbity_target != null:
#		grabbity_target.global_transform.origin = pin.global_transform.origin
		grabbity_target.grabbed = true

func _on_grabbity_timeout():
	can_grab = true
