extends BaseWeapon
class_name Boomstick

onready var flash = get_node("flash")
onready var flash_timer = get_node("flash/timer")

func _ready():
	flash_timer.connect("timeout", self, "_on_flash_timeout")

puppet func fire():
	get_node("sounds/fire").play()
	flash.visible = true
	flash_timer.start()
	if shooter.state.grounded == false:
		shooter.vel = shooter.camera.global_transform.basis.z * 15

func _on_flash_timeout():
	flash.visible = false
