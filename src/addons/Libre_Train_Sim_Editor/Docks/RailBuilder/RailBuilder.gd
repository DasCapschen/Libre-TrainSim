@tool
class_name RailBuilderDock extends Control


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var world: World
var current_rail
var eds # Editor Selection
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func update_selected_rail(node):
	if node.is_in_group("Rail"):
		current_rail = node
		$CurrentRail/Name.text = node.name
		$ManualMoving.pressed = current_rail.manual_moving
		current_rail._update(true)
		$S.visible = true
		$RotationHeight.visible = true
		update_RotationHeightData()
		update_generalInformation()
		if current_rail.parallel_rail != "":
			$S/Settings.hide()
			$S/General/ParallelRail.show()
			return
		$S/Settings.show()
		$S/General/ParallelRail.hide()
		$S/Settings/Length/LineEdit.text = str(node.length)
		$S/Settings/Radius/LineEdit.text = str(node.radius)
		$S/Settings/Angle/LineEdit.text =  str(current_rail.end_rot - current_rail.start_rot)
		
		
		self.set_tendSlopeData(current_rail.get_tendSlopeData())
	else:
		current_rail = null
		$CurrentRail/Name.text = ""
		$RotationHeight.visible = false
		$S.visible = false
		


func _on_OptionButton_item_selected(id):
	if id == 0: # Length Radius
		$S/Settings/Length.visible = true
		$S/Settings/Radius.visible = true
		$S/Settings/Angle.visible = false
	if id == 1: # Radius Angle
		$S/Settings/Length.visible = false
		$S/Settings/Radius.visible = true
		$S/Settings/Angle.visible = true
	if id == 2: # Length Angle
		$S/Settings/Length.visible = true
		$S/Settings/Radius.visible = false
		$S/Settings/Angle.visible = true

func _on_Update_pressed():
	if $CurrentRail/Name.text != current_rail.name: 
		current_rail = null
		update_selected_rail(self)
	if current_rail == null: return
	
	current_rail.rail_type_path = $S/General/RailType/LineEdit.text
	current_rail.distance_to_parllel_rail = float($S/General/ParallelRail/ParallelDistance.text)
	if $S/Settings.visible:
		var radius
		var length
		
		if $S/Settings/OptionButton.selected == 0: ## Radius - Length
			radius = float($S/Settings/Radius/LineEdit.text)
			length = float($S/Settings/Length/LineEdit.text)
		elif $S/Settings/OptionButton.selected == 1: ## Radius - Angle
			radius = float($S/Settings/Radius/LineEdit.text)
			var angle = float($S/Settings/Angle/LineEdit.text)
			length = (radius * 2.0 * PI) * angle/360.0
		elif $S/Settings/OptionButton.selected == 2: ## Length Angle
			length = float($S/Settings/Length/LineEdit.text)
			var angle = float($S/Settings/Angle/LineEdit.text)
			if angle == 0:
				radius = 0
			else: 
				radius = length / ((angle/360.0)*2.0*PI)
			print(radius)
		
		if length > 1000:
			print("MaxRailLength of 1000 exceedet! Canceling..")
			return
		if length != 0:
			current_rail.length = length
			current_rail.radius = radius
		current_rail.set_tendSlopeData(self.get_tendSlopeData())
	
	current_rail._update(true)
	update_selected_rail(current_rail)
	print("Rail updated.")
	pass # Replace with function body.


func _on_AddRail_pressed():
	if current_rail == null: return
	if $CurrentRail/Name.text != current_rail.name: 
		current_rail = null
		update_selected_rail(self)
	if $AddRail/Mode.selected == 0: ## After rail
		var rail_parent = world.get_node("Rails")
		var rail_node = preload("res://addons/Libre_Train_Sim_Editor/Data/Modules/Rail.tscn")
		var new_rail = rail_node.instantiate()
		new_rail.name = current_rail.name
		new_rail.position = current_rail.end_pos
		new_rail.rotation.y = current_rail.end_rot
		new_rail.length = float($S/Settings/Length/LineEdit.text)
		new_rail.radius = float($S/Settings/Radius/LineEdit.text)
		new_rail.rail_type_path = $S/General/RailType/LineEdit.text
		new_rail.start_tend = current_rail.end_tend
		new_rail.end_tend = current_rail.end_tend
		new_rail.start_slope = current_rail.end_slope
		new_rail.end_slope =  current_rail.end_slope
		rail_parent.add_child(new_rail)
		new_rail.set_owner(current_rail.find_parent("World"))
		update_selected_rail(new_rail)
		eds.clear()
		eds.add_node(new_rail)
	if $AddRail/Mode.selected == 1: ## Parallel rail
		var rail_parent = current_rail.get_parent()
		var rail_node = preload("res://addons/Libre_Train_Sim_Editor/Data/Modules/Rail.tscn")
		var new_rail = rail_node.instantiate()
		new_rail.name = current_rail.name + "P"
		new_rail.parallel_rail = current_rail.name
		new_rail.distance_to_parllel_rail = float($AddRail/ParallelDistance/LineEdit.text)
#		current_rail.others_distance = float($AddRail/ParallelDistance/LineEdit.text)
#		current_rail.calc_parallel_rail(true)
#		new_rail.translation = current_rail.translation + (Vector3(1, 0, 0).rotated(Vector3(0,1,0), current_rail.rotation.y-90)*float($AddRail/ParallelDistance/LineEdit.text))
#		new_rail.rotation.y = current_rail.rotation.y
#		new_rail.length = current_rail.others_length
#		new_rail.radius = current_rail.others_radius
#		new_rail.railType = $S/General/RailType/LineEdit.text
#		new_rail.set_tendSlopeData(current_rail.get_tendSlopeData())
		rail_parent.add_child(new_rail)
		new_rail.set_owner(current_rail.find_parent("World"))
		update_selected_rail(new_rail)
		eds.clear()
		eds.add_node(new_rail)
	if $AddRail/Mode.selected == 2: ## Before rail
		var rail_parent = current_rail.get_parent()
		var rail_node = preload("res://addons/Libre_Train_Sim_Editor/Data/Modules/Rail.tscn")
		var new_rail = rail_node.instantiate()
		new_rail.name = current_rail.name
		new_rail.translation = current_rail.translation
		new_rail.rotation.y = current_rail.rotation.y + deg2rad(180)
		new_rail.length = float($S/Settings/Length/LineEdit.text)
		new_rail.radius = float($S/Settings/Radius/LineEdit.text)
		new_rail.rail_type_path = $S/General/RailType/LineEdit.text
		new_rail.start_tend = -current_rail.start_tend
		new_rail.end_tend = -current_rail.start_tend
		new_rail.start_slope = -current_rail.start_slope
		new_rail.end_slope = -current_rail.start_slope
		rail_parent.add_child(new_rail)
		new_rail.set_owner(current_rail.find_parent("World"))
		update_selected_rail(new_rail)
		eds.clear()
		eds.add_node(new_rail)
		
		
		
	print("Rail added.")
	pass # Replace with function body.


func _on_Rename_pressed():
	if current_rail == null: return
	$CurrentRail/Name.text = $CurrentRail/Name.text.replace(" ", "_")
	current_rail.name = $CurrentRail/Name.text
	update_selected_rail(current_rail)
	print("Rail renamed.")
	pass # Replace with function body.


func _on_Delete_pressed():
	current_rail.free()
	current_rail = null
	update_selected_rail(self)
	print("Rail deleted.")
	pass # Replace with function body.


func _on_Mode_item_selected(id):
	$AddRail/ParallelDistance.visible = (id == 1)


func _on_ShiftButton_pressed():
	if current_rail == null: return
	if $CurrentRail/Name.text != current_rail.name: 
		current_rail = null
		update_selected_rail(self)
	
	current_rail.radius = float($S/Settings/Shift/Radius/LineEdit.text)
	current_rail.in_shift = float($S/Settings/Shift/Shift/LineEdit.text)
	if current_rail.radius < 0 and current_rail.in_shift > 0:
		current_rail.in_shift = current_rail.in_shift*-1
	current_rail.calc_shift(true)
	if current_rail.out_length > 1000:
		print("MaxRailLength of 1000 exceedet! Canceling..")
		return
	current_rail.length = current_rail.out_length
	current_rail._update(true)
	update_selected_rail(current_rail)
	pass # Replace with function body.


func _on_Shift2Button_pressed():
	if current_rail == null: return
	if $CurrentRail/Name.text != current_rail.name: 
		current_rail = null
		update_selected_rail(self)
		
	var data = calc_shift(float($S/Settings/Shift2/LengthForward/LineEdit.text), float($S/Settings/Shift2/Shift/LineEdit.text))
	if data[1] > 1000:
		print("MaxRailLength of 1000 exceedet! Canceling..")
		return
	current_rail.length = data[1]
	current_rail.radius = data[0]
	current_rail._update(true)
	
	pass # Replace with function body.

## Calculate the shift of an rail, given with relational length and shift
func calc_shift(x, y): ## This is 2 dimensional
	if y == 0:
		return [0, x]
	var delta = rad2deg(atan(y/x))
	var gamma = 90 - delta
	var beta = 180-90-gamma  ## Angle of "Rail Circle"
	#print(beta)
	var b = sqrt((x*x) + (y*y)) ## Shortest length between beginning and end of the rail

	var a = (b / cos(deg2rad(gamma)))/2 ## Radius of "Rail Circle"

	
	var length = (beta*2)/360 * 2*PI*a ## Lenght of the rail
	return [a, length]


## Connect two rails:
func _on_Connect_pressed():
	var rail_parent = world.get_node("Rails")
	var first_rail = rail_parent.get_node($RailConnector/FirstRail/LineEdit.text)
	var second_rail = rail_parent.get_node($RailConnector/SecondRail/LineEdit.text)
	if not (first_rail.is_in_group("Rail") and second_rail.is_in_group("Rail")) :
		print("Some rail not found. Check your spelling!")
		return
	print("Rails connected.")
	
	first_rail._update(true)
	second_rail._update(true)
	var pos1
	var rot1
	if $RailConnector/FirstRail/OptionButton.selected == 0:
		pos1 = first_rail.translation
		rot1 = first_rail.rotation.y + deg2rad(180)
	else:
		pos1 = first_rail.end_pos
		rot1 = first_rail.end_rot
		
	var pos2
	var rot2
	if $RailConnector/SecondRail/OptionButton.selected == 0:
		pos2 = second_rail.translation
		rot2 = second_rail.rotation.y + deg2rad(180)
	else:
		pos2 = second_rail.end_pos
		rot2 = second_rail.end_rot
	
	var vector = (pos2 - pos1)/2
	print(vector)
	vector = vector.rotated(Vector3(0,1,0), -deg2rad(rot1))
	
	var rail_node = preload("res://addons/Libre_Train_Sim_Editor/Data/Modules/Rail.tscn")
	
	## rail 1:
	var new_rail = rail_node.instantiate()
	new_rail.name = str(first_rail.name) + "Connector"
	new_rail.translation = pos1
	new_rail.rotation.y = rot1
	var data = calc_shift(vector.x, -vector.z)
	new_rail.length = data[1]
	new_rail.radius = data[0]
	rail_parent.add_child(new_rail)
	new_rail.set_owner(current_rail.find_parent("World"))
	pos2 = new_rail.end_pos
	rot2 = new_rail.end_rot
	
	## rail 2:
	new_rail = rail_node.instantiate()
	new_rail.name = str(second_rail.name) + "Connector"
	new_rail.position = pos2
	new_rail.rotation.y = rot2
	data = calc_shift(vector.x, -vector.z)
	new_rail.length = data[1]
	new_rail.radius = -data[0]
	rail_parent.add_child(new_rail)
	new_rail.set_owner(current_rail.find_parent("World"))

	pass # Replace with function body.



func _on_Select_FirstRail_pressed():
	if $CurrentRail/Name.text != current_rail.name: 
		current_rail = null
		update_selected_rail(self)
	if current_rail == null: return
	$RailConnector/FirstRail/LineEdit.text = current_rail.name


func _on_Select_SecondRail_pressed():
	if $CurrentRail/Name.text != current_rail.name: 
		current_rail = null
		update_selected_rail(self)
	if current_rail == null: return
	$RailConnector/SecondRail/LineEdit.text = current_rail.name





func _on_ShowHideTendency_pressed():
	if $S/Settings/Tendency/S.visible:
		$S/Settings/Tendency/ShowHideTendency.text = "Show Tendency"
		$S/Settings/Tendency/S.visible = false
		$S/Settings/Tendency/S2.visible = false
		$S/Settings/Tendency/automaticTendency.hide()
	else:
		$S/Settings/Tendency/ShowHideTendency.text = "Hide Tendency"
		$S/Settings/Tendency/S.visible = true
		$S/Settings/Tendency/S2.visible = true
		$S/Settings/Tendency/automaticTendency.show()


func _on_ShowHideSlope_pressed():
	if $S/Settings/Slope/SlopeGrid.visible:
		$S/Settings/Slope/ShowHideSlope.text = "Show Slope"
		$S/Settings/Slope/SlopeGrid.visible = false
	else:
		$S/Settings/Slope/ShowHideSlope.text = "Hide Slope"
		$S/Settings/Slope/SlopeGrid.visible = true


func get_tendSlopeData():
	var d = {}
	d.start_slope = $S/Settings/Slope/SlopeGrid/StartSlope.value
	d.end_slope = $S/Settings/Slope/SlopeGrid/EndSlope.value
	d.start_tend = $S/Settings/Tendency/S/StartTend.value
	d.end_tend = $S/Settings/Tendency/S/EndTend.value
	d.tend1_pos = $S/Settings/Tendency/S2/Tend1Pos.value
	d.tend1 = $S/Settings/Tendency/S2/Tend1.value
	d.tend2_pos = $S/Settings/Tendency/S2/Tend2Pos.value
	d.tend2 = $S/Settings/Tendency/S2/Tend2.value
	d.automatic_tendency = $S/Settings/Tendency/automaticTendency.pressed
	return d

func set_tendSlopeData(data):
	var s = data
	$S/Settings/Slope/SlopeGrid/StartSlope.value = s.start_slope
	$S/Settings/Slope/SlopeGrid/EndSlope.value = s.end_slope
	$S/Settings/Tendency/S/StartTend.value = s.start_tend
	$S/Settings/Tendency/S/EndTend.value = s.end_tend
	$S/Settings/Tendency/S2/Tend1Pos.value = s.tend1_pos
	$S/Settings/Tendency/S2/Tend1.value = s.tend1
	$S/Settings/Tendency/S2/Tend2Pos.value = s.tend2_pos
	$S/Settings/Tendency/S2/Tend2.value = s.tend2
	$S/Settings/Tendency/automaticTendency.pressed = s.automatic_tendency
	$S/Settings/Tendency/S2/Tend1Pos.editable = !s.automatic_tendency
	$S/Settings/Tendency/S2/Tend1.editable = !s.automatic_tendency
	$S/Settings/Tendency/S2/Tend2Pos.editable = !s.automatic_tendency
	$S/Settings/Tendency/S2/Tend2.editable = !s.automatic_tendency
	
	

func update_RotationHeightData():
	$RotationHeight/StartRotation.text = str(current_rail.start_rot)
	$RotationHeight/EndRotation.text =str( current_rail.end_rot)
	$RotationHeight/StartHeight.text = str(current_rail.start_pos.y)
	$RotationHeight/EndHeight.text = str(current_rail.end_pos.y)

func update_generalInformation():
	$S/General/RailType/LineEdit.text = current_rail.rail_type_path
	$S/General/OverheadLine.pressed = current_rail.overhead_line
	$S/General/ParallelRail/ParallelRail.text = current_rail.parallel_rail
	$S/General/ParallelRail/ParallelDistance.text = str(current_rail.distance_to_parllel_rail)
	


func _on_ManualMoving_pressed():
	current_rail.manual_moving = $ManualMoving.pressed
	


func _on_automaticTendency_pressed():
	current_rail.automatic_tendency = $S/Settings/Tendency/automaticTendency.pressed
	current_rail.update_automatic_tendency()
	set_tendSlopeData(current_rail.get_tendSlopeData())
	current_rail._update(true)
	
	




func _on_OverheadLine_pressed():
	current_rail.overhead_line = $S/General/OverheadLine.pressed
	current_rail.update_overhead_line()
