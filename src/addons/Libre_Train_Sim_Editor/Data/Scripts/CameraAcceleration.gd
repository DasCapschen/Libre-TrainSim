class_name CameraAcceleration
extends Node

var previous_position: Vector3
var previous_speed: Vector3
var parent

export(float, 0.0, 1.0) var acceleration_strength = 0.05
export(float, 0.0, 1.0) var smoothing = 0.75

# these must be separate if camera shake is also used!
# without camera shake, they can be the same!
export(NodePath) var camera_to_affect
export(NodePath) var node_providing_acceleration

var _camera
var _acc_node

func _ready():
	_camera = get_node(camera_to_affect)
	_acc_node = get_node(node_providing_acceleration)
	
	previous_position = _acc_node.global_transform.origin
	previous_speed = Vector3(0,0,0)


func _process(delta: float) -> void:
	var speed = (_acc_node.global_transform.origin - previous_position)/delta
	var acceleration = (speed - previous_speed)/delta
	if acceleration.length() < 0.01:
		acceleration = Vector3(0,0,0)
	
	var soll_position = Vector3(0,0,0)
	var soll_rotation = Vector3(0,0,0)
	
	soll_position = -acceleration * acceleration_strength
	
	# smooth the motion
	_camera.translation = _camera.translation.linear_interpolate(soll_position, 1.0-smoothing)
	
	previous_position = _acc_node.global_transform.origin
	previous_speed = speed

