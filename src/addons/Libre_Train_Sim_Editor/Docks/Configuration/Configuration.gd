@tool
class_name ConfigurationDock extends Control


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var world: World
var config
var save_path

var current_scenario = ""
var loaded_current_scenario = ""

func get_all_scenarios():
	if config == null: return []
	return config.get_value("Scenarios", "List", [])

func get_world_config():
	if typeof(world) == TYPE_NIL or world.name != "World" or world.track_name.is_empty():
		return null
	var file_name = world.track_name + "/" + world.track_name
	save_path = "res://Worlds/" + file_name + "-scenarios.cfg"
	config = ConfigFile.new()
	var load_response = config.load(save_path)

func check_duplicate_scenario(s_name): # gives true, if duplicate was found
	for other_s_name in get_all_scenarios():
		if other_s_name == s_name:
			print("There already exists a scenario with this name!")
			return true
	return false

func _on_NewScenario_pressed():
	var s_name = $Scenarios/VBoxContainer/HBoxContainer/LineEdit.text
	if s_name == "" or check_duplicate_scenario(s_name): return
	var scenario_list = get_all_scenarios()
	scenario_list.append(s_name)
	config.set_value("Scenarios", "List", scenario_list)
	var scenario_data = config.get_value("Scenarios", "scenario_data", {})
	scenario_data[s_name] = {}
	config.set_value("Scenarios", "scenario_data", scenario_data)
	config.save(save_path)
	current_scenario = s_name
	update_scenario_list()
	print("Scenario added.")

func _on_RenameScenario_pressed():
	var s_name = $Scenarios/VBoxContainer/HBoxContainer/LineEdit.text
	if current_scenario == "" or s_name == "" or check_duplicate_scenario(s_name) or s_name == current_scenario: return
	var scenario_list = get_all_scenarios()
	scenario_list.erase(current_scenario)
	scenario_list.append(s_name)
	var scenario_data = config.get_value("Scenarios", "scenario_data", {})
	scenario_data[s_name] = scenario_data[current_scenario]
	config.set_value("Scenarios", "scenario_data", scenario_data)
	config.set_value("Scenarios", "List", scenario_list)
	config.save(save_path)
	current_scenario = s_name
	update_scenario_list()
	print("Scenario renamed.")

func _on_DuplicateScenario_pressed():
	var s_name = current_scenario + " (Duplicate)"
	if current_scenario == "" or s_name == "" or check_duplicate_scenario(s_name) or s_name == current_scenario: return
	var scenario_list = get_all_scenarios()
	scenario_list.append(s_name)
	var scenario_data = config.get_value("Scenarios", "scenario_data", {})
	scenario_data[s_name] = scenario_data[current_scenario].duplicate()
	config.set_value("Scenarios", "scenario_data", scenario_data)
	config.set_value("Scenarios", "List", scenario_list)
	config.save(save_path)
	reload_config()
	current_scenario = s_name
	print("Scenario dulicated.")
	update_scenario_list()
	pass # Replace with function body.

func reload_config():
	config = ConfigFile.new()
	var load_response = config.load(save_path)
	print("Scenario Config reloaded.")


func _on_DeleteScenario_pressed():
	if current_scenario == "": return
	var scenario_list = get_all_scenarios()
	scenario_list.erase(current_scenario)
	var scenario_data = config.get_value("Scenarios", "scenario_data", {})
	scenario_data.erase(current_scenario)
	config.set_value("Scenarios", "scenario_data", scenario_data)
	config.set_value("Scenarios", "List", scenario_list)
	config.save(save_path)
	current_scenario = ""
	update_scenario_list()
	print("Scenario deleted.")

var old_world
func _process(delta):
	if world == null:
		current_scenario = ""
		return
	if old_world != world:
		get_world_config()
		get_world_configuration()
		update_scenario_list()
		current_scenario = ""
	old_world = world
	var active_world = world.name == "World"
	for child in $"World Configuration".get_children():
		child.visible = active_world
	for child in $"Scenarios".get_children():
		child.visible = active_world
	if not active_world: return
	$Scenarios/VBoxContainer/CurrentScenario/LineEdit.text = current_scenario

	if $Scenarios/VBoxContainer/ItemList.get_selected_items().size() > 0:
		current_scenario = $Scenarios/VBoxContainer/ItemList.get_item_text($Scenarios/VBoxContainer/ItemList.get_selected_items()[0])

	$Scenarios/VBoxContainer/Settings.visible = current_scenario != ""
	$Scenarios/VBoxContainer/Label2.visible = current_scenario != ""
	$Scenarios/VBoxContainer/Write.visible = current_scenario != ""
	$Scenarios/VBoxContainer/Load.visible = current_scenario != ""
	$Scenarios/VBoxContainer/ResetSignals.visible = current_scenario != ""


func get_scenario_settings(): # fills the settings field with saved values
	var scenario_data = config.get_value("Scenarios", "scenario_data", {})
	if not scenario_data.has(current_scenario): return
	var s = scenario_data[current_scenario]

	$Scenarios/VBoxContainer/Settings/Tab/General/Time/TimeHour.value = s["TimeH"]
	$Scenarios/VBoxContainer/Settings/Tab/General/Time/TimeMinute.value = s["TimeM"]
	$Scenarios/VBoxContainer/Settings/Tab/General/Time/TimeSecond.value = s["TimeS"]
	$Scenarios/VBoxContainer/Settings/Tab/General/TrainLength/SpinBox.value = s["TrainLength"]
	$Scenarios/VBoxContainer/Settings/Tab/General/Description.text = s["Description"]
	$Scenarios/VBoxContainer/Settings/Tab/General/Duration/SpinBox.value = s["Duration"]
	print("Scenario Settings loaded")

func set_scenario_settings():
	if current_scenario == "": return
	var scenario_data = config.get_value("Scenarios", "scenario_data", {})
	if scenario_data == null:
		scenario_data = {}
	scenario_data[current_scenario]["TimeH"] = $Scenarios/VBoxContainer/Settings/Tab/General/Time/TimeHour.value
	scenario_data[current_scenario]["TimeM"] = $Scenarios/VBoxContainer/Settings/Tab/General/Time/TimeMinute.value
	scenario_data[current_scenario]["TimeS"] = $Scenarios/VBoxContainer/Settings/Tab/General/Time/TimeSecond.value
	scenario_data[current_scenario]["TrainLength"] = $Scenarios/VBoxContainer/Settings/Tab/General/TrainLength/SpinBox.value
	scenario_data[current_scenario]["Description"] = $Scenarios/VBoxContainer/Settings/Tab/General/Description.text
	scenario_data[current_scenario]["Duration"] = $Scenarios/VBoxContainer/Settings/Tab/General/Duration/SpinBox.value
	print("Scenario Settings saved")


	config.set_value("Scenarios", "scenario_data", scenario_data)
	config.save(save_path)
	print("Scenario General Settings saved")

func update_scenario_list():
	$Scenarios/VBoxContainer/ItemList.clear()
	if config == null: return
	var scenarios = config.get_value("Scenarios", "List", {})
	for scenario in scenarios:
		$Scenarios/VBoxContainer/ItemList.add_item(scenario)
	print("Scenario List updated.")

func update_train_list():
	$Scenarios/VBoxContainer/Settings/Tab/Trains/ItemList2.clear()
	var scenario_data = config.get_value("Scenarios", "scenario_data", {})
	if not scenario_data[current_scenario].has("Trains"): return
	var trains = scenario_data[current_scenario]["Trains"].keys()
	for train in trains:
		$Scenarios/VBoxContainer/Settings/Tab/Trains/ItemList2.add_item(train)
	print("Train List updated.")

func _on_SaveGeneral_pressed():
	set_scenario_settings()





## Load Signals
func _on_LoadScenario_pressed():
	if current_scenario == "": return
	var scenario_data = config.get_value("Scenarios", "scenario_data", {})
	if not scenario_data.has(current_scenario): return
	var scenario = scenario_data[current_scenario]
	if not scenario.has("Signals"): return
	var signals = scenario["Signals"]
	world.apply_scenario_to_signals(signals)
	print("Signal Data loaded successfully from scenario into world")

## Save Signals
func _on_WriteData_pressed():
	get_enviroment_data_for_scenario()

func get_enviroment_data_for_scenario():
	var signals = world.get_signal_data_for_scenario()
	var scenario_data = config.get_value("Scenarios", "scenario_data", {})
	if not scenario_data.has(current_scenario):
		scenario_data[current_scenario] = {}
	scenario_data[current_scenario]["Signals"] = signals
	config.set_value("Scenarios", "scenario_data", scenario_data)
	config.save(save_path)
	print("Signal Data saved successfully")


func _on_ItemList_item_selected(index):
	current_scenario = $Scenarios/VBoxContainer/ItemList.get_item_text(index)
	world.current_scenario = current_scenario
	update_train_list()
	get_train_settings()
	get_scenario_settings()

func _on_SaveChunks_pressed():
	print("Saving and Creating World Chunks..")
	world.save_world(true)

func _on_SaveWorldConfig_pressed():
	var d = {}
	#d["file_name"] = $Configuration/GridContainer/file_name.text
	d["ReleaseDate"] = [$"World Configuration/GridContainer/ReleaseDate/Day".value, $"World Configuration/GridContainer/ReleaseDate/Month".value, $"World Configuration/GridContainer/ReleaseDate/Year".value]
	d["Author"] = $"World Configuration/GridContainer/Author".text
	d["TrackDesciption"] = $"World Configuration/GridContainer/TrackDescription".text
	d["ThumbnailPath"] = $"World Configuration/GridContainer/ThumbnailPath".text
	config.set_value("WorldConfig", "Data", d)
	config.save(save_path)
	print("World Config saved.")

func get_world_configuration():
	if config == null: return
	var d = config.get_value("WorldConfig", "Data", null)
	if d == null: return
	$"World Configuration/GridContainer/ReleaseDate/Day".value = d["ReleaseDate"][0]
	$"World Configuration/GridContainer/ReleaseDate/Month".value = d["ReleaseDate"][1]
	$"World Configuration/GridContainer/ReleaseDate/Year".value = d["ReleaseDate"][2]
	$"World Configuration/GridContainer/Author".text = d["Author"]
	$"World Configuration/GridContainer/TrackDescription".text = d["TrackDesciption"]
	$"World Configuration/GridContainer/ThumbnailPath".text = d["ThumbnailPath"]

	$"World Configuration/Notes/RichTextLabel".text = world.get_value("notes", "")




## Trains:
### Station Editing: #################################

func _on_SaveTrain_pressed():
	set_train_settings()

var current_train = "Player"

func get_train_settings():
	var scenario_data = config.get_value("Scenarios", "scenario_data", {})
	if not scenario_data.has(current_scenario): return
	if not scenario_data[current_scenario].has("Trains"): return
	if not scenario_data[current_scenario]["Trains"].has(current_train):
		print("No Train Data for "+ current_train + " found. - No data loaded.")
		clear_train_settings_view()
		return
	var trains = scenario_data[current_scenario]["Trains"]
	if not trains.has(current_train): return
	var train = trains[current_train]

	$Scenarios/VBoxContainer/Settings/Tab/Trains/PreferredTrain/TrainName.text = train.get("PreferredTrain", "")
	$Scenarios/VBoxContainer/Settings/Tab/Trains/Route/Route.text = train["Route"]
	$Scenarios/VBoxContainer/Settings/Tab/Trains/GridContainer/StartRail.text = train ["StartRail"]
	$Scenarios/VBoxContainer/Settings/Tab/Trains/GridContainer/StartRailPosition.value = train["StartRailPosition"]
	$Scenarios/VBoxContainer/Settings/Tab/Trains/GridContainer/Direction.selected = train["Direction"]
	$Scenarios/VBoxContainer/Settings/Tab/Trains/GridContainer/DoorConfiguration.selected = train["DoorConfiguration"]
	print(train)
	$Scenarios/VBoxContainer/Settings/Tab/Trains/stationTable.set_data(train["Stations"])
	$Scenarios/VBoxContainer/Settings/Tab/Trains/GridContainer/SpawnTime/H.value = train["SpawnTime"][0]
	$Scenarios/VBoxContainer/Settings/Tab/Trains/GridContainer/SpawnTime/M.value = train["SpawnTime"][1]
	$Scenarios/VBoxContainer/Settings/Tab/Trains/GridContainer/SpawnTime/S.value = train["SpawnTime"][2]
	$Scenarios/VBoxContainer/Settings/Tab/Trains/GridContainer/DespawnRail.text = train["DespawnRail"]
	$Scenarios/VBoxContainer/Settings/Tab/Trains/GridContainer/InitialSpeed.value = train.get("InitialSpeed", 0)
	$Scenarios/VBoxContainer/Settings/Tab/Trains/GridContainer/InitialSpeedLimit.value = train.get("InitialSpeedLimit", -1)
	print("Train "+ current_train + " loaded.")

func set_train_settings():
	var train = {}
	train["PreferredTrain"] = $Scenarios/VBoxContainer/Settings/Tab/Trains/PreferredTrain/TrainName.text
	train["Route"] = $Scenarios/VBoxContainer/Settings/Tab/Trains/Route/Route.text
	train ["StartRail"] = $Scenarios/VBoxContainer/Settings/Tab/Trains/GridContainer/StartRail.text
	train["StartRailPosition"] = $Scenarios/VBoxContainer/Settings/Tab/Trains/GridContainer/StartRailPosition.value
	train["Direction"] = $Scenarios/VBoxContainer/Settings/Tab/Trains/GridContainer/Direction.selected
	train["DoorConfiguration"] = $Scenarios/VBoxContainer/Settings/Tab/Trains/GridContainer/DoorConfiguration.selected
	train["SpawnTime"] = [$Scenarios/VBoxContainer/Settings/Tab/Trains/GridContainer/SpawnTime/H.value, $Scenarios/VBoxContainer/Settings/Tab/Trains/GridContainer/SpawnTime/M.value, $Scenarios/VBoxContainer/Settings/Tab/Trains/GridContainer/SpawnTime/S.value]
	train["DespawnRail"] = $Scenarios/VBoxContainer/Settings/Tab/Trains/GridContainer/DespawnRail.text
	train["InitialSpeed"] = $Scenarios/VBoxContainer/Settings/Tab/Trains/GridContainer/InitialSpeed.value
	train["InitialSpeedLimit"] = $Scenarios/VBoxContainer/Settings/Tab/Trains/GridContainer/InitialSpeedLimit.value

	train["Stations"] = $Scenarios/VBoxContainer/Settings/Tab/Trains/stationTable.get_data()
	var scenario_data = config.get_value("Scenarios", "scenario_data", {})
	if not scenario_data.has(current_scenario):
		scenario_data[current_scenario] = {}
	if not scenario_data[current_scenario].has("Trains"):
		scenario_data[current_scenario]["Trains"] = {}
	scenario_data[current_scenario]["Trains"][current_train] = train
	config.set_value("Scenarios", "scenario_data", scenario_data)
	config.save(save_path)
	print("Train "+ current_train + " saved.")

#var entriesCount = 0
#const stationTableColumns = 8

#func _on_RemoveStationEntry_pressed():
#	var grid = $Scenarios/Settings/Tab/Trains/Stations/Stations
#	var children = grid.get_children()
#	if entriesCount == 0:
#		return
#	children.invert()
#	for i in range (0,stationTableColumns):
#		children[i].queue_free()
#	entriesCount -= 1


#func _on_AddStationEntry_pressed():
#	entriesCount += 1
#	var grid = $Scenarios/Settings/Tab/Trains/Stations/Stations
#	for child in grid.get_children():
#		print(child.name)
#	print("###############")
#
#	var a
#
#	a = grid.get_node("nodeName0").duplicate()
#	grid.add_child(a)
#	a.show()
#
#	a = grid.get_node("stationName0").duplicate()
#	grid.add_child(a)
#	a.show()
#
#	a = grid.get_node("arrivalTime0").duplicate()
#	grid.add_child(a)
#	a.show()
#
#	a = grid.get_node("departureTime0").duplicate()
#	grid.add_child(a)
#	a.show()
#
#	a = grid.get_node("haltTime0").duplicate()
#	grid.add_child(a)
#	a.show()
#
#	a = grid.get_node("stopType0").duplicate()
#	grid.add_child(a)
#	a.show()
#
#	a = grid.get_node("waitingPersons0").duplicate()
#	grid.add_child(a)
#	a.show()
#
#	a = grid.get_node("leavingPersons0").duplicate()
#	grid.add_child(a)
#	a.show()
#	pass # Replace with function body.


#func get_station_array():
#	var grid = $Scenarios/Settings/Tab/Trains/Stations/Stations
#	var children = grid.get_children()
#	var stations = {"node_name" : [], "station_name" : [], "arrival_time" : [], "departure_time" : [], "halt_time" : [], "stop_type" : [], "waiting_persons": [], "leaving_persons" : [], "passed" : []}
#	for i in range(2, entriesCount+2):
#		stations["node_name"].append(children[stationTableColumns*i+0].text)
#		stations["station_name"].append(children[stationTableColumns*i+1].text)
#		stations["arrival_time"].append([children[stationTableColumns*i+2].get_node("H").value, children[6*i+2].get_node("M").value, children[6*i+2].get_node("S").value])
#		stations["departure_time"].append([children[stationTableColumns*i+3].get_node("H").value, children[6*i+3].get_node("M").value, children[6*i+3].get_node("S").value])
#		stations["halt_time"].append(children[stationTableColumns*i+4].value)
#		stations["stop_type"].append(children[stationTableColumns*i+5].selected)
#		stations["waiting_persons"].append(children[stationTableColumns*i+6].value)
#		stations["leaving_persons"].append(children[stationTableColumns*i+7].value)
#		stations["passed"].append(false)
#	return stations

#func prepare_station_table(stations):
#
##	print(stations)
#	var grid = $Scenarios/Settings/Tab/Trains/Stations/Stations
#	while (grid.get_children().size() > 2*stationTableColumns):
#		grid.get_children()[grid.get_children().size()-1].free()
#	entriesCount = 0
#	if stations == null:
#		return
#	for i in range (0,stations["node_name"].size()):
#		_on_AddStationEntry_pressed()
#	var children = grid.get_children()
#	for i in range(2, entriesCount+2):
#		children[stationTableColumns*i+0].text = stations["node_name"][i-2]
#		children[stationTableColumns*i+1].text = stations["station_name"][i-2]
#		children[stationTableColumns*i+2].get_node("H").value = stations["arrival_time"][i-2][0]
#		children[stationTableColumns*i+2].get_node("M").value = stations["arrival_time"][i-2][1]
#		children[stationTableColumns*i+2].get_node("S").value = stations["arrival_time"][i-2][2]
#		children[stationTableColumns*i+3].get_node("H").value = stations["departure_time"][i-2][0]
#		children[stationTableColumns*i+3].get_node("M").value = stations["departure_time"][i-2][1]
#		children[stationTableColumns*i+3].get_node("S").value = stations["departure_time"][i-2][2]
#		children[stationTableColumns*i+4].value = stations["halt_time"][i-2]
#		children[stationTableColumns*i+5].selected = stations["stop_type"][i-2]
#		if stations.has("waiting_persons"):
#			children[stationTableColumns*i+6].value = stations["waiting_persons"][i-2]
#		if stations.has("leaving_persons"):
#			children[stationTableColumns*i+7].value = stations["leaving_persons"][i-2]





func _on_ResetSignals_pressed():
	for child in world.get_node("Signals").get_children():
		if child.type == SignalType.SIGNAL:
			child.reset()


func _on_ItemList2_Train_selected(index):
	current_train = $Scenarios/VBoxContainer/Settings/Tab/Trains/ItemList2.get_item_text(index)
	get_train_settings()
	$Scenarios/VBoxContainer/Settings/Tab/Trains/HBoxContainer2/LineEdit.text = current_train


func _on_NewTrain_pressed():
	var train_name = $Scenarios/VBoxContainer/Settings/Tab/Trains/HBoxContainer2/LineEdit.text
	if train_name == "": return
	$Scenarios/VBoxContainer/Settings/Tab/Trains/ItemList2.add_item(train_name)



func _on_RenameTrain_pressed():
	if current_train == "Player":
		print("You can't rename the player train!")
		return
	var old_train = current_train
	var train_name = $Scenarios/VBoxContainer/Settings/Tab/Trains/HBoxContainer2/LineEdit.text
	if train_name == "": return
	for  i in range(0, $Scenarios/VBoxContainer/Settings/Tab/Trains/ItemList2.get_item_count()):
		if $Scenarios/VBoxContainer/Settings/Tab/Trains/ItemList2.get_item_text(i) == train_name:
			print("There already exists a train whith this train name, aborting...")
			return
	get_train_settings()
	current_train = train_name
	set_train_settings()
	## Delete "Old Train"
	delete_train(old_train)
	update_train_list()




func _on_DuplicateTrain_pressed():
	if current_train == "": return
	get_train_settings()
	current_train = current_train + " (Duplicate)"
	$Scenarios/VBoxContainer/Settings/Tab/Trains/ItemList2.add_item(current_train)
	set_train_settings()



func delete_train(train):
	var scenario_data = config.get_value("Scenarios", "scenario_data", {})
	if not scenario_data.has(current_scenario): return
	if not scenario_data[current_scenario].has("Trains"): return
	if not scenario_data[current_scenario]["Trains"].has(train):
		return
	var trains = scenario_data[current_scenario]["Trains"]
	trains.erase(train)
	scenario_data[current_scenario]["Trains"] = trains
	config.set_value("Scenarios", "scenario_data", scenario_data)
	config.save(save_path)

func _on_DeleteTrain_pressed():
	if current_train == "Player":
		print ("You cant delete the player train!")
		return
	delete_train(current_train)
	print("Train deleted.")
	current_train = ""
	update_train_list()
	clear_train_settings_view()

func clear_train_settings_view(): # Resets the Train settings when adding a new npc for example.
	$Scenarios/VBoxContainer/Settings/Tab/Trains/PreferredTrain/TrainName.text = ""
	$Scenarios/VBoxContainer/Settings/Tab/Trains/Route/Route.text = ""
	$Scenarios/VBoxContainer/Settings/Tab/Trains/GridContainer/StartRail.text = ""
	$Scenarios/VBoxContainer/Settings/Tab/Trains/GridContainer/StartRailPosition.value = 0
	$Scenarios/VBoxContainer/Settings/Tab/Trains/GridContainer/Direction.selected = 0
	$Scenarios/VBoxContainer/Settings/Tab/Trains/GridContainer/DoorConfiguration.selected = 0
	$Scenarios/VBoxContainer/Settings/Tab/Trains/GridContainer/SpawnTime/H.value = -1
	$Scenarios/VBoxContainer/Settings/Tab/Trains/GridContainer/SpawnTime/M.value = 0
	$Scenarios/VBoxContainer/Settings/Tab/Trains/GridContainer/SpawnTime/S.value = 0
	$Scenarios/VBoxContainer/Settings/Tab/Trains/GridContainer/DespawnRail.text = ""

	$Scenarios/VBoxContainer/VBoxContainer/Settings/Tab/Trains/stationTable.clear_data()



#func _on_ToggleAllSavedObjects_pressed():
#	if world.editorAllObjectsUnloaded:
#		world.editorLoadAllChunks()
#	else:
#		world.editorUnloadAllChunks()
#	updateToggleAllSavedObjectsButton()
#
#
#func updateToggleAllSavedObjectsButton():
#	if world == null or world.name != "World":
#		return
#	if not world.editorAllObjectsUnloaded:
#		$"World Configuration/ToggleAllSavedObjects".text = "Unload all Objects from configuration"
#	else:
#		$"World Configuration/ToggleAllSavedObjects".text = "Load all Objects from configuration"


func _on_WorldLoading_AllChunks_pressed():
	if $"World Configuration/WorldLoading/AllChunks".pressed:
		$"World Configuration/WorldLoading/RailConfiguration".hide()
		$"World Configuration/WorldLoading/IncludeNeighbours".hide()
	else:
		$"World Configuration/WorldLoading/RailConfiguration".show()
		$"World Configuration/WorldLoading/IncludeNeighbours".show()



func _on_WorldLoading_Unload_pressed():
	if $"World Configuration/WorldLoading/AllChunks".pressed:
		world.unload_and_save_all_chunks()
		print("Unloaded all chunks.")
		return
	var chunks = world.get_chunks_between_rails(
		$"World Configuration/WorldLoading/RailConfiguration/FromRail".text,
		$"World Configuration/WorldLoading/RailConfiguration/ToRail".text,
		$"World Configuration/WorldLoading/IncludeNeighbours".pressed)
	if chunks == null:
		return
	world.unload_and_save_chunks(chunks)
	pass # Replace with function body.


func _on_WorldLoading_Load_pressed():
	if $"World Configuration/WorldLoading/AllChunks".pressed:
		world.force_load_all_chunks()
		print("Loaded all chunks.")
		return
	var chunks = world.get_chunks_between_rails(
		$"World Configuration/WorldLoading/RailConfiguration/FromRail".text,
		$"World Configuration/WorldLoading/RailConfiguration/ToRail".text,
		$"World Configuration/WorldLoading/IncludeNeighbours".pressed)
	if chunks == null:
		return
	world.load_chunks(chunks)
	print("Loaded Chunks " + str(chunks))


func _on_Chunks_Save_pressed():
	if $"World Configuration/WorldLoading/AllChunks".pressed:
		world.save_all_chunks()
		print("Saved all chunks.")
		return
	var chunks = world.get_chunks_between_rails(
		$"World Configuration/WorldLoading/RailConfiguration/FromRail".text,
		$"World Configuration/WorldLoading/RailConfiguration/ToRail".text,
		$"World Configuration/WorldLoading/IncludeNeighbours".pressed)
	if chunks == null:
		return
	world.save_chunks(chunks)


func _on_Notes_Save_pressed():
	world.save_value("notes", $"World Configuration/Notes/RichTextLabel".text)
