extends CanvasLayer

################################################################################
## To Content-Creators: DO NOT EDIT THIS SCRIPT!! This Script will be overwritten by the game.
################################################################################

onready var player = get_parent()

func _ready():
	$MobileHUD.visible = Root.mobile_version
	if Root.mobile_version:
		$IngameInformation/Next.rect_position.y += 100
		$TextBox/RichTextLabel.hide()
		$TextBox/RichTextLabelMobile.show()
		$TextBox/Ok.add_font_override("font", preload("res://addons/Libre_Train_Sim_Editor/Data/Misc/FontMenu.tres"))

	
func _process(delta):
	if $TextBox.visible:
		if Input.is_action_just_pressed("ui_accept"):
			_on_OkTextBox_pressed()
	
	check_escape(delta)
	
	check_train_info_above(delta)
	
	check_next_table(delta)
	
	check_train_info(delta)
	
	if sending:
		messaget += delta
		if messaget > 4:
			$Message.play("FadeOut")
			sending = false
	$FPS.text = String(Engine.get_frames_per_second())
	
#	$IngameInformation/Speed/Speed.text = "Speed: " + String(int(Math.speed_to_kmh((get_parent().speed)))) + " km/h"
#	$IngameInformation/Speed/CurrentLimit.text = "Speed Limit: " + String(get_parent().current_speed_limit) + " km/h"
	
#	var alpha = (Math.speed_to_kmh(get_parent().speed)/get_parent().current_speed_limit)*2 -1
#	if alpha < 0:
#		alpha = 0
#	$IngameInformation/Speed/CurrentLimit.modulate.a = alpha
	
	if $Pause.visible or $TextBox.visible or $MobileHUD/Pause.visible:
		get_tree().paused = true
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		get_tree().paused = false
		
	update_nextTable(delta)
	
	$IngameInformation/TrainInfo/Screen1.update_display(Math.speed_to_kmh(player.speed), player.technical_soll, player.door_status, player.enforced_braking, player.sifa, player.automatic_driving, player.current_speed_limit, player.engine)
		


var sending = false
var messaget = 0
func send_Message(text):
	$MarginContainer/Label.text = text
	$Message.play("FadeIn")
	$Bling.play()
	messaget = 0
	sending = true
	
func check_escape(delta):
	if Input.is_action_just_pressed("Escape"):
		get_tree().paused = true
		$Pause.visible = true


func _on_Back_pressed():
	get_tree().paused = false
	$Pause.visible = false


func _on_Quit_pressed():
	get_tree().quit()
	

func show_textbox_message(string):
	$TextBox/RichTextLabel.text = string
	$TextBox/RichTextLabelMobile.text = string
	get_tree().paused = true
	$TextBox.visible = true
	


func _on_OkTextBox_pressed():
	get_tree().paused = false
	$TextBox.visible = false
	if $Black.visible:
		$Black/AnimationPlayer.play("FadeOut")
	
var modulation = 0
func check_train_info(delta):
	if Input.is_action_just_pressed("trainInfo"):
		modulation += 0.5
		if modulation > 1: 
			modulation = 0
		$IngameInformation/TrainInfo.modulate = Color( 1, 1, 1, modulation)

func check_next_table(delta):
	if Input.is_action_just_pressed("nextTable"):
		$IngameInformation/Next.visible = !$IngameInformation/Next.visible



func _on_QuitMenu_pressed():
	get_tree().paused = false
	jAudioManager.clear_all_sounds()
	jEssentials.remove_all_pending_delayed_calls()
	get_tree().change_scene("res://addons/Libre_Train_Sim_Editor/Data/Modules/MainMenu.tscn")
	pass # Replace with function body.

func check_train_info_above(delta):
	if Input.is_action_just_pressed("trainInfoAbove"):
		$IngameInformation/TrainInfoAbove.visible = not $IngameInformation/TrainInfoAbove.visible
	if $IngameInformation/TrainInfoAbove.visible:
		$IngameInformation/TrainInfoAbove.update_info(get_parent())

var red_signal = preload("res://addons/Libre_Train_Sim_Editor/Data/Misc/RedSignal.png")
var green_signal = preload("res://addons/Libre_Train_Sim_Editor/Data/Misc/GreenSignal.png")
var orange_signal = preload("res://addons/Libre_Train_Sim_Editor/Data/Misc/OrangeSignal.png")
func update_nextTable(delta):
	## Update Next Signal:
	$IngameInformation/Next/GridContainer/DistanceToSignal.text = Math.distance_to_string(player.distance_to_next_signal)
	if player.next_signal != null:
		match player.next_signal.status:
			SignalState.RED:
				$IngameInformation/Next/GridContainer/Signal.texture = red_signal
			SignalState.GREEN:
				$IngameInformation/Next/GridContainer/Signal.texture = green_signal
			SignalState.ORANGE:
				$IngameInformation/Next/GridContainer/Signal.texture = orange_signal
				
	
	## Update next Speedlimit
	
	if player.next_speed_limit_node != null:
		$IngameInformation/Next/GridContainer/DistanceToSpeedLimit.text = Math.distance_to_string(player.distance_to_next_speed_limit)
		$IngameInformation/Next/GridContainer/SpeedLimit.text = String(player.next_speed_limit_node.speed) + " km/h"
	else:
		$IngameInformation/Next/GridContainer/DistanceToSpeedLimit.text = "-"
	
	## Update Next Station 
	var stations = player.stations
	if stations.passed.size() == 0 or (player.end_station and player.is_in_station):
		$IngameInformation/Next/GridContainer/Arrival.text = "-"
		$IngameInformation/Next/GridContainer/DistanceToStation.text = "-"
	else:
		if player.is_in_station:
			for i in range (0, stations.passed.size()):
				if stations.passed[i]: continue
				$IngameInformation/Next/GridContainer/Arrival.text = Math.time_to_string(player.stations["departure_time"][i])
				$IngameInformation/Next/GridContainer/DistanceToStation.text = "-"
				
				break
		else:
			for i in range (0, stations.passed.size()):
				
				if stations.passed[i] or stations.node_name[i] != player.next_station: continue
				$IngameInformation/Next/GridContainer/Arrival.text = Math.time_to_string(player.stations["arrival_time"][i])
				$IngameInformation/Next/GridContainer/DistanceToStation.text = Math.distance_to_string(player.distance_to_next_station)
				
				break
				

	

