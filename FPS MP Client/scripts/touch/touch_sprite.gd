extends Sprite

# A sprite visilbe only on touch screens.

func _ready():
	visible = OS.has_touchscreen_ui_hint()
