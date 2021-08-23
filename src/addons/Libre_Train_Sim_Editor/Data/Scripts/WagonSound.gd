extends Node3D

var player
@onready var wagon = get_parent()

var soll_curve_sound = -50
var soll_drive_sound = -50

@export_file("*.ogg,*.wav,*.mp3") var drive_sound_path = "res://Resources/Basic/Sounds/Drive.ogg"
@export_file("*.ogg,*.wav,*.mp3") var curve_sound_path = "res://Resources/Basic/Sounds/Curve.ogg"
@export_file("*.ogg,*.wav,*.mp3") var switch_sound_path = "res://Resources/Basic/Sounds/DriveOverSwitch.ogg"
@export_file("*.ogg,*.wav,*.mp3") var brake_sound_path = "res://Resources/Basic/Sounds/Brakes.ogg"



func _process(delta):
	if player == null:
		player = get_parent().player
		return
	

	
	## soll_curve_sound:
	if wagon.current_rail.radius == 0 or Math.speed_to_kmh(player.speed) < 35 or abs(wagon.current_rail.radius) > 600:
		soll_curve_sound = -50
	else:
		soll_curve_sound = -25.0 + (Math.speed_to_kmh(player.speed)/80.0 * abs(300.0/wagon.current_rail.radius))*5
	
#	print(soll_curve_sound)
	$CurveSound.unit_db = Root.clamp_via_time(soll_curve_sound, $CurveSound.unit_db, delta)
#	$CurveSound.unit_db = 10
	
	## Drive Sound:
	$DriveSound.pitch_scale = 0.5 + Math.speed_to_kmh(player.speed)/200.0
	var drive_sound_db = -20.0 + Math.speed_to_kmh(player.speed)/2.0
	if drive_sound_db > 10:
		drive_sound_db = 10
	if player.speed == 0:
		drive_sound_db = -50.0
	$DriveSound.unit_db = Root.clamp_via_time(drive_sound_db, $DriveSound.unit_db, delta) 
	
	var soll_brake_sound = -50.0
	if not (player.speed >= 5 or player.command >= 0 or player.speed == 0):
		soll_brake_sound = -20.0 -player.command * 5.0/player.speed
		if soll_brake_sound > 10:
			soll_brake_sound = 10
	$BrakeSound.unit_db = Root.clamp_via_time(soll_brake_sound, $BrakeSound.unit_db, delta)
	
	$DriveSound.stream_paused = not wagon.visible
	$CurveSound.stream_paused = not wagon.visible
	$SwitchSound.stream_paused = not wagon.visible
	$SwitchSound2.stream_paused = not wagon.visible
	$BrakeSound.stream_paused = not wagon.visible
	

	check_and_play_switch_sound()
	

func _ready():
	$DriveSound.stream = load(drive_sound_path)
	$CurveSound.stream = load(curve_sound_path)
	$SwitchSound.stream = load(switch_sound_path)
	$SwitchSound.stream.loop = false
	$SwitchSound2.stream = load(switch_sound_path)
	$SwitchSound2.stream.loop = false
	$BrakeSound.stream = load(brake_sound_path)
	
	$DriveSound.unit_db = -50
	$CurveSound.unit_db = -50
	$BrakeSound.unit_db = -50

var last_switch_sound_rail = null
var second_switch_sound_distance = -1 # If this distance is set, and its bigger than the complete distance of the wagon, the second switch sound will be played 
func check_and_play_switch_sound():
	if second_switch_sound_distance != -1 and second_switch_sound_distance < wagon.distance_on_route:
		$SwitchSound2.play()
		second_switch_sound_distance = -1
		
	if not wagon.switch_on_next_change:
		return
	
	if wagon.forward:
		if wagon.current_rail.length - (wagon.distance_on_rail + wagon.length/2.0) < 1 and not wagon.current_rail == last_switch_sound_rail:
			$SwitchSound.play()
			last_switch_sound_rail = wagon.current_rail
			second_switch_sound_distance = wagon.distance_on_route + wagon.length -1
	else:
		if wagon.distance_on_rail - wagon.length/2.0 < 1 and not wagon.current_rail == last_switch_sound_rail:
			$SwitchSound.play()
			last_switch_sound_rail = wagon.current_rail
			second_switch_sound_distance = wagon.distance_on_route + wagon.length -1
			
	
	
		
	
	
