extends Node
class_name StackFSM

var stack : Array

func _physics_process(_delta):
	var current_state = get_current_state()
	if current_state != null:
		if get_parent().has_method(current_state):
			var param = get_param(current_state)
			if param != null:
				get_parent().call(current_state, param)
			else:
				get_parent().call(current_state)

func pop_state():
	return stack.pop_back()

func push_state(state, param):
	if get_current_state() != state:
		stack.push_back([state, param])

func get_current_state():
	if stack.size() > 0:
		return stack[stack.size() - 1][0]
	else:
		return null

func get_param(state):
	for i in stack:
		if i[0] == state:
			return i[1]

func has_state(state):
	var has = false
	for i in stack:
		if i[0] == state:
			has = true
	return has
