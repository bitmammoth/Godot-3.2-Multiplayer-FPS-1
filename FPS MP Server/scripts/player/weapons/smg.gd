extends BaseWeapon
class_name SMG

onready var timer_fire = get_node("cooldown")
var can_fire : bool = true

const RAY_LENGTH = 1000
const KNOCKBACK = 5

func _ready():
	timer_fire.connect("timeout", self, "_on_fire_timeout")

func _physics_process(_delta):
	# Fix
	process_commands()

func process_commands():
	if cmd.primary_fire and can_fire and visible:
		fire_gun()

func _on_fire_timeout():
	can_fire = true

func fire_gun():
	can_fire = false
	rpc_unreliable("fire")
	var screen_center = get_viewport().size / 2
	var state = get_world().direct_space_state
	var from : Vector3
	var to : Vector3
	if shooter.has_method("check_player"):
		from = camera.project_ray_origin(screen_center)
		to = from + camera.project_ray_normal(screen_center) * RAY_LENGTH
	if shooter.has_method("check_bot"):
		from = camera.global_transform.origin
		to = from + camera.global_transform.basis.z * -RAY_LENGTH
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
			result.collider.hit(10, shooter, result.position)
			result.collider.set_velocity(dir * KNOCKBACK)
#			rpc_unreliable("create_impact", result.collider.get_path(), result.position, result.normal)
	timer_fire.start()
