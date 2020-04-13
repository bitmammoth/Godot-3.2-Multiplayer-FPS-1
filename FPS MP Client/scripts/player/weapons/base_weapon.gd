extends Spatial
class_name BaseWeapon

# Base class for weapons.

# Reference to a player that shoots the weapon.
var shooter : BasePlayer

func _ready():
	shooter = get_owner()

func _physics_process(_delta):
	pass

puppet func create_impact(parent_path : String, pos : Vector3, norm : Vector3, material : String):
	var parent = get_node(parent_path)
	var impact = preloader.impacts[material].instance()
	parent.add_child(impact)
	impact.global_transform.origin = pos + norm * 0.01
	impact.look_at(pos - norm, Vector3(1, 1, 0))
	impact.rotation = Vector3(impact.rotation.x, impact.rotation.y, rand_range(-1, 1))
	var rand_scale = rand_range(0.75, 1.25)
	impact.scale = Vector3(rand_scale, rand_scale, rand_scale)
	var debris = preloader.debris.instance()
	game.world.add_child(debris)
	debris.color = Color(0.2, 0.2, 0.2)
	debris.global_transform.origin = pos
