extends Camera

# General purpose configurable camera script
# later getting things like "follow player" for camera at stations

export var fly_speed = 0.5
export var mouse_sensitivity = 10
export var camera_factor = 0.1 ## The Factor, how much the camera moves at acceleration and braking

var yaw = 0
var pitch = 0

# whether the camera is tied to a point or can move around with wasd
export var fixed = true

# whether to apply or not acceleration effect on camera
export var accel = false

# Saves the camera position at the beginning. The Camera Position will be changed, when the train is accelerating, or braking
onready var camera_zero_transform = transform

# Reference delta at 60fps
const ref_delta = 0.0167 # 1.0 / 60


onready var world = find_parent("World")

# used for accel if any.
onready var player = world.find_node("Player")

func _ready():
	# Initialization here
	self.set_process_input(true)
	self.set_process(true)
	#set mouse position


func _enter_tree():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _exit_tree():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

var mouse_motion = Vector2(0,0)

func _input(event):
	if current and event is InputEventMouseMotion:
		mouse_motion = mouse_motion + event.relative

onready var camera_y = rotation_degrees.y - 90.0
onready var camera_x = -rotation_degrees.x

func _process(delta):
	if not current:
		pass
	#mouse movement

	if not Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED and not Root.mobile_version:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	if mouse_motion.length() > 0:
		var motion_factor = (ref_delta / delta * ref_delta) * mouse_sensitivity
		camera_y += -mouse_motion.x * motion_factor
		camera_x += +mouse_motion.y * motion_factor
		if camera_x > 85: camera_x = 85
		if camera_x < -85: camera_x = -85
		rotation_degrees.y = camera_y +90
		rotation_degrees.x = -camera_x
		mouse_motion = Vector2(0,0)


	if accel and player:
		var current_real_acceleration = player.current_real_acceleration
		var speed = player.speed
		var soll_camera_position = camera_zero_transform.origin.x + (current_real_acceleration * -camera_factor)
		if speed == 0:
			soll_camera_position = camera_zero_transform.origin.x
		var missing_camera_position = translation.x - soll_camera_position
		translation.x -= missing_camera_position * delta

	if not fixed:
		var delta_fly_speed = (delta / ref_delta) * fly_speed

		if(Input.is_key_pressed(KEY_W)):
			self.set_translation(self.get_translation() - get_global_transform().basis*Vector3(0,0,1) * delta_fly_speed)
		if(Input.is_key_pressed(KEY_S)):
			self.set_translation(self.get_translation() - get_global_transform().basis*Vector3(0,0,1) * -delta_fly_speed)
		if(Input.is_key_pressed(KEY_A) and not Input.is_key_pressed(KEY_CONTROL)):
			self.set_translation(self.get_translation() - get_global_transform().basis*Vector3(1,0,0) * delta_fly_speed)
		if(Input.is_key_pressed(KEY_D)):
			self.set_translation(self.get_translation() - get_global_transform().basis*Vector3(1,0,0) * -delta_fly_speed)
		if(Input.is_key_pressed(KEY_SHIFT)):
			fly_speed = 2
		else:
			fly_speed = 0.5
