class_name CameraShakePlayer
extends Node

export(NodePath) var camera_to_affect
var _camera

export(float, 0.0, 1.0) var smoothing = 0.75

# NOTE: after adding a shake, you can still modify it :)
#       because _data only keeps a reference, not a copy!
var _data = []

# stops all and any shaking
func stop():
	_data = []

# adds another shake to play
# good for overlaying multiple shakes
func add(shake: CameraShake):
	_data.append({"shake": shake, "start": _get_time()})


# play this shake only. immediately stops all other shakes
func play(shake: CameraShake):
	stop()
	add(shake)

func _ready():
	_camera = get_node(camera_to_affect)

func _process(delta: float) -> void:
	var index = 0
	
	var total_position = Vector3(0,0,0)
	var total_rotation = Vector3(0,0,0)
	
	while index < _data.size():
		var start = _data[index].start
		var shake = _data[index].shake
		
		# if shake finished
		if shake.duration_type == shake.DurationType.DURATION \
		and start + shake.duration > _get_time():
			_data.remove(index)
			continue
		# else:
		total_position += _get_next_position_for_shake(shake)
		total_rotation += _get_next_rotation_for_shake(shake)
		index += 1
	
	_camera.translation = _camera.translation.linear_interpolate(total_position, 1.0-smoothing)
	_camera.rotation = _camera.rotation.linear_interpolate(total_rotation, 1.0-smoothing)


func _get_next_position_for_shake(shake) -> Vector3:
	var position = Vector3()
	
	if shake.shake_type == shake.ShakeType.Random:
		pass
	elif shake.shake_type == shake.ShakeType.Sine:
		pass
	elif shake.shake_type == shake.ShakeType.Noise:
		pass
	
	return position


func _get_next_rotation_for_shake(shake) -> Vector3:
	return Vector3()


func _get_time():
	return OS.get_ticks_msec()/1000.0
