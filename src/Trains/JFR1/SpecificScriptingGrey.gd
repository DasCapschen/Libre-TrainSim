extends Node


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
onready var player = get_parent()

var is_ready = false
# Called when the node enters the scene tree for the first time.
func ready():
	if player.ai: return
	get_node("../Cabin/DisplayMiddle").set_clear_mode(Viewport.CLEAR_MODE_ONLY_NEXT_FRAME)
	var texture = get_node("../Cabin/DisplayMiddle").get_texture()
	get_node("../Cabin/ScreenMiddle").material_override.emission_texture = texture
	get_node("../Cabin/DisplayMiddle/Display").blinking_timer = player.get_node("HUD").get_node("IngameInformation/TrainInfo/Screen1").blinking_timer
	
	get_node("../Cabin/DisplayLeft").set_clear_mode(Viewport.CLEAR_MODE_ONLY_NEXT_FRAME)
	texture = get_node("../Cabin/DisplayLeft").get_texture()
	get_node("../Cabin/ScreenLeft").material_override.emission_texture = texture
	
	get_node("../Cabin/DisplayRight").set_clear_mode(Viewport.CLEAR_MODE_ONLY_NEXT_FRAME)
	texture = get_node("../Cabin/DisplayRight").get_texture()
	get_node("../Cabin/ScreenRight").material_override.emission_texture = texture
	
	get_node("../Cabin/DisplayReverser").set_clear_mode(Viewport.CLEAR_MODE_ONLY_NEXT_FRAME)
	texture = get_node("../Cabin/DisplayReverser").get_texture()
	get_node("../Cabin/ScreenReverser").material_override.emission_texture = texture


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if player.ai: return
	if not is_ready: 
		is_ready = true
		ready()
	get_node("../Cabin/DisplayMiddle/Display").update_display(Math.speed_to_kmh(player.speed), player.technical_soll, player.door_status, player.enforced_braking, player.sifa, player.automatic_driving, player.current_speed_limit, player.engine, player.reverser)

	get_node("../Cabin/DisplayLeft/ScreenLeft2").update_time(player.time)
	get_node("../Cabin/DisplayLeft/ScreenLeft2").update_voltage(player.voltage)
	get_node("../Cabin/DisplayLeft/ScreenLeft2").update_command(player.command)
	
	var stations = player.stations
	get_node("../Cabin/DisplayRight/ScreenRight").update_display(stations["arrival_time"], stations["departure_time"], stations["station_name"], stations["stop_type"], stations["passed"], player.is_in_station)
	
	update_Combi_Roll(player.soll_command, get_node("../Cabin/BrakeRoll"))
	update_reverser(player.reverser, get_node("../Cabin/Reverser"))


func update_reverser(command, node):
	match command:
		player.ReverserState.FORWARD:
			node.rotation_degrees.y = -120
		player.ReverserState.NEUTRAL:
			node.rotation_degrees.y = -90
		player.ReverserState.REVERSE:
			node.rotation_degrees.y = -60


func update_Combi_Roll(command, node):
	node.rotation_degrees.z = 45*command+1

func update_Brake_Roll(command, node):
	var rotation
	if command > 0:
		rotation = 45
	else:
		rotation = 45 + command*90
	node.rotation_degrees.z = rotation

func update_Acc_Roll(command, node):
	var rotation
	if command < 0:
		rotation = 45
	else:
		rotation = 45 - command*90
	node.rotation_degrees.z = rotation
