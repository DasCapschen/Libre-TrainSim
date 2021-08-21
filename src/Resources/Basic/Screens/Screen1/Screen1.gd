extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

export (float) var speed_pointer_rotation_at_100 
export (float) var soll_speed_pointer_rotation_at_100 
var speed_pointer_zero
var speed_per_kmh
var soll_speed_pointer_zero
var soll_speed_per_kmh

onready var world = find_parent("World")


export (float) var command_pointer_rotation_at_100 
export (float) var blinking_time = 0.8
var command_pointer_zero
var command_per_percent

var syncronizing_screen = false
# Called when the node enters the scene tree for the first time.
func _ready():
	if not  world.global_dict.has("Screen1.BlinkingStatus"):
		syncronizing_screen = true
		world.global_dict["Screen1.BlinkingStatus"] = false
		
	speed_pointer_zero = $SpeedPointer.rotation_degrees
	speed_per_kmh = (speed_pointer_rotation_at_100-speed_pointer_zero)/100.0
	
	soll_speed_pointer_zero = $SpeedLimitPointer.rotation_degrees
	soll_speed_per_kmh = (soll_speed_pointer_rotation_at_100 - soll_speed_pointer_zero)/100.0
	
	command_pointer_zero = $CommandPointer.rotation_degrees
	command_per_percent = (command_pointer_rotation_at_100-command_pointer_zero)/100.0
	#print("DISPLAY: " + String(speed_per_kmh) + " " + String(speed_pointer_zero) + " " + String(speed_pointer_rotation_at_100))
	pass # Replace with function body.

var soll_command_pointer = 0
var soll_speed_limit_pointer = 0
var blinking_timer = 0
var blink_status = false
func _process(delta):
	$CommandPointer.rotation_degrees = (soll_command_pointer - $CommandPointer.rotation_degrees)*delta*4.0 + $CommandPointer.rotation_degrees
	$SpeedLimitPointer.rotation_degrees = (soll_speed_limit_pointer - $SpeedLimitPointer.rotation_degrees)*delta*4.0 + $SpeedLimitPointer.rotation_degrees
	if syncronizing_screen:
		blinking_timer += delta
		if blinking_timer > blinking_time:
			blink_status = !blink_status
			world.global_dict["Screen1.BlinkingStatus"] = blink_status
			blinking_timer = 0
	
	blink_status = world.global_dict["Screen1.BlinkingStatus"]
		

	
var last_auto_pilot = false
func update_display(speed, command, door_status, enforced_braking, sifa, autopilot, speed_limit, engine, reverser):
	## Tachos:
	$SpeedPointer.rotation_degrees = speed_pointer_zero+speed_per_kmh*speed 
	soll_command_pointer = command_pointer_zero+command_per_percent*command*100 
	soll_speed_limit_pointer = soll_speed_pointer_zero+soll_speed_per_kmh*speed_limit 
	
	
	$Speed.text = String(int(speed))
	$Time.text = Math.time_to_string(world.time)
	
	## Engine:
	$Engine.visible = !engine
	
	## Enforced Breaking
	if enforced_braking:
		$EnforcedBraking.visible = blink_status
	else:
		$EnforcedBraking.visible = false
	
	## Sifa:
	$Sifa.visible = sifa
	
	## Doors:
	if door_status == DoorState.CLOSING:
		$Doors.visible = blink_status
	else:
		$Doors.visible = true
	$Doors/Right.visible = door_status & DoorState.RIGHT
	$Doors/Left.visible = door_status & DoorState.LEFT
	$Doors/Door.visible = door_status & DoorState.BOTH

	$Reverser/Forward.visible = reverser == ReverserState.FORWARD
	$Reverser/Backward.visible = reverser == ReverserState.REVERSE
	$Reverser/Neutral.visible = reverser == ReverserState.NEUTRAL

#	if not lastAutoPilot and autopilot:
#		$AnimationPlayerAutoPilot.play("autopilot")
	$Autopilot.visible = autopilot and blink_status
#	last_auto_pilot = autopilot
	
		
		
	
	
	
	

