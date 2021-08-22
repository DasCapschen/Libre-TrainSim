extends Spatial

################################################################################
## To Content-Creators: DO NOT EDIT THIS SCRIPT!! This Script will be overwritten by the game.
## For your own scripting please use the attached Node "SpecificScripting"
################################################################################

################################################################################
## Interesting Variables for addOn Creators, which could be read out, (or set).
var soll_command = -1 # The input by the player. (0: Nothing, 1: Full acceleration, -1: Full Break). |soll_command| should be lesser than 1.
export (float) var acceleration # Unit: m/(s*s) 
export (float) var brake_acceleration # Unit: m/(s*s)
export (float) var friction # (-> Speed = Speed - Speed * fritction (*delta) )
export (float) var length # Train length. # Used in Train Stations for example
export (float) var speed_limit # Maximum Speed, the train can drive. (Unit: km/h)
export (int) var control_type = ControlType.COMBINED # 0: Arrowkeys (Combi Control), 1: WASD (Separate brake and speed)
export (bool) var electric = true
var pantograph = false   ## Please just use this variable, if to check, if pantograph is up or down. true: up
var pantograph_up = false ## is true, if pantograph is rising.
var engine = false ## Describes wether the engine of the train is running or not.
var voltage = 0 # If this value = 0, the train wont drive unless you press ingame "B". If voltage is "up", then its at 15 by default. Unit (kV)
export (float) var pantograph_time = 5
var speed = 0 # Initiats the speed. (Unit: m/s) ## You can convert it with var kmhSpeed = Math.speed2kmh(speed)
onready var current_speed_limit = speed_limit # Unit: km/h # holds the current speedlimit
var hard_over_speeding = false # If Speed > speedlimit + 10 this is set to true
var command = -1 # If Command is < 0 the train will brake, if command > 0 the train will accelerate. Set by the player with Arrow Keys.
var technical_soll = 0 # Soll Command. This variable describes the "aim" of command
var blocked_acceleration = false ## If true, then acceleration is blocked. e.g.  brakes, dooors, engine,....
var acc_roll = 0 # describes the user input, (0 to 1)
var brake_roll = -1 # describes the user input (0 to -1)
var current_acceleration = 0 # Current Acceleration in m/(s*s) (Can also be neagtive) - JJust from brakes and engines
var current_real_acceleration = 0
var time = [23,59,59] ## actual time. Indexes: [0]: Hour, [1]: Minute, [2]: Second
var enforced_braking = false 
var overrun_red_signal = false
## set by the world scneario manager. Holds the timetable. PLEASE DO NOT EDIT THIS TIMETABLE! The passed variable displays, if the train was already there. (true/false)
var stations = {"node_name" : [], "station_name" : [], "arrival_time" : [], "departure_time" : [], "halt_time" : [], "stop_type" : [], "waiting_persons" : [], "leaving_persons" : [], "passed" : [], "arrival_announce_path" : [], "departure_announce_path" : [], "approach_announce_path" : []} 

var reverser = ReverserState.NEUTRAL

## For current Station:
var current_station_name = "" # If we are in a station, this variable stores the current station name
var whole_train_not_in_station = false # true if speed = 0, and the train is not fully in the station
var is_in_station = false # true if the train speed = 0, the train is fully in the station, and doors were opened. - Until depart Message
var real_arrival_time = time # Time is set if train successfully arrived
var station_length = 0 # stores the stationlength
var station_halt_time = 0 # stores the minimal halt time from station 
var arrival_time = time # stores the arrival time. (from the timetable)
var depature_time = time # stores the departure time. (from the timetable)
var platform_side = PlatformSide.NONE # Stores where the plaform is.

export var doors = true # If the train has doors, I presume?
export var doors_closing_time = 7
var door_status = DoorState.CLOSED

export var braking_speed = 0.3
export var brake_release_speed = 0.2
export var acceleration_speed = 0.2
export var acceration_release_speed = 0.5

export var is_sifa_enabled = true
var sifa = false # If this is true, the player has to press the sifa key (Space)

export (String) var description = ""
export (String) var author = ""
export (String) var release_date = ""
export (String) var screenshot_path = ""

## 0: Free View 1: Cabin View, 2: Outer View
enum CameraState {
	FREE_VIEW = 0,
	CABIN_VIEW = 1,
	OUTER_VIEW = 2
}
var camera_state = CameraState.CABIN_VIEW

var camera_mid_point = Vector3(0,2,0)
var camera_y = 90
var camera_x = 0

var mouse_sensitivity = 10

var camera_distance = 20
var camera_distance_changed = false
const CAMERA_DISTANCE_MIN = 5
const CAMERA_DISTANCE_MAX = 200

var ref_fov = 42.7 # reference FOV for camera movement multiplier
var camera_fov = 42.7 # current FOV
var camera_fov_soll = 42.7 # FOV user wants
const CAMERA_FOV_MIN = 20
const CAMERA_FOV_MAX = 60

var sound_mode = 0 # 0: Interior, 1: Outer   ## Not currently used


export (Array, NodePath) var wagons 
export var wagon_distance = 0.5 ## Distance between the wagons
var wagons_visible = false
var wagon_instances = [] # Over this the wagons can be accessed

var automatic_driving = false # Autopilot
var soll_speed = 0 ## Unit: km/h
var soll_speed_tolerance = 4 # Unit km/h
var soll_speed_enabled = false ## Automatic Speed handlement

var next_signal = null ## Type: Node (object)
var distance_to_next_signal = 0
var next_speed_limit_node = null ## Type: Node (object)
var distance_to_next_speed_limit = 0

var ai = false # It will be set by the scenario manger from world node. -> Every train which is not controlled by player has this value = true.
var despawn_rail = "" ## If the AI Train reaches this rail, he will despawn.
var rendering = true
var despawning = false
var initial_speed = -1 ## Set by the scenario manager form the world node. Only works for ai. When == -1, it will be ignored

var front_light = false
var inside_light = false

var last_driven_signal = null ## In here the reference of the last driven signal_passed is saved

## For Sound:
var current_rail_radius = 0

export (float) var sound_isolation = -8

## callable functions:
# send_message()
# show_textbox_message(string)
################################################################################


var world # Node Reference to the world node.

export var camera_factor = 1 ## The Factor, how much the camaere moves at acceleration and braking
export var camera_shaking_factor = 1.0 ## The Factor how much the camera moves at high speeds
var start_position # on rail, given by scenario manager in world node
var forward = true # does the train drive at the rail direction, or against it? 
var debug  ## used for driving fast at the track, if true. Set by world node. Set only for Player Train
var route # String conataining all importand Railnames for e.g. switches. Set by the scenario manager of the world
var distance_on_rail = 0  # It is the current position on the rail.
var distance_on_route = 0 # Current position on the whole route
var current_rail # Node Reference to the current rail on which we are driving.
var route_index = 0 # Index of the baked route Array.
var next_signal_index = 0 # Index of NEXT signal_passed on baked route signal_passed array
var start_rail # rail, on which the train is starting. Set by the scenario manger of the world

# Reference delta at 60fps
const ref_delta = 0.0167 # 1.0 / 60



onready var camera_node = $Camera
var camera_zero_transform # Saves the camera position at the beginning. The Camera Position will be changed, when the train is accelerating, or braking

func ready(): ## Called by World!
	
	# capture mouse
	# TODO: input mapping to release mouse for interaction?
	# FIXME: mouse is visible in Grey Train, but not in Red Train, why?
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	if not ai:
		camera_zero_transform = camera_node.transform
		camera_x = -$Camera.rotation_degrees.x
		camera_y = $Camera.rotation_degrees.y
		$Camera.current = true
	world = get_parent().get_parent()
	
	route = route.split(" ")
	bake_route()
	
	if Root.easy_mode or ai:
		pantograph = true
		control_type = ControlType.COMBINED
		is_sifa_enabled = false
		reverser = ReverserState.FORWARD

	if not doors:
		door_status = DoorState.CLOSED
	
	if not electric:
		pantograph = true
		voltage = 15
	
	if is_sifa_enabled:
		$Sound/SiFa.play()
	
	## Get driving handled
	## Set the Train at the beginning of the rail, and after that set the distance on the Rail forward, which is standing in var start_position
	distance_on_rail = start_position
	current_rail = world.get_node("Rails/"+start_rail)
	if current_rail == null:
		printerr("Can't find Rail. Check the route of the Train "+ self.name)
		return
	if forward:
		distance_on_route = start_position
	else:
		distance_on_route = current_rail.length - start_position

	## Set Train to Route:
	if forward:
		self.transform = current_rail.get_transform_at_rail_distance(distance_on_rail)
	else:
		self.transform = current_rail.get_transform_at_rail_distance(distance_on_rail)
		rotate_object_local(Vector3(0,1,0), deg2rad(180))
	
	if debug and not ai: 
		command = 0
		soll_command = 0
	
	## get chunks handled:
	if not ai:
		world.active_chunk = world.pos_to_chunk(self.translation) 
	
	spawn_wagons()
	
	## Prepare Signals:
	if not ai:
		set_signal_warn_limits()
		set_signal_afters()

		
		
	if ai:
		sound_mode = 1
		wagons_visible = true
		automatic_driving = true
		$Cabin.queue_free()
		$Camera.queue_free()
		$HUD.queue_free()
		camera_state = 1 # Not for the camera, for the components who want to see, if the player sees the train from the inside or outside. AI is seen from outside whole time ;)
		inside_light = true
		front_light = true
		
	print("Train " + name + " spawned sucessfully at " + current_rail.name)

var initial_switch_check = false
var process_long_delta = 0.5 # Definition of Period, every which seconds the function is called.
func process_long(delta): ## All functions in it are called every (process_long_delta * 1 second).
	update_next_signal(delta)
	update_next_speed_limit(delta)
	update_next_station(delta)
	check_despawn()
	check_speed_limit(delta)
	check_for_next_station(delta)
	check_for_player_help(delta)
	get_time()
	check_free_last_signal(delta)
	fix_obsolete_stations()
	check_visibility(delta)
	if automatic_driving:
		autopilot(delta)
	if name == "npc3":
		print(current_rail.name)
		print(distance_on_rail)
		
	if not initial_switch_check:
		update_switch_on_next_change()
		initial_switch_check = true



var process_long_timer = 0

func _process(delta):
	if Input.is_action_just_pressed("debug")  and not ai:
		debug = !debug
		if debug:
			send_message(TranslationServer.translate("DEBUG_MODE_ENABLED"))
			force_close_doors()
			force_pantograph_up()
			start_engine()
			reverser = ReverserState.FORWARD
			overrun_red_signal = false
			enforced_braking = false
			command = 0
			soll_command = 0
			
		else:
			overrun_red_signal = false
			enforced_braking = false
			command = 0
			soll_command = 0
			send_message(TranslationServer.translate("DEBUG_MODE_DISABLED"))
	
	process_long_timer += delta
	if process_long_timer > process_long_delta:
		process_long(process_long_timer)
		process_long_timer = 0
	
	if world == null:
		return
	
	if Root.easy_mode and not ai:
		if Input.is_action_just_pressed("autopilot"):
			jAudioManager.play_game_sound("res://Resources/Basic/Sounds/click.ogg")
			toggle_automatic_driving()
	
	
	if soll_speed_enabled:
		handle_soll_speed(delta)
	
	get_command(delta)
	
	get_speed(delta)
	
	if speed != 0:
		drive(delta)
	
	if despawning: 
		queue_free()

	if not ai:
		handle_camera(delta)

	if electric:
		check_pantograph(delta)
	
	if not debug and not ai:
		check_security()
	
	if doors:
		check_doors(delta)
	
	check_signals()
	
	check_station(delta)
	
	if is_sifa_enabled:
		check_sifa(delta)

	handle_input()
	
	current_rail_radius = current_rail.radius
	
	if not ai:
		update_train_audio_bus()
		
	handle_engine()
	
	check_overdriving_a_switch()
	

func handle_engine():
	if not pantograph:
		engine = false
	if not ai and Input.is_action_just_pressed("engine"):
		jAudioManager.play_game_sound("res://Resources/Basic/Sounds/click.ogg")
		if not engine:
			start_engine()
		else:
			stop_engine()
	
func start_engine():
	if pantograph:
		engine = true
		
func stop_engine():
	engine = false
	
func get_time():
	time = world.time

func _input(event):
	if ai:
		return
	if event is InputEventMouseMotion:
		mouse_motion = mouse_motion + event.relative
		
	if event.is_pressed():
		# zoom in
		if Input.is_mouse_button_pressed(BUTTON_WHEEL_UP):
			if camera_state == CameraState.CABIN_VIEW:
				camera_fov_soll = camera_fov + 5
			elif camera_state == CameraState.OUTER_VIEW:
				camera_distance += camera_distance*0.2
				camera_distance_changed = true
			# call the zoom function
		# zoom out
		if Input.is_mouse_button_pressed(BUTTON_WHEEL_DOWN):
			if camera_state == CameraState.CABIN_VIEW:
				camera_fov_soll = camera_fov - 5
			elif camera_state == CameraState.OUTER_VIEW:
				camera_distance -= camera_distance*0.2
				camera_distance_changed = true
			# call the zoom function
		
		camera_fov_soll = clamp(camera_fov_soll, CAMERA_FOV_MIN, CAMERA_FOV_MAX)
		camera_distance = clamp(camera_distance, CAMERA_DISTANCE_MIN, CAMERA_DISTANCE_MAX)

func get_command(delta):
	if control_type == ControlType.COMBINED and not automatic_driving: ## Combi Roll
		if Input.is_action_pressed("ui_up"):
			soll_command += 0.7 * delta
		if Input.is_action_pressed("ui_down"):
			soll_command -= 0.7 * delta
		if soll_command >= 1:
			soll_command = 1
		if soll_command <= -1:
			soll_command = -1
		if Input.is_action_pressed("ui_left"):
			soll_command = 0
		if Input.is_action_pressed("ui_right"):
			soll_command = 1
		if soll_command > 1: soll_command = 1
		if soll_command < -1: soll_command = -1
		
	elif control_type == ControlType.SEPARATE and not automatic_driving: ## Seperate Brake and Acceleration
		if Input.is_action_pressed("acc+"):
			acc_roll += 0.7 * delta
		if Input.is_action_pressed("acc-"):
			acc_roll -= 0.7 * delta
		if acc_roll > 1: acc_roll = 1
		if acc_roll < 0: acc_roll = 0
		if Input.is_action_pressed("brake+"):
			brake_roll -= 0.7 * delta
		if Input.is_action_pressed("brake-"):
			brake_roll += 0.7 * delta
		if brake_roll > 0: brake_roll = 0
		if brake_roll < -1: brake_roll = -1
		
		soll_command = acc_roll
		if brake_roll != 0: soll_command = brake_roll
		
	if soll_command == 0 or Root.easy_mode or ai and not enforced_braking:
		blocked_acceleration = false
	if command < 0 and not Root.easy_mode and not ai:
		blocked_acceleration = true
	if door_status & DoorState.BOTH: # if left or right or both
		blocked_acceleration = true
	if reverser == ReverserState.NEUTRAL:
		blocked_acceleration = true
		
	technical_soll = soll_command
	
	if technical_soll > 0 and blocked_acceleration:
		technical_soll = 0
	
	if enforced_braking and not debug:
		technical_soll = -1
	
	
	var missing_value = (technical_soll-command)
	if missing_value == 0: return
	if command > 0:
		if missing_value > 0:
			missing_value = acceleration_speed
		if missing_value < 0:
			missing_value = -acceration_release_speed
	if command < 0:
		if missing_value > 0:
			missing_value = brake_release_speed
		if missing_value < 0:
			missing_value = -braking_speed
	command = command + missing_value*delta
	if ((technical_soll-command) > 0 and missing_value < 0) or ((technical_soll-command) < 0 and missing_value > 0):
		command = technical_soll

	
	
func get_speed(delta):
	if initial_speed != -1 and not enforced_braking and command > 0 and ai:
		speed = initial_speed
		initial_speed = -1
		return
	var last_speed = speed
	## Slope:
	var current_slope = current_rail.get_height_rot(distance_on_rail)
	if not forward:
		current_slope = -current_slope
	if reverser == ReverserState.REVERSE:
		current_slope = -current_slope
	var slope_acceleration = -current_slope/10
	speed += slope_acceleration *delta
	
	var soll_acceleration
	if command < 0:
		## Brake:
		soll_acceleration = brake_acceleration * command
		if speed < 0:
			soll_acceleration = -soll_acceleration
	else:
		soll_acceleration = acceleration * command
	
	current_acceleration = soll_acceleration
	speed += soll_acceleration * delta
	
	speed -= speed *friction * delta
	
	if abs(speed) < 0.2 and command < 0 and abs(soll_acceleration) > abs(slope_acceleration):
		speed = 0
	
#	if speed < 0:
#		speed = 0
	if Math.speed_to_kmh(speed) > speed_limit:
		speed = Math.kmh_to_speed(speed_limit)
	if delta != 0:
		current_real_acceleration = (speed - last_speed) * 1/delta
	if debug:
		speed = max(0, 200*command)

func drive(delta):
	var driven_distance = speed * delta
	if reverser == ReverserState.REVERSE:
		driven_distance = -driven_distance
	distance_on_route += driven_distance

	if not forward:
		driven_distance = -driven_distance
	distance_on_rail += driven_distance

	if distance_on_rail > current_rail.length or distance_on_rail < 0:
		change_to_next_rail()
	
	if not rendering: return
	if forward:
		self.transform = current_rail.get_transform_at_rail_distance(distance_on_rail)
	else:
		self.transform = current_rail.get_transform_at_rail_distance(distance_on_rail)
		rotate_object_local(Vector3(0,1,0), deg2rad(180))

func change_to_next_rail():
	var old_radius = current_rail.radius
	if forward:
		old_radius = -old_radius
	
	if forward and (reverser == ReverserState.FORWARD):
		distance_on_rail -= current_rail.length
	if not forward and (reverser == ReverserState.REVERSE):
		distance_on_rail -= current_rail.length

	if not ai:
		print("Player: Changing Rail...")

	if reverser == ReverserState.REVERSE:
		route_index -= 1
	else:
		route_index += 1

	if baked_route.size() == route_index:
		print(name + ": Route no more rail found, despawning me...")
		despawn()
		return

	current_rail =  world.get_node("Rails").get_node(baked_route[route_index])
	forward = baked_route_direction[route_index]

	var new_radius = current_rail.radius
	if forward:
		new_radius = -new_radius
	
	if not forward and (reverser == ReverserState.FORWARD):
		distance_on_rail += current_rail.length
	if forward and (reverser == ReverserState.REVERSE):
		distance_on_rail += current_rail.length
		
	
	# Get radius difference:
	if old_radius == 0: # prevent diviging through Zero, and take a very very big curve radius instead. 
		old_radius = 1000000000
	if new_radius == 0: # prevent diviging through Zero, and take a very very big curve radius instead. 
		new_radius = 1000000000
	var radius_difference_factor = abs(1/new_radius - 1/old_radius)*2000
	
	print(new_radius)
	print(old_radius)
	
	print (radius_difference_factor)
	curve_shaking_factor = radius_difference_factor * Math.speed_to_kmh(speed) / 100.0 * camera_shaking_factor



	
var mouse_motion = Vector2()
var mouse_wheel

func remove_free_camera():
	if world.has_node("FreeCamera"):
		world.get_node("FreeCamera").queue_free()
		

func switch_to_cabin_view():
	#Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	camera_state = CameraState.CABIN_VIEW
	wagons_visible = false
	camera_node.transform = camera_zero_transform
	camera_x = -camera_node.rotation_degrees.x
	camera_y = camera_node.rotation_degrees.y
	$Camera.fov = camera_fov # reset to first person FOV (zoom)
	$Cabin.show()
	remove_free_camera()
	$Camera.current = true

func switch_to_outer_view():
	wagons_visible = true
	camera_state = CameraState.OUTER_VIEW
	camera_distance_changed = true # FIX for camera not properly setting itself until 1st input
	$Camera.fov = ref_fov # reset to reference FOV, zooming works different in this view
	$Cabin.hide()
	remove_free_camera()
	$Camera.current = true


func handle_camera(delta):
	if Input.is_action_just_pressed("Cabin View"):
		switch_to_cabin_view()
	if Input.is_action_just_pressed("Outer View"):
		switch_to_outer_view()
	if Input.is_action_just_pressed("FreeCamera"):
		$Cabin.hide()
		wagons_visible = true
		camera_state = CameraState.FREE_VIEW
		get_node("Camera").current = false
		var cam = load("res://addons/Libre_Train_Sim_Editor/Data/Modules/FreeCamera.tscn").instance()
		cam.current = true
		world.add_child(cam)
		cam.owner = world
		cam.transform = transform.translated(camera_mid_point)

	var player_cameras = get_tree().get_nodes_in_group("PlayerCameras")
	for i in range(3, 9):
		if Input.is_action_just_pressed("player_camera_" + str(i)) and player_cameras.size() >= i - 2:
			wagons_visible = true
			camera_state = i
			player_cameras[i -3].current = true
			$Cabin.hide()
			remove_free_camera()

	if camera_state == CameraState.CABIN_VIEW:
		## Camera x Position
		var soll_camera_position_x = camera_zero_transform.origin.x + (current_real_acceleration/20.0 * -camera_factor * reverser)
		if speed == 0 or debug:
			soll_camera_position_x = camera_zero_transform.origin.x
		var missing_camera_position_x = camera_node.translation.x - soll_camera_position_x
		var soll_camera_translation = camera_node.translation
		soll_camera_translation.x -= missing_camera_position_x * delta
		
		## Handle Camera Shaking:
		soll_camera_translation += get_camera_shaking(delta)
		camera_node.translation = soll_camera_translation
		
		# FIXME: in the first frame, delta == 0, why?
		if mouse_motion.length() > 0 and delta > 0:
			var motion_factor = (ref_delta / delta * ref_delta) * mouse_sensitivity * (camera_fov / ref_fov)
			camera_y += -mouse_motion.x * motion_factor
			camera_x += +mouse_motion.y * motion_factor
			camera_x = clamp(camera_x, -85, 85)
			camera_node.rotation_degrees.y = camera_y
			camera_node.rotation_degrees.x = -camera_x
			mouse_motion = Vector2(0,0)
		
		if abs(camera_fov - camera_fov_soll) > 1:
			camera_fov += sign(camera_fov_soll - camera_fov)
			camera_node.fov = camera_fov
		
	elif camera_state == CameraState.OUTER_VIEW:
		#if not Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		#	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		if mouse_motion.length() > 0 or camera_distance_changed:
			var motion_factor = (ref_delta / delta * ref_delta) * mouse_sensitivity
			camera_y += -mouse_motion.x * motion_factor
			camera_x += +mouse_motion.y * motion_factor
			camera_x = clamp(camera_x, -85, 85)
			var camera_vector = Vector3(camera_distance, 0, 0)
			camera_vector = camera_vector.rotated(Vector3(0,0,1), deg2rad(camera_x)).rotated(Vector3(0,1,0), deg2rad(camera_y))
			camera_node.translation = camera_vector + camera_mid_point
			camera_node.rotation_degrees.y = camera_y + 90
			camera_node.rotation_degrees.x = -camera_x
			mouse_motion = Vector2(0,0)
			camera_distance_changed = false
		

## Signals:
func check_signals():
	if reverser == ReverserState.REVERSE:
		# search through signals BACKWARDS, since we are driving BACKWARDS
		var search_array = baked_route_signal_names.slice(0, next_signal_index-1)
		search_array.invert()
		for signal_name in search_array:
			if baked_route_signal_positions[signal_name] > distance_on_route:
				next_signal_index -= 1 # order is important
				handle_signal(signal_name)
			else: break
	else:
		var search_array = baked_route_signal_names.slice(next_signal_index, baked_route_signal_names.size()-1)
		for signal_name in search_array:
			if baked_route_signal_positions[signal_name] < distance_on_route:
				next_signal_index += 1
				handle_signal(signal_name)
			else: break

func find_previous_speed_limit():
	# reset to max speed limit, in case no previous signal_passed is found
	var return_value = speed_limit
	var search_array = get_all_previous_signals_of_types([SignalType.SIGNAL, SignalType.SPEED])
	for signal_name in search_array:
		var signal_inst = world.get_node("Signals/"+signal_name)
		if signal_inst.speed != -1:
			return_value = signal_inst.speed
			break
	return return_value

func handle_signal(signal_name):
	next_signal = null
	next_speed_limit_node = null
	var signal_passed = world.get_node("Signals/"+signal_name)
	if signal_passed.forward != forward: return

	print(name + ": SIGNAL: " + signal_passed.name)

	if signal_passed.type == SignalType.SIGNAL: ## Signal
		if reverser == ReverserState.FORWARD:
			if signal_passed.speed != -1:
				current_speed_limit = signal_passed.speed
			if signal_passed.warn_speed != -1: 
				pass
			if signal_passed.status == SignalState.RED:
				send_message(TranslationServer.translate("YOU_OVERRUN_RED_SIGNAL"))
				overrun_red_signal = true
			else:
				free_signal_after_driven_train_length(last_driven_signal)
			signal_passed.set_state(SignalState.RED)
			last_driven_signal = signal_passed
		else:
			if signal_passed.speed != -1:
				current_speed_limit = find_previous_speed_limit()
			signal_passed.set_state(SignalState.GREEN)  # turn green, we are no longer in the block!
			# reset last signal_passed, and turn it RED
			var prev = get_all_previous_signals_of_types([SignalType.SIGNAL])
			if prev.size() > 0:
				last_driven_signal = world.get_node("Signals/"+prev[0])
				last_driven_signal.set_state(SignalState.RED)
	
	elif signal_passed.type == SignalType.STATION: ## Station
		if not stations["node_name"].has(signal_passed.name):
			print(name + ": Station not found in repository, ingoring station. Maybe you are at the wrong track, or the nodename in the station table of the player is incorrect...")
			return
		current_station_index = stations["node_name"].find(signal_passed.name)
		match stations["stop_type"][current_station_index]:
			StopType.PASS:
				stations["passed"][current_station_index] = true
			StopType.HALT:
				end_station = false
				station_begin = false
			StopType.BEGIN:
				end_station = false
				station_begin = true
			StopType.END:
				end_station = true
				station_begin = false
		current_station_name = stations["station_name"][current_station_index]		
		is_in_station = false
		platform_side = signal_passed.platform_side
		station_halt_time = stations["halt_time"][current_station_index]
		station_length = signal_passed.station_length
		distance_on_station_begin = distance_on_route
		arrival_time = stations["arrival_time"][current_station_index]
		depature_time = stations["departure_time"][current_station_index]
		door_open_message_sent_timer = 0
		door_open_message_sent = false
		current_station_node = signal_passed
		if not station_begin:
			for wagon_inst in wagon_instances:
				wagon_inst.send_persons_to_door(platform_side, stations["leaving_persons"][current_station_index]/100.0)
	elif signal_passed.type == SignalType.SPEED:
		if reverser == ReverserState.REVERSE:
			current_speed_limit = find_previous_speed_limit()
		else:
			current_speed_limit = signal_passed.speed
	elif signal_passed.type == SignalType.WARN_SPEED:
		print(name + ": Next Speed Limit: "+String(signal_passed.warn_speed))
	elif signal_passed.type == SignalType.CONTACT_POINT:
		signal_passed.activate_contact_point(name)
	pass




## For Station:
const GOODWILL_DISTANCE = 10 # The distance_on_route the player can overdrive a station, or it's train end isn't in the station.
var end_station = false
var station_begin = true
var station_timer = 0
var distance_on_station_begin = 0
var door_open_message_sent_timer = 0
var door_open_message_sent = false
var current_station_node 
var current_station_index = 0
func check_station(delta):
	if current_station_name != "":
		if (speed == 0 and not is_in_station and distance_on_route-distance_on_station_begin+GOODWILL_DISTANCE<length) and not whole_train_not_in_station and not station_begin:
			whole_train_not_in_station = true
			send_message(TranslationServer.translate("END_OF_YOUR_TRAIN_NOT_IN_STATION"))
		if ((speed == 0 and not is_in_station and distance_on_route-distance_on_station_begin>=length) and door_status == DoorState.CLOSED):
			door_open_message_sent_timer += delta
			if door_open_message_sent_timer > 5 and not door_open_message_sent:
				send_message(TranslationServer.translate("HINT_OPEN_DOORS"))
				door_open_message_sent = true
		if ((speed == 0 and not is_in_station and distance_on_route-distance_on_station_begin>=length) and ((door_status & DoorState.BOTH) or platform_side == PlatformSide.NONE)) or (station_begin and not is_in_station):
			real_arrival_time = time
			var late_message = ". "
			if not station_begin:
				var seconds_later = -arrival_time[2] + real_arrival_time[2] + (-arrival_time[1] + real_arrival_time[1])*60 + (-arrival_time[0] + real_arrival_time[0])*3600
				if seconds_later > 120:
					late_message += TranslationServer.translate("YOU_ARE_LATE_1") + " " + String(int(seconds_later/60)) + " " + TranslationServer.translate("YOU_ARE_LATE_2_ONE_MINUTE")
				elif seconds_later > 60:
					late_message += TranslationServer.translate("YOU_ARE_LATE_1") + " " + String(int(seconds_later/60)) + " " + TranslationServer.translate("YOU_ARE_LATE_2")
			if station_begin:
				current_station_node.set_waiting_persons(stations["waiting_persons"][0]/100.0 * world.default_persons_at_station)
				jEssentials.call_delayed(1.2, self, "send_message", [TranslationServer.translate("WELCOME_TO") + " " + current_station_name])
			else:
				send_message(TranslationServer.translate("WELCOME_TO") + " " + current_station_name + late_message)
				
			
			if camera_state != CameraState.CABIN_VIEW:
				for wagon in wagon_instances:
					jTools.call_delayed(1, wagon, "play_outside_announcement", [stations["arrival_announce_path"][current_station_index]])
			elif not ai:
				jTools.call_delayed(1, jAudioManager, "play_game_sound", [stations["arrival_announce_path"][current_station_index]])
			station_timer = 0
			is_in_station = true
			if not end_station:
				send_door_positions_to_current_station()
		elif (speed == 0 and is_in_station ) :
			if station_timer > station_halt_time:
				if end_station:
					send_message(TranslationServer.translate("SCENARIO_FINISHED"))
					stations["passed"][stations["station_name"].find(current_station_name)] = true
					current_station_name = ""
					next_station = ""
					is_in_station = false
					next_station_node = null
					current_station_node = null
					update_waiting_persons_on_next_station()
					return
				if depature_time[0] <= time[0] and depature_time[1] <= time[1] and depature_time[2] <= time[2]:
					next_station = null
					send_message(TranslationServer.translate("YOU_CAN_DEPART"))
					stations["passed"][stations["station_name"].find(current_station_name)] = true
					if camera_state != CameraState.CABIN_VIEW:
						for wagon in wagon_instances:
							wagon.play_outside_announcement(stations["departure_announce_path"][current_station_index])
					elif not ai:
						jAudioManager.play_game_sound(stations["departure_announce_path"][current_station_index])
					leave_current_station()
		elif (speed != 0 and is_in_station) and (door_status == DoorState.CLOSED):
			send_message(TranslationServer.translate("YOU_DEPARTED_EARLIER"))
			leave_current_station()
		elif (station_length+GOODWILL_DISTANCE<distance_on_route-distance_on_station_begin) and current_station_name != "" and not station_begin:
			if is_in_station:
				send_message(TranslationServer.translate("YOU_DEPARTED_EARLIER"))
			else:
				send_message(TranslationServer.translate("YOU_MISSED_A_STATION"))
			leave_current_station()
		station_timer += delta
		if (speed != 0):
			whole_train_not_in_station = false
			
func leave_current_station():
	stations["passed"][stations["station_name"].find(current_station_name)] = true
	current_station_name = ""
	next_station = ""
	is_in_station = false
	next_station_node = null
	current_station_node = null
	update_waiting_persons_on_next_station()

func update_waiting_persons_on_next_station():
	var station_nodes = get_all_upcoming_signals_of_types([SignalType.STATION])
	if station_nodes.size() != 0:
		var station_node = world.get_node("Signals/"+station_nodes[0])
		var index = stations["node_name"].find(station_node.name)
		station_node.set_waiting_persons(stations["waiting_persons"][index]/100.0 * world.default_persons_at_station)

## Pantograph
var pantograph_timer = 0

func force_pantograph_up():
	pantograph = true
	pantograph_up = true

func rise_pantograph():
	if not pantograph:
		pantograph_up = true
		pantograph_timer = 0

func check_pantograph(delta):
	if Input.is_action_just_pressed("pantograph") and not ai:
		jAudioManager.play_game_sound("res://Resources/Basic/Sounds/click.ogg")
		pantograph_up = !pantograph_up
		pantograph_timer = 0
	if pantograph != pantograph_up:
		pantograph_timer+= delta
		if pantograph:
			pantograph = false
		if pantograph_timer > pantograph_time:
			pantograph = pantograph_up
	if pantograph:
		voltage = voltage + (20-voltage)*delta*2.0
	else:
		voltage = voltage + (0-voltage)*delta*2.0
		


var check_speed_limit_timer = 0
func check_speed_limit(delta):
	hard_over_speeding = Math.speed_to_kmh(speed) > current_speed_limit + 10
	if Math.speed_to_kmh(speed) > current_speed_limit + 5 and check_speed_limit_timer > 5:
		check_speed_limit_timer = 0
		send_message( TranslationServer.translate("YOU_ARE_DRIVING_TO_FAST") + " " +  String(current_speed_limit))
	check_speed_limit_timer += delta

	
func send_message(string):
	if not ai:
		print("Sending Message: " + string )
		$HUD.send_Message(string)
		

## Doors:
var doors_closing_timer = 0
func open_left_doors():
	if not (door_status & (DoorState.LEFT | DoorState.MOVING)) and speed == 0:
		if not $Sound/DoorsOpen.playing: 
			$Sound/DoorsOpen.play()
		door_status = (door_status | DoorState.LEFT) & ~DoorState.CLOSED
		
func open_right_doors():
	if not (door_status & (DoorState.RIGHT | DoorState.MOVING)) and speed == 0:
		if not $Sound/DoorsOpen.playing: 
			$Sound/DoorsOpen.play()
		# ADD right to door state, REMOVE closed from door state
		# is equal to: 
		#     if doors are closed, set door state = right
		#     if doors are left, set door state = both
		door_status = (door_status | DoorState.RIGHT) & ~DoorState.CLOSED

func close_doors():
	# if left door, or right door, or both doors are open, and the doors are not moving
	if not (door_status & DoorState.MOVING) and (door_status & DoorState.BOTH):
		door_status = DoorState.CLOSING
		$Sound/DoorsClose.play()
		
func force_close_doors():
	door_status = DoorState.CLOSING
	doors_closing_timer = doors_closing_time - 0.1

func check_doors(delta):
	if Input.is_action_just_pressed("doorClose") and not ai:
		jAudioManager.play_game_sound("res://Resources/Basic/Sounds/click.ogg")
		close_doors()
	if Input.is_action_just_pressed("doorLeft") and not ai:
		jAudioManager.play_game_sound("res://Resources/Basic/Sounds/click.ogg")
		open_left_doors()
	if Input.is_action_just_pressed("doorRight") and not ai:
		jAudioManager.play_game_sound("res://Resources/Basic/Sounds/click.ogg")
		open_right_doors()
	if door_status == DoorState.CLOSING:
		doors_closing_timer += delta
	if doors_closing_timer > doors_closing_time:
		door_status = DoorState.CLOSED
		doors_closing_timer = 0
		
	
## BAKING
func sort_signals_by_distance(a, b):
	if a["distance"] < b["distance"]:
		return true
	return false
	
var baked_route ## Route, which will be generated at start of the game.
var baked_route_direction
var baked_route_rail_length
var baked_route_signal_names = [] # sorted array of all signal_passed names along the route
var baked_route_signal_positions = {} # dictionary of all signal_passed positions along the route (key = signal_passed name)
func bake_route(): ## Generate the whole route for the train.
	baked_route = []
	baked_route_direction = [forward]
	
	baked_route.append(start_rail)
	var current_r = world.get_node("Rails").get_node(baked_route[0]) ## imagine: current rail, which the train will drive later
	baked_route_rail_length = [current_r.length]
	var current_pos
	var current_rot
	var current_f = forward
	if current_f: ## Forward
		current_pos = current_r.end_pos
		current_rot = current_r.end_rot
	else: ## Backward
		current_pos = current_r.start_pos
		current_rot = current_r.start_rot - 180.0

	var sum_route_length = 0

	var rail_signals = current_r.attached_signals
	rail_signals.sort_custom(self, "sort_signals_by_distance")
	if not current_f: 
		rail_signals.invert()
	for signal_dict in rail_signals:
		var signal_instance = world.get_node("Signals/"+signal_dict["name"])
		if signal_instance.forward != current_f: 
			continue
		var position_on_route = sum_route_length
		if current_f: 
			position_on_route += signal_dict["distance"]
		else: 
			position_on_route += current_r.length - signal_dict["distance"]
		baked_route_signal_names.append(signal_dict["name"])
		baked_route_signal_positions[signal_dict["name"]] = position_on_route
	sum_route_length += current_r.length

	while(true): ## Find next Rail
		var possible_rails = []
		for rail in world.get_node("Rails").get_children(): ## Get Rails, which are in the near of the endposition of current rail:
			if current_pos.distance_to(rail.start_pos) < 0.1 and abs(Math.norm_deg(current_rot) - abs(Math.norm_deg(rail.start_rot))) < 1 and rail.name != current_r.name:
				possible_rails.append(rail.name)
			elif current_pos.distance_to(rail.end_pos) < 0.1 and abs(Math.norm_deg(current_rot) - abs(Math.norm_deg(rail.end_rot+180.0))) < 1 and rail.name != current_r.name:
				possible_rails.append(rail.name)
		
		if possible_rails.size() == 0: ## If no rail was found
			break
		elif possible_rails.size() == 1: ## If only one rail is possible to switch
			baked_route.append(possible_rails[0])
		else: ## if more rails are available:
			var selected_rail = possible_rails[0]
			for rail in possible_rails:
				for route_name in route:
					if route_name == rail:
						selected_rail = rail
						break
			baked_route.append(selected_rail)
		
		
		
		## Set Rail to "End" of newly added Rail
		current_r = world.get_node("Rails").get_node(baked_route[baked_route.size()-1]) ## Get "current Rail"
		if current_pos.distance_to(current_r.translation) < current_pos.distance_to(current_r.end_pos):
			current_f = true
		else:
			current_f = false

		baked_route_direction.append(current_f)
		baked_route_rail_length.append(current_r.length)

		# bake signals
		rail_signals = current_r.attached_signals
		rail_signals.sort_custom(self, "sort_signals_by_distance")
		if not current_f: 
			rail_signals.invert()
		for signal_dict in rail_signals:
			var signal_instance = world.get_node("Signals/"+signal_dict["name"])
			if signal_instance.forward != current_f: 
				continue
			var position_on_route = sum_route_length
			if current_f: 
				position_on_route += signal_dict["distance"]
			else: 
				position_on_route += current_r.length - signal_dict["distance"]
			baked_route_signal_names.append(signal_dict["name"])
			baked_route_signal_positions[signal_dict["name"]] = position_on_route
		sum_route_length += current_r.length

		if current_f: ## Forward
			current_pos = current_r.end_pos
			current_rot = current_r.end_rot
		else: ## Backward
			current_pos = current_r.start_pos
			current_rot = current_r.start_rot - 180.0
	print(name + ": Baking Route finished:")
	print(name + ": Baked Route: "+ String(baked_route))
	print(name + ": Baked Route: Direction "+ String(baked_route_direction))
	
func show_textbox_message(string):
	$HUD.show_textbox_message(string)
	
func get_all_upcoming_signals_of_types(types : Array): # returns an sorted array with the names of the signals. The first entry is the nearest.
	var return_value = []
	var search_array = baked_route_signal_names.slice(next_signal_index, baked_route_signal_names.size()-1)
	for signal_name in search_array:
		var signal_instance = world.get_node("Signals/"+signal_name)
		if signal_instance == null: continue
		if types.has(signal_instance.type):
			return_value.append(signal_name)
	return return_value

func get_all_previous_signals_of_types(types: Array): # returns an sorted array with the names of the signals. The first entry is the nearest.
	var return_value = []
	var search_array = baked_route_signal_names.slice(0, next_signal_index)
	search_array.invert()
	for signal_name in search_array:
		var signal_instance = world.get_node("Signals/"+signal_name)
		if signal_instance == null: continue
		if types.has(signal_instance.type):
			return_value.append(signal_name)
	return return_value

func get_distance_to_signal(signal_name):
	return baked_route_signal_positions[signal_name] - distance_on_route

var next_station = ""
var check_for_next_stationTimer = 0
var station_message_sent = false
func check_for_next_station(delta):  ## Used for displaying (In 1000m there is ...)
	check_for_next_stationTimer += delta
	if check_for_next_stationTimer < 1: return
	else:
		check_for_next_stationTimer = 0
		if next_station == "":
			var next_stations = get_all_upcoming_signals_of_types([SignalType.STATION])
#			print(name + ": "+String(next_stations))
			if next_stations.size() == 0:
				station_message_sent = true
				return
			next_station = next_stations[0]
			station_message_sent = false
		
		if not station_message_sent and get_distance_to_signal(next_station) < 1001 and stations["node_name"].has(next_station) and stations["stop_type"][stations["node_name"].find(next_station)] != StopType.PASS and not is_in_station:
			var station = world.get_node("Signals").get_node(next_station)
			station_message_sent = true
			var distance_s = String(int(get_distance_to_signal(next_station)/100)*100+100)
			if distance_s == "1000":
				distance_s = "1km"
			else:
				distance_s += "m"
			send_message(TranslationServer.translate("THE_NEXT_STATION_IS_1") + " " + stations["station_name"][stations["node_name"].find(next_station)]+ ". " + TranslationServer.translate("THE_NEXT_STATION_IS_2")+ " " + distance_s + " " + TranslationServer.translate("THE_NEXT_STATION_IS_3"))
			if camera_state != CameraState.OUTER_VIEW and camera_state != CameraState.FREE_VIEW and not ai:
#				print(name + ": Playing Sound.......................................................")
				jTools.call_delayed(10, jAudioManager, "play_game_sound", [stations["approach_announce_path"][stations["node_name"].find(next_station)]])
#				jAudioManager.play_game_sound(stations["approach_announce_path"][current_station_index+1])
		

func check_security():#
	var old_enforced_brake = 	enforced_braking
	enforced_braking = hard_over_speeding or overrun_red_signal or not engine or sifa_timer > 33 
	if not old_enforced_brake and enforced_braking and speed > 0 and not ai:
		$Sound/EnforcedBrake.play()

var check_for_player_help_timer = 0
var check_for_player_help_timer2 = 0
var check_for_player_help_sent = false
func check_for_player_help(delta):
	if not check_for_player_help_sent and speed == 0:
		check_for_player_help_timer += delta
		if check_for_player_help_timer > 8 and not pantograph_up and not check_for_player_help_sent:
			if not Root.mobile_version:
				send_message(TranslationServer.translate("HINT_F2"))
			check_for_player_help_sent = true
		if check_for_player_help_timer > 15 and command < -0.5 and not check_for_player_help_sent:
			if not Root.mobile_version:
				send_message(TranslationServer.translate("HINT_F2"))
			check_for_player_help_sent = true
	else:
		check_for_player_help_timer = 0
	
	check_for_player_help_timer2 += delta
	if blocked_acceleration and acc_roll > 0 and brake_roll == 0 and door_status == DoorState.CLOSED and not overrun_red_signal and check_for_player_help_timer2 > 10 and not is_in_station:
		send_message(TranslationServer.translate("HINT_ADVANCED_DRIVING"))
		check_for_player_help_timer2 = 0
		

func horn():
	if not ai:
		jAudioManager.play_game_sound("res://Resources/Basic/Sounds/click.ogg")
	$Sound/Horn.play()

var sifa_timer = 0
func check_sifa(delta):
	if automatic_driving:
		sifa_timer = 0
	sifa_timer += delta
	if speed == 0 or Input.is_action_just_pressed("SiFa"):
		if Input.is_action_just_pressed("SiFa"):
			jAudioManager.play_game_sound("res://Resources/Basic/Sounds/click.ogg")
		sifa_timer = 0
	sifa =  sifa_timer > 25
	$Sound/SiFa.stream_paused = not sifa_timer > 30
		
func set_signal_warn_limits(): # Called in the beginning of the route
	var signals = get_all_upcoming_signals_of_types([SignalType.SIGNAL])
	var speed_limits = get_all_upcoming_signals_of_types([SignalType.SPEED])
	for speed_limit in speed_limits:
		signals.append(speed_limit)
	var signal_t = {"name" : signals, "position" : []}
	for signal_s in signal_t["name"]:
		signal_t["position"].append(get_distance_to_signal(signal_s))
	var sorted_signals = Math.sort_signals(signal_t, true)
#	print(signal_t)
#	print(sorted_signals)
	var limit = speed_limit
	for i in range(0,sorted_signals.size()):
		var signal_n = world.get_node("Signals").get_node(sorted_signals[i])
		if signal_n.speed != -1:
			if signal_n.speed < limit and i > 0:
				var signal_n_before = world.get_node("Signals").get_node(sorted_signals[i-1])
				if signal_n_before.type == SignalType.SIGNAL:
					signal_n_before.set_warn_speed(signal_n.speed)
			limit = signal_n.speed

func set_signal_afters():
	var signals = get_all_upcoming_signals_of_types([SignalType.SIGNAL])
	for i in range(1,signals.size()):
		var signal_n = world.get_node("Signals").get_node(signals[i-1])
		signal_n.signal_after = signals[i]
		

func spawn_wagons():
	var next_wagon_position = start_position
	for wagon in wagons:
		var wagon_node = get_node(wagon)
		var new_wagon = wagon_node.duplicate()
		new_wagon.owner = self.owner
		new_wagon.show()
		new_wagon.baked_route = baked_route
		new_wagon.baked_route_direction = baked_route_direction
		new_wagon.forward = forward
		new_wagon.current_rail = current_rail
		new_wagon.distance_on_rail = next_wagon_position
		new_wagon.player = self
		new_wagon.world = world
		if forward:
			next_wagon_position -= wagon_node.length + wagon_distance
		else:
			next_wagon_position += wagon_node.length + wagon_distance
		get_parent().add_child(new_wagon)
		wagon_instances.append(new_wagon)
	
	# Handle Cabin:
	$Cabin.baked_route = baked_route
	$Cabin.baked_route_direction = baked_route_direction
	$Cabin.forward = forward
	$Cabin.current_rail = current_rail
	$Cabin.distance_on_rail = next_wagon_position
	$Cabin.player = self
	$Cabin.world = world

func toggle_automatic_driving():
	automatic_driving = !automatic_driving
	if not automatic_driving:
		soll_speed_enabled = false
		print("Automatic Driving disabled")
	else:
		print("AutomaticDriving enabled")

var autopilot_in_station = true

var update_next_signal_timer = 0
func update_next_signal(delta):
	if next_signal == null:
		var upcoming = get_next_signal()
		if upcoming == null: return
		next_signal = world.get_node("Signals/"+upcoming)
		update_next_signal_timer = 1 ## Force Update Signal
	update_next_signal_timer += delta
	if update_next_signal_timer > 0.2:
		distance_to_next_signal = get_distance_to_signal(next_signal.name)
		update_next_signal_timer = 0

func get_next_signal():
	var all = get_all_upcoming_signals_of_types([SignalType.SIGNAL])
	if all.size() > 0:
		return all[0]
	return null

var update_next_speed_limit_timer = 0
func update_next_speed_limit(delta):
	if next_speed_limit_node == null:
		next_speed_limit_node = get_next_speed_limit()
		if next_speed_limit_node == null:
			return
		update_next_speed_limit_timer = 1 ## Force Update Signal
	update_next_speed_limit_timer += delta
	if update_next_speed_limit_timer > 0.2:
		distance_to_next_speed_limit = get_distance_to_signal(next_speed_limit_node.name)
		update_next_speed_limit_timer = 0

func get_next_speed_limit(): #
	var all = get_all_upcoming_signals_of_types([SignalType.SPEED, SignalType.SIGNAL])
	for limit in all:
		if world.get_node("Signals/" + limit).speed != -1:
			return world.get_node("Signals/" + limit)
			


var next_station_node = null
var distance_to_next_station = 0
var update_next_station_timer = 0
func update_next_station(delta):  ## Used for Autopilot
	if next_station_node == null:
		var upcoming = get_next_station()
		if upcoming == null: return
		next_station_node = world.get_node("Signals").get_node(upcoming)
		next_station_node.set_waiting_persons(stations["waiting_persons"][0]/100.0 * world.default_persons_at_station)
	distance_to_next_station = get_distance_to_signal(next_station_node.name) + next_station_node.stationLength

func get_next_station():
	var all = get_all_upcoming_signals_of_types([SignalType.STATION])
	if all.size() > 0:
		return all[0]
	return null

func autopilot(delta):
	debug_lights(self)
	if not pantograph_up:
		pantograph_up = true
	if not engine:
		start_engine()
	if is_in_station:
		soll_speed = 0
		return
	if (door_status & DoorState.BOTH) and not (door_status & DoorState.MOVING):
		door_status = DoorState.CLOSING
		$Sound/DoorsClose.play()
		
	
	
	var soll_speed_arr = {}
	
	## Red Signal:
	soll_speed_arr[0] = speed_limit
	if next_signal != null and next_signal.status == SignalState.RED:
		soll_speed_arr[0] = min(sqrt(15*distance_to_next_signal+20), (distance_to_next_signal+10)/4.0)
		if soll_speed_arr[0] < 10:
			soll_speed_arr[0] = 0
	## Next SpeedLimit
	soll_speed_arr[1] = current_speed_limit
	if next_speed_limit_node != null and next_speed_limit_node.speed != -1:
		soll_speed_arr[1] = next_speed_limit_node.speed + (distance_to_next_speed_limit-50)/((speed+2)/2)
		if (distance_to_next_signal < 50):
			soll_speed_arr[1] = next_speed_limit_node.speed
	
	## Next Station:
	soll_speed_arr[2] = speed_limit
	
	if next_station_node != null:
		if stations["node_name"].has(next_station_node.name):

			soll_speed_arr[2] = min(sqrt(15*distance_to_next_station+20), (distance_to_next_station+10)/4.0)
			if soll_speed_arr[2] < 10:
				soll_speed_arr[2] = 0
		else:
			next_station_node = null

			
	## Open Doors:
	if (current_station_name != "" and speed == 0 and not is_in_station and distance_on_route-distance_on_station_begin>=length):
		if next_station_node.platform_side == PlatformSide.LEFT:
			door_status = DoorState.LEFT
			$Sound/DoorsOpen.play()
		elif next_station_node.platform_side == PlatformSide.RIGHT:
			door_status = DoorState.RIGHT
			$Sound/DoorsOpen.play()
		elif next_station_node.platform_side == PlatformSide.BOTH:
			door_status = DoorState.BOTH
			$Sound/DoorsOpen.play()
	
	
	soll_speed_arr[3] = current_speed_limit
	

#	print("0: "+ String(soll_speed_arr[0]))
#	print("1: "+ String(soll_speed_arr[1]))
#	print("2: "+ String(soll_speed_arr[2]))
#	print("3: "+ String(soll_speed_arr[3]))
	soll_speed = soll_speed_arr.values().min()
	soll_speed_enabled = true
	

	

	
func handle_soll_speed(delta):
	var speed_difference = soll_speed - Math.speed_to_kmh(speed)
	if abs(speed_difference) > 4:
		if speed_difference > 10: 
			soll_command = 1
		elif speed_difference < 10 and speed_difference > 0:
			soll_command = 0.5
		elif speed_difference > -10 and speed_difference < 0:
			soll_command = -0.5
		elif speed_difference < -10:
			soll_command = -1
	elif abs(speed_difference) < 1: 
		soll_command = 0
	if soll_speed == 0 and abs(speed_difference) < 10:
		soll_command = -0.5

func check_despawn():
	if ai and current_rail.name == despawn_rail:
		despawn()
		
func despawn():
	free_last_signal_because_of_despawn()
	print("Despawning Train: " + name)
	despawning = true

var check_visibility_timer = 0
func check_visibility(delta):
	check_visibility_timer += delta
	if check_visibility_timer < 1: return
	if ai: 
		var current_chunk = world.pos_to_chunk(world.get_original_pos_big_chunk(translation))
		rendering = world.ist_chunks.has(world.chunk_to_string(current_chunk))
		self.visible = rendering
		wagons_visible = rendering
			 

func debug_lights(node):
	for child in node.get_children():
		if child.name != "HUD":
			debug_lights(child)
	if node.has_meta("energy"):
		node.visible = false
		node.visible = true
		print("Spotlight updated")


		
func toggle_cabin_light():
	if not has_node("CabinLight"):
		return
	jAudioManager.play_game_sound("res://Resources/Basic/Sounds/click.ogg")
	inside_light = !inside_light
	$CabinLight.visible = inside_light

func toggle_front_light():
	if not has_node("FrontLight"):
		return
	jAudioManager.play_game_sound("res://Resources/Basic/Sounds/click.ogg")
	front_light = !front_light
	$FrontLight.visible = front_light

var signal_to_free = null
var signal_to_free_distance = 0
func free_signal_after_driven_train_length(signal_instance): # Called, when overdrove the next signal_passed
	signal_to_free = signal_instance
	signal_to_free_distance = distance_on_route

func check_free_last_signal(delta): #called by process
	if ((distance_on_route - signal_to_free_distance) > length) and signal_to_free != null:
		signal_to_free.give_signal_free()
		
func free_last_signal_because_of_despawn():
	if  last_driven_signal != null:
		last_driven_signal.give_signal_free()
	
func fix_obsolete_stations(): ## Checks, if there are stations in the stations table, wich are not passed, but unreachable. For them it sets them to passed. Thats good for the Screen in the train.
	pass # doesn't work as expected..
#	for i in range(stations.node_name.size()):
#		var stationNodeName = stations.node_name[i]
#		var obsolete = true
#		for nextStationsNodeName in get_all_upcoming_signals_of_types([SignalType.STATION]):
#			if nextStationsNodeName == stationNodeName:
#					obsolete = false
#					break
#		if obsolete:
#			if not stationNodeName == current_station_name and stations.stop_type[i] != StopType.BEGIN:
#				stations.passed[i] = true

func update_train_audio_bus():
	if camera_state == CameraState.FREE_VIEW or camera_state == CameraState.OUTER_VIEW:
		AudioServer.set_bus_volume_db(2,0)
	else:
		AudioServer.set_bus_volume_db(2,sound_isolation)

func send_door_positions_to_current_station():
	print("Sending Door Postions...")
	var doors = []
	var doors_wagon = []
	for wagon in wagon_instances:
		var wagon_transform
		if forward:
			wagon_transform = wagon.current_rail.get_transform_at_rail_distance(wagon.distance_on_rail)
		else:
			var forward_transform = wagon.current_rail.get_transform_at_rail_distance(wagon.distance_on_rail)
			var backward_basis = forward_transform.basis.rotated(Vector3(0,1,0), deg2rad(180)) # Maybe this could break on ascending/descanding rails..
			var backward_transform = Transform(backward_basis, forward_transform.origin)
			wagon_transform = backward_transform
		if (current_station_node.platform_side == PlatformSide.LEFT):
			for door in wagon.left_doors:
				door.world_pos = (wagon_transform.translated(door.translation).origin)
				doors.append(door)
				doors_wagon.append(wagon)
		if (current_station_node.platform_side == PlatformSide.RIGHT):
			for door in wagon.right_doors:
				door.world_pos = (wagon_transform.translated(door.translation).origin)
				doors.append(door)
				doors_wagon.append(wagon)
	current_station_node.set_door_positions(doors, doors_wagon)


var curve_shaking_factor = 0.0
var camera_shaking_time = 0.0
func get_camera_shaking(delta):
	camera_shaking_time += delta
	curve_shaking_factor = Root.clamp_via_time(0.0, curve_shaking_factor, delta)
	
	var camera_shaking = Vector3(sin(camera_shaking_time*10.0), cos(camera_shaking_time*7.0), sin(camera_shaking_time*13.0)) / 10000.0
	
	var shaking_factor = Math.speed_to_kmh(speed) / 100.0 * abs(sin(camera_shaking_time/5)) * camera_shaking_factor
	

#	print(curve_shaking_factor)
	shaking_factor = max(shaking_factor, curve_shaking_factor)
	
	var current_camera_shaking = camera_shaking * shaking_factor
	
	return current_camera_shaking
		
var switch_on_next_change = false
func update_switch_on_next_change():
	if forward and current_rail.is_switch_part[1] != "":
		switch_on_next_change = true
		return
	elif not forward and current_rail.is_switch_part[0] != "":
		switch_on_next_change = true
		return
	
	if baked_route.size() > route_index+1:
		var next_rail = world.get_node("Rails").get_node(baked_route[route_index+1])
		var next_forward = baked_route_direction[route_index+1]
		if next_forward and next_rail.is_switch_part[0] != "":
			switch_on_next_change = true
			return
		elif not next_forward and next_rail.is_switch_part[1] != "":
			switch_on_next_change = true
			return
			
	switch_on_next_change = false

var last_switch_rail = null ## Last rail, where was overdriven a switch
func check_overdriving_a_switch():
	if not switch_on_next_change:
		return
	
	var camera_translation = 0
	if has_node("Camera"):
		camera_translation = $Camera.translation.x
	if forward:
		if current_rail.length - (distance_on_rail + camera_translation) < 0 and not current_rail == last_switch_rail:
			overdriven_switch()
			last_switch_rail = current_rail
	else:
		if distance_on_rail - camera_translation < 0 and not current_rail == last_switch_rail:
			overdriven_switch()
			last_switch_rail = current_rail


func overdriven_switch():
	pass

func change_reverser(change):
	if speed != 0:
		return

	match reverser:
		ReverserState.FORWARD:
			if change < 0:
				reverser = ReverserState.NEUTRAL
				jAudioManager.play_game_sound("res://Resources/Basic/Sounds/click.ogg")
		ReverserState.NEUTRAL:
			jAudioManager.play_game_sound("res://Resources/Basic/Sounds/click.ogg")
			if change > 0: reverser = ReverserState.FORWARD
			else: reverser = ReverserState.REVERSE
		ReverserState.REVERSE:
			if change > 0:
				reverser = ReverserState.NEUTRAL
				jAudioManager.play_game_sound("res://Resources/Basic/Sounds/click.ogg")


func handle_input():
	if ai:
		return
	if Input.is_action_just_pressed("FrontLight") and not Input.is_key_pressed(KEY_CONTROL):
		toggle_front_light()
		
	if Input.is_action_just_pressed("InsideLight"):
		toggle_cabin_light()
	
	if Input.is_action_just_pressed("Horn"):
		horn()

	if Input.is_action_just_pressed("reverser+"):
		change_reverser(+1)

	if Input.is_action_just_pressed("reverser-"):
		change_reverser(-1)
