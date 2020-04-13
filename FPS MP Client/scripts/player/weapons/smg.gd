extends BaseWeapon
class_name SMG

onready var flash = get_node("flash")
onready var flash_timer = get_node("flash/timer")

func _ready():
	var _flash_timeout = flash_timer.connect("timeout", self, "_on_flash_timeout")

puppet func fire():
	get_node("sounds/fire").play()
	flash.visible = true
	flash_timer.start()

func _on_flash_timeout():
	flash.visible = false
