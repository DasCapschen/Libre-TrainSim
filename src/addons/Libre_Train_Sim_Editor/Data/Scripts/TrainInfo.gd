extends Control


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
var red = preload("res://addons/Libre_Train_Sim_Editor/Data/Misc/DotRed.png")
var green = preload("res://addons/Libre_Train_Sim_Editor/Data/Misc/DotGreen.png")
var orange = preload("res://addons/Libre_Train_Sim_Editor/Data/Misc/DotOrange.png")

func update_info(player):
	if player.engine:
		$ScrollContainer/VBoxContainer/Engine/dot.texture = green
	else:
		$ScrollContainer/VBoxContainer/Engine/dot.texture = red
	
	
	## Pantograph:
	$ScrollContainer/VBoxContainer/Pantograpgh.visible = player.electric
	if player.pantograph:
		$ScrollContainer/VBoxContainer/Pantograpgh/dot.texture = green
	else:
		if player.pantograph_up:
			$ScrollContainer/VBoxContainer/Pantograpgh/dot.texture = orange
		else:
			$ScrollContainer/VBoxContainer/Pantograpgh/dot.texture = red
	
	## Doors:
	$ScrollContainer/VBoxContainer/Doors.visible = player.doors
	if player.door_status == DoorState.CLOSED:
		$ScrollContainer/VBoxContainer/Doors/dot.texture = green
	elif player.door_status == DoorState.CLOSING:
		$ScrollContainer/VBoxContainer/Doors/dot.texture = orange
	else:
		$ScrollContainer/VBoxContainer/Doors/dot.texture = red
	
	## Control Type:
	if player.control_type == ControlType.COMBINED:
		$"ScrollContainer/VBoxContainer/Brakes-1".hide()
		$"ScrollContainer/VBoxContainer/Acceleration-1".hide()
	else:
		$"ScrollContainer/VBoxContainer/Brakes-0".hide()
		$"ScrollContainer/VBoxContainer/Acceleration-0".hide()
		
		
	## Brakes:
	if player.technical_soll < 0:
		$"ScrollContainer/VBoxContainer/Brakes-0/dot".texture = red
		$"ScrollContainer/VBoxContainer/Brakes-1/dot".texture = red
	else:
		if player.command < 0:
			$"ScrollContainer/VBoxContainer/Brakes-0/dot".texture = orange
			$"ScrollContainer/VBoxContainer/Brakes-1/dot".texture = orange
		else:
			$"ScrollContainer/VBoxContainer/Brakes-0/dot".texture = green
			$"ScrollContainer/VBoxContainer/Brakes-1/dot".texture = green
	
	## Acceleration:
	if player.blocked_acceleration:
		$"ScrollContainer/VBoxContainer/Acceleration-0/dot".texture = red
		$"ScrollContainer/VBoxContainer/Acceleration-1/dot".texture = red
	else:
		$"ScrollContainer/VBoxContainer/Acceleration-0/dot".texture = green
		$"ScrollContainer/VBoxContainer/Acceleration-1/dot".texture = green
	
	## EnforcedBreake
	if player.enforced_braking:
		$ScrollContainer/VBoxContainer/EnforcedBreaking/dot.texture = red
	else:
		$ScrollContainer/VBoxContainer/EnforcedBreaking/dot.texture = green
	
	## SiFa
	$ScrollContainer/VBoxContainer/SiFa.visible = player.is_sifa_enabled
	if player.sifa_timer > 35:
		$ScrollContainer/VBoxContainer/SiFa/dot.texture = red
	elif player.sifa_timer > 25:
		$ScrollContainer/VBoxContainer/SiFa/dot.texture = orange
	else:
		$ScrollContainer/VBoxContainer/SiFa/dot.texture = green
	
	$ScrollContainer/VBoxContainer/Autopilot.visible = Root.easy_mode
	if player.automatic_driving:
		$ScrollContainer/VBoxContainer/Autopilot/dot.texture = green
	else:
		$ScrollContainer/VBoxContainer/Autopilot/dot.texture = red
	
	if player.front_light:
		$ScrollContainer/VBoxContainer/FrontLight/dot.texture = green
	else:
		$ScrollContainer/VBoxContainer/FrontLight/dot.texture = red
	
	if player.inside_light:
		$ScrollContainer/VBoxContainer/InsideLight/dot.texture = green
	else:
		$ScrollContainer/VBoxContainer/InsideLight/dot.texture = red
