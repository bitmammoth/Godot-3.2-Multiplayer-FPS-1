extends Node

# This script preloads data like sounds and scenes for creating impact effects.
# Based on material.

# Impacts
onready var impacts = {
	concrete = preload("res://scenes/effects/impact.tscn"),
	metal = preload("res://scenes/effects/impact_metal.tscn"),
	soil = preload("res://scenes/effects/impact.tscn")
}

onready var debris = preload("res://scenes/effects/debris.tscn")
onready var stain = preload("res://scenes/effects/stain.tscn")
onready var splatter = preload("res://scenes/effects/splatter.tscn")

# Footsteps
onready var footsteps = {
	generic = [
		preload("res://sounds/footsteps/generic_1.wav"),
		preload("res://sounds/footsteps/generic_2.wav"),
		preload("res://sounds/footsteps/generic_3.wav"),
		preload("res://sounds/footsteps/generic_4.wav"),
		preload("res://sounds/footsteps/generic_5.wav"),
		preload("res://sounds/footsteps/generic_6.wav")
	],
	metal = [
		preload("res://sounds/footsteps/metal_1.wav"),
		preload("res://sounds/footsteps/metal_2.wav"),
		preload("res://sounds/footsteps/metal_3.wav"),
		preload("res://sounds/footsteps/metal_4.wav"),
		preload("res://sounds/footsteps/metal_5.wav"),
		preload("res://sounds/footsteps/metal_6.wav")
	],
	soil = [
		preload("res://sounds/footsteps/soil_1.wav"),
		preload("res://sounds/footsteps/soil_2.wav"),
		preload("res://sounds/footsteps/soil_3.wav"),
		preload("res://sounds/footsteps/soil_4.wav"),
		preload("res://sounds/footsteps/soil_5.wav"),
		preload("res://sounds/footsteps/soil_6.wav")
	],
	ladder = [
		preload("res://sounds/footsteps/metal_1.wav"),
		preload("res://sounds/footsteps/metal_2.wav"),
		preload("res://sounds/footsteps/metal_3.wav"),
		preload("res://sounds/footsteps/metal_4.wav"),
		preload("res://sounds/footsteps/metal_5.wav"),
		preload("res://sounds/footsteps/metal_6.wav")
	]
}

# Impact sounds
onready var hit_sounds = {
	concrete = [
		preload("res://sounds/weapons/impact_concrete_1.wav")
	],
	metal = [
		preload("res://sounds/physics/metal/metal_hit_1.wav"),
		preload("res://sounds/physics/metal/metal_hit_2.wav"),
		preload("res://sounds/physics/metal/metal_hit_3.wav"),
		preload("res://sounds/physics/metal/metal_hit_4.wav"),
		preload("res://sounds/physics/metal/metal_hit_5.wav"),
		preload("res://sounds/physics/metal/metal_hit_6.wav")
	]
}
onready var slide_sounds = {
	concrete = preload("res://sounds/physics/metal/metal_slide.wav"),
	metal = preload("res://sounds/physics/metal/metal_slide.wav")
}
