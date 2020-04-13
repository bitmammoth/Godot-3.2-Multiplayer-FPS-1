extends BaseWeapon
class_name Boomstick

var pellets = 6
var spread = 60

const RAY_LENGTH = 500
const KNOCKBACK = 10

onready var timer_cooldown = get_node("cooldown")
var can_fire : bool = true

func _ready():
	timer_cooldown.connect("timeout", self, "_on_fire_timeout")

func _physics_process(_delta):
	process_commands()

func process_commands():
	if cmd.primary_fire and can_fire and visible:
		fire_gun()

func _on_fire_timeout():
	can_fire = true

func fire_gun():
	rpc("fire")
	can_fire = false
	var screen_center = get_viewport().size / 2
	var state = get_world().direct_space_state
	var from : Vector3
	var to : Vector3
	if shooter.has_method("check_player"):
		from = camera.project_ray_origin(screen_center)
	if shooter.has_method("check_bot"):
		from = camera.global_transform.origin
	for n in pellets:
		if shooter.has_method("check_player"):
			to = from + camera.project_ray_normal(screen_center) * RAY_LENGTH + random_spread(spread)
		if shooter.has_method("check_bot"):
			to = from + (camera.global_transform.basis.z * -RAY_LENGTH) + random_spread(spread)
		var result = state.intersect_ray(from, to, [self, shooter], 1, true, false)
		if result:
			var dir = -camera.global_transform.basis.z.normalized()
			var pos = (global_transform.origin - result.collider.global_transform.origin).normalized()
			if result.collider is PhysicalBone:
				result.collider.apply_impulse(pos, dir * 2)
			if result.collider is RigidBody:
				result.collider.apply_impulse(pos, dir * 2)
				rpc_unreliable("create_impact", result.collider.get_path(), result.position, result.normal, get_material_name(result.collider))
			if result.collider is StaticBody:
				rpc_unreliable("create_impact", game.world.get_path(), result.position, result.normal, get_material_name(result.collider))
			if result.collider is BasePlayer:
				result.collider.hit(25, shooter, result.position)
				result.collider.set_velocity(dir * KNOCKBACK)
	timer_cooldown.start()
	if shooter.state.grounded == false:
		shooter.vel = camera.global_transform.basis.z * 15
