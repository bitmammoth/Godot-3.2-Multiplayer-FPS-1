extends Spatial
class_name BaseWeapon

var shooter : BasePlayer
var camera : Camera
var head : Spatial

var cmd = {
	primary_fire = false,
	secondary_fire = false
}

func _ready():
	shooter = get_owner()
	head = shooter.get_node("head")
	camera = shooter.get_node("head/camera")

func _physics_process(_delta):
	# Fix
	if !visible:
		cmd.primary_fire = false
		shooter.cmd.primary_fire = false

func get_material_name(body):
	if body.physics_material_override:
		if body.physics_material_override.get_name() != null:
			return body.physics_material_override.get_name()
	else:
		return "concrete"

func random_spread(spread):
	randomize()
	return Vector3(rand_range(-spread, spread), rand_range(-spread, spread), rand_range(-spread, spread))
