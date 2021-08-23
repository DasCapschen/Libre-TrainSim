extends Node3D

var player
@onready var wagon = get_parent()

@export_file("*.ogg,*.wav,*.mp3") var engine_idle_path = "res://Resources/Basic/Sounds/EngineIdle.ogg"
@export_file("*.ogg,*.wav,*.mp3") var acceleration_path = "res://Resources/Basic/Sounds/Acceleration3.ogg"

func _ready():
	$Idle.stream = load(engine_idle_path)
	$Acceleration.stream = load(acceleration_path)
	
	$Idle.unit_db = -50
	$Acceleration.unit_db = -50
	
func _process(delta):
	if player == null:
		player = get_parent().player
		return	
	
	
	if player.engine:
		$Idle.unit_db = Root.clamp_via_time(0, $Idle.unit_db, delta)
	else:
		$Idle.unit_db = Root.clamp_via_time(-50, $Idle.unit_db, delta)
		
	var soll_acceleration = -50
	if player.command > 0 and player.engine and player.speed != 0:
		if  Math.speed_to_kmh(player.speed) < 60:
			soll_acceleration = -30 + abs(player.command*30)
		else:
			soll_acceleration = -30 + abs(player.command*30) - (Math.speed_to_kmh(player.speed)-60)*3.0
	
	$Acceleration.unit_db = Root.clamp_via_time(soll_acceleration, $Acceleration.unit_db, delta)

	$Idle.stream_paused = not wagon.visible
	$Acceleration.stream_paused = not wagon.visible
#
#
### soll_curve_sound:
#	if wagon.current_rail.radius == 0 or Math.speed_to_kmh(player.speed) < 35:
#		soll_curve_sound = -50
#	else:
#		soll_curve_sound = -25.0 + (Math.speed_to_kmh(player.speed)/80.0 * abs(300.0/wagon.current_rail.radius))*5
#
##	print(soll_curve_sound)
#	$CurveSound.unit_db = Root.clamp_via_time(soll_curve_sound, $CurveSound.unit_db, delta)
##	$CurveSound.unit_db = 10
#
#	## Drive Sound:
#	$DriveSound.pitch_scale = 0.5 + Math.speed_to_kmh(player.speed)/200.0
#	var drive_sound_db = -20.0 + Math.speed_to_kmh(player.speed)/2.0
#	if drive_sound_db > 10:
#		drive_sound_db = 10
#	if player.speed == 0:
#		drive_sound_db = -50.0
#	$DriveSound.unit_db = Root.clamp_via_time(drive_sound_db, $DriveSound.unit_db, delta) 
#
#	var soll_brake_sound = -50.0
#	if not (player.speed >= 5 or player.command >= 0 or player.speed == 0):
#		soll_brake_sound = -20.0 -player.command * 5.0/player.speed
#		if soll_brake_sound > 10:
#			soll_brake_sound = 10
#	$BrakeSound.unit_db = Root.clamp_via_time(soll_brake_sound, $BrakeSound.unit_db, delta)
