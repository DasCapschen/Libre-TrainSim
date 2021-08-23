@tool
class_name World extends Node3D

@onready var time_hour: int = 0
@onready var time_minute: int = 0
@onready var time_second: int = 0
@onready var time_milliseconds: int = 0
@onready var time: Array[int] = [time_hour,time_minute,time_second]

var default_persons_at_station: int = 20

var global_dict: Dictionary = {} ## Used, if some nodes need to communicate globally. Modders could use it. Please make sure, that you pick an unique key_name

################################################################################
var current_scenario: String = ""

@export var file_name: String = "Name Me!"
@onready var track_name: String = file_name.rsplit("/")[0]

var chunk_size: int = 1000

var all_chunks = [] # All Chunks of the world
var ist_chunks = [] # All Current loaded Chunks
var soll_chunks = [] # All Chunks, which should be loaded immediately

var active_chunk = string_to_chunk("0,0") # Current Chunk of the player (ingame)


var author = ""
var picture_path = "res://screenshot.png"
var description = ""

var pending_trains = {"TrainName" : [], "SpawnTime" : []}

var player: Node

var train_files = {"Array" : []}

var person_visual_instances_paths = [
	"res://Resources/Basic/Persons/Man_Young_01.tscn",
	"res://Resources/Basic/Persons/Man_Middleaged_01.tscn",
	"res://Resources/Basic/Persons/Woman_Young_01.tscn",
	"res://Resources/Basic/Persons/Woman_Middleaged_01.tscn",
	"res://Resources/Basic/Persons/Woman_Old_01.tscn"
]
var person_visual_instances = []


func _ready():
	jEssentials.call_delayed(2.0, self, "get_actual_loaded_chunks")
	if track_name.is_empty():
		track_name = file_name
	print("track_name: " +track_name + " " + file_name)
	$jSaveModule.set_save_path(str("res://Worlds/" + track_name + "/" + track_name + ".save"))
	
	if Engine.editor_hint:
#		update_all_rails_overhead_line_setting(false)
		return

	if not Engine.editor_hint:
		Root.world = self
		Root.fix_frame_drop()
		Root.check_and_load_translations_for_track(track_name)
		Root.crawl_directory("res://Trains",train_files,"tscn")
		train_files = train_files["Array"]
		current_scenario = Root.current_scenario
		set_scenario_to_world()
		
		
		## Create Persons-Node:
		var persons_node = Node3D.new()
		persons_node.name = "Persons"
		persons_node.owner = self
		add_child(persons_node)
		
		for person_visual_instances_path in person_visual_instances_paths:
			person_visual_instances.append(load(person_visual_instances_path))
			
		for signal_n in $Signals.get_children():
			if signal_n.type == SignalType.STATION:
				signal_n.persons_node = persons_node
				signal_n.spawn_persons_at_beginning()
		
		all_chunks = get_all_chunks()
		
		ist_chunks = []
		configure_soll_chunks(active_chunk)

		apply_soll_chunks()

		player = $Players/Player
		last_chunk = pos_to_chunk(get_original_pos_big_chunk(player.position))
		
		apply_user_settings()


	pass
	
func save_value(key : String, value):
	return $jSaveModule.save_value(key, value)
	
func get_value(key : String,  default_value = null):
	return $jSaveModule.get_value(key,  default_value)

func apply_user_settings():
	if Root.mobile_version:
		$DirectionalLight.shadow_enabled = false
		player.get_node("Camera").far = 400
		get_viewport().set_msaa(0)
		$WorldEnvironment.environment.fog_enabled = false
		return
	if get_node("DirectionalLight") != null:
		$DirectionalLight.shadow_enabled = jSettings.get_shadows()
	player.get_node("Camera").far = jSettings.get_view_distance()
	get_viewport().set_msaa(jSettings.get_anti_aliasing())
	$WorldEnvironment.environment.fog_enabled = jSettings.get_fog()
	
func _process(delta):
	if not Engine.editor_hint:
		update_time(delta)
		check_train_spawn(delta)
		handle_chunk()
		check_big_chunk()
	else:
		var buildings: Node3D = get_node("Buildings")
		for child in get_children():
			if child.is_class("MeshInstance3D"):
				remove_child(child)
				buildings.add_child(child)
				child.owner = self



func update_time(delta):
	time_milliseconds += delta
	if time_milliseconds > 1:
		time_milliseconds -= 1
		time[2] += 1
	else:
		return
	if time[2] == 60:
		time[2] = 0
		time[1] += 1
	if time[1] == 60:
		time[1] = 0
		time[0] += 1
	if time[0] == 24:
		time[0] = 0




func pos_to_chunk(position):
	return Vector3(int(position.x / chunk_size), 0, int(position.z / chunk_size))
	
func compare_chunks(pos1, pos2):
	return (pos1.x == pos2.x && pos1.z == pos2.z)
	
func chunk_to_string(position : Vector3):
	return (str(position.x) + "," + str(position.z))
	
func string_to_chunk(string : String):
	var array: Array = string.split(",")
	return Vector3(array[0].to_int(), 0 , array[1].to_int())

func get_chunk_neighbours(chunk):
	return [
		Vector3(chunk.x+1, 0, chunk.z+1), 
		Vector3(chunk.x+1, 0, chunk.z), 
		Vector3(chunk.x+1, 0, chunk.z-1), 
		Vector3(chunk.x, 0, chunk.z+1), 
		Vector3(chunk.x, 0, chunk.z-1), 
		Vector3(chunk.x-1, 0, chunk.z+1), 
		Vector3(chunk.x-1, 0, chunk.z), 
		Vector3(chunk.x-1, 0, chunk.z-1)
	]

func save_chunk(position):
	
	var chunk: Dictionary = {} #"position" : position, "Rails" : {}, "Buildings" : {}, "Flora" : {}}
	chunk.position = position
	chunk["Rails"] = {}
	var rails: Array = get_node("Rails").get_children()
	chunk["Rails"] = []
	for rail in rails:
		if compare_chunks(pos_to_chunk(rail.position), position):
			rail.update_is_switch_part()
			chunk["Rails"].append(rail.name)

	
	chunk["Buildings"] = {}
	var buildings: Array = get_node("Buildings").get_children()
	for building in buildings:
		if compare_chunks(pos_to_chunk(building.position), position):
			var surface_arr = []
			for i in range(building.get_surface_material_count()):
				surface_arr.append(building.get_surface_material(i))
			chunk["Buildings"][building.name] = {name = building.name, transform = building.transform, mesh_path = building.mesh.resource_path, surface_arr = surface_arr}

	chunk["Flora"] = {}
	var flora: Array = get_node("Flora").get_children()
	for forest in flora:
		if compare_chunks(pos_to_chunk(forest.position), position):
			chunk["Flora"][forest.name] = {name = forest.name, transform = forest.transform, x = forest.x, z = forest.z, spacing = forest.spacing, random_location = forest.random_location, random_location_factor = forest.random_location_factor, random_rotation = forest.random_rotation, random_scale = forest.random_scale, random_scale_factor = forest.random_scale_factor, multimesh = forest.multimesh, material_override = forest.material_override}
	

	
	chunk["TrackObjects"] = {}
	var track_objects = get_node("TrackObjects").get_children()
	for track_object in track_objects:

		if compare_chunks(pos_to_chunk(track_object.position), position):
			chunk["TrackObjects"][track_object.name] = {name = track_object.name, transform = track_object.transform, data = track_object.get_data()}
	$jSaveModule.save_value(chunk_to_string(position), null)
	$jSaveModule.save_value(chunk_to_string(position), chunk)
	print("Saved Chunk " + chunk_to_string(position))
	


func unload_chunk(position : Vector3):
	
	var chunk = $jSaveModule.get_value(chunk_to_string(position), null)
	if chunk == null:
		return
	var rails: Array = get_node("Rails").get_children()
	for rail in rails:
		if compare_chunks(pos_to_chunk(rail.position), position):
			if chunk["Rails"].has(rail.name):
				rail.unload_visible_instance()
	
	var buildings: Array = get_node("Buildings").get_children()
	for building in buildings:
		if compare_chunks(pos_to_chunk(building.position), position):
			if chunk["Buildings"].has(building.name):
				building.queue_free()
			else:
				print("Object not saved! I wont unload this for you...")
	
	var flora: Array = get_node("Flora").get_children()
	for forest in flora:
		if compare_chunks(pos_to_chunk(forest.position), position):
			if chunk["Flora"].has(forest.name):
				forest.queue_free()
			else:
				print("Object not saved! I wont unload this for you...")
	
	var track_objects: Array = get_node("TrackObjects").get_children()
	for node in track_objects:
		if compare_chunks(pos_to_chunk(node.position), position):
			if chunk["TrackObjects"].has(node.name):
				node.queue_free()
			else:
				print("Object not saved! I wont unload this for you...")
	
	print("Unloaded Chunk " + chunk_to_string(position))
	
	
	
func load_chunk(position : Vector3):
	print("Loading Chunk " + chunk_to_string(position))
	
	var chunk = $jSaveModule.get_value(chunk_to_string(position), {"empty" : true})

	if chunk.has("empty"):
		print("Chunk "+chunk_to_string(position) + " not found in Save File. Chunk not loaded!")
		return
	## rails:
	var rails: Array = chunk["Rails"]
	for rail in rails:
		print("Loading rail: " + rail)
		## IF YOU GET HERE AN ERROR: Do Save and Create Chunks, and check, if only rails are assigned to the "Rails" Node
		if $Rails.get_node(rail) != null: 
			$Rails.get_node(rail).load_visible_instance()
		else:
			printerr("WARNING: rail "+ rail+ " not found in scene tree, but was saved in chunk. That shouldn't be.")
		

	##buildings:
	var buildings_node: Node3D = get_node("Buildings")
	var buildings: Array = chunk["Buildings"]
	for building in buildings:
		if buildings_node.find_node(building) == null:
			var mesh_instance = MeshInstance3D.new()
			mesh_instance.name = buildings[building].name
			mesh_instance.set_mesh(load(buildings[building].mesh_path))
			mesh_instance.transform = buildings[building].transform
			mesh_instance.position = get_new_pos_big_chunk(mesh_instance.position)
			var surface_arr = buildings[building].surface_arr
			if surface_arr == null:
				surface_arr = []
			print(surface_arr)
			for i in range (surface_arr.size()):
				mesh_instance.set_surface_material(i, surface_arr[i])
			buildings_node.add_child(mesh_instance)
			mesh_instance.set_owner(self)
		else:
			print("Node " + building + " already loaded!") 
	
	
	##flora:
	var flora_node: Node3D = get_node("Flora")
	var flora: Array = chunk["Flora"]
	var forest_node = preload("res://addons/Libre_Train_Sim_Editor/Data/Modules/Forest.tscn")
	for forest in flora:#
		if flora_node.find_node(forest) == null:
			var forest_instance = forest_node.instantiate()
			forest_instance.name = flora[forest].name
			forest_instance.multimesh = flora[forest].multimesh
			forest_instance.random_location = flora[forest].random_location
			forest_instance.random_location_factor = flora[forest].random_location_factor
			forest_instance.random_rotation = flora[forest].random_rotation
			forest_instance.random_scale = flora[forest].random_scale
			forest_instance.random_scale_factor = flora[forest].random_scale_factor
			forest_instance.spacing = flora[forest].spacing
			forest_instance.transform = flora[forest].transform
			forest_instance.position = get_new_pos_big_chunk(forest_instance.position)
			forest_instance.x = flora[forest].x
			forest_instance.z = flora[forest].z
			forest_instance.material_override = flora[forest].material_override
			flora_node.add_child(forest_instance)
			forest_instance.set_owner(self)
			get_node("Flora/"+forest)._update(true)
		else:
			print("Node " + forest + " already loaded!") 
			
			
	##track_objects:
	var parent_node: Node3D = get_node("TrackObjects")
	var node_array: Array = chunk["TrackObjects"]
	var node_prefab = preload("res://addons/Libre_Train_Sim_Editor/Data/Modules/TrackObjects.tscn")
	for node in node_array:
		if parent_node.find_node(node) == null:
			var node_instance = node_prefab.instantiate()
			node_instance.name = node_array[node].name
			node_instance.set_data(node_array[node].data)
			node_instance.transform = node_array[node].transform
			node_instance.position = get_new_pos_big_chunk(node_instance.position)
			parent_node.add_child(node_instance)
			node_instance.set_owner(self)
		else:
			print("Node " + node + " already loaded!") 
	
	var unloaded_chunks: Array = get_value("unloaded_chunks", [])
	unloaded_chunks.erase(chunk_to_string(position))
	save_value("unloaded_chunks", unloaded_chunks)
	
	print("Chunk " + chunk_to_string(position) + " loaded")
	pass

func get_all_chunks(): # Returns Array of Strings
	all_chunks = []
	var rail_node: Node3D = get_node("Rails")
	if rail_node == null:
		printerr("Rail Node not found. World is corrupt!")
		return
	for rail in rail_node.get_children():
		var rail_chunk = pos_to_chunk(rail.position)
		all_chunks = add_single_to_array(all_chunks, chunk_to_string(rail_chunk))

		for chunk in get_chunk_neighbours(rail_chunk):
			all_chunks = add_single_to_array(all_chunks, chunk_to_string(chunk))
	return all_chunks

func add_single_to_array(array, value):
	if not array.has(value):
		array.append(value)
	return array
	

func configure_soll_chunks(chunk):
	soll_chunks = []
	soll_chunks.append(chunk_to_string(chunk))
	for a in get_chunk_neighbours(chunk):
		soll_chunks.append(chunk_to_string(a))
	pass

func apply_soll_chunks():
	print("applying soll chunks...")
	print("ist_chunks: " + str(ist_chunks))
	print("soll_chunks: " + str(soll_chunks))
	var old_ist_chunks = ist_chunks.duplicate()
	for a in old_ist_chunks:
		if not soll_chunks.has(a):
			unload_chunk(string_to_chunk(a))
			ist_chunks.remove(ist_chunks.find(a))
	print("ist_chunks: " + str(ist_chunks))
	for a in soll_chunks:
		if not ist_chunks.has(a):
			load_chunk(string_to_chunk(a))
			ist_chunks.append(a)
			
var last_chunk: Vector3
func handle_chunk():
	var player = $Players/Player
	var current_chunk = pos_to_chunk(get_original_pos_big_chunk(player.position))
	if not compare_chunks(current_chunk, last_chunk):
		active_chunk = current_chunk
		configure_soll_chunks(current_chunk)
		apply_soll_chunks()
	last_chunk = pos_to_chunk(get_original_pos_big_chunk(player.position))







## BIG CHUNK_SYSTEM: KEEPS THE WORLD under 5000

var current_big_chunk = Vector2(0,0)

func pos_to_big_chunk(pos):
	return Vector2(int(pos.x/5000), int(pos.z/5000))+current_big_chunk
	
func get_new_pos_big_chunk(pos):
	return Vector3(pos.x-current_big_chunk.x*5000.0, pos.y, pos.z-current_big_chunk.y*5000.0)
	
func get_original_pos_big_chunk(pos):
	return Vector3(pos.x+current_big_chunk.x*5000.0, pos.y, pos.z+current_big_chunk.y*5000.0)
		
func check_big_chunk():
	var player: Node = $Players/Player
	var new_chunk = pos_to_big_chunk(player.position)

	if (new_chunk != current_big_chunk):
		var deltaChunk = current_big_chunk - new_chunk
		current_big_chunk = new_chunk
		print (new_chunk)
		print(current_big_chunk)
		print("Changed to new big Chunk. Changing Objects position..")
		update_world_trasform_big_chunk(deltaChunk)
		


func update_world_trasform_big_chunk(delta_chunk):
	var delta_translation = Vector3(delta_chunk.x*5000, 0, delta_chunk.y*5000)
	print(delta_translation)
	for player in $Players.get_children():
		player.position += delta_translation
	for rail in $Rails.get_children():
		rail.position += delta_translation
		rail._update(true)
	for signal_n in $Signals.get_children():
		signal_n.position += delta_translation
	for building in $Buildings.get_children():
		building.position += delta_translation
	for forest in $Flora.get_children():
		forest.position += delta_translation
	for to in $TrackObjects.get_children():
		to.position += delta_translation
	for person in $Persons.get_children():
		person.position += delta_translation
	
		


func apply_scenario_to_signals(signals):
	## Apply Scenario Data
	for signal_n in  $Signals.get_children():
		if signals.has(signal_n.name):
			signal_n.set_scenario_data(signals[signal_n.name])
			
func get_signal_data_for_scenario():
	var signals: Dictionary = {}
	for s in $Signals.get_children():
		signals[s.name] = s.get_scenario_data()
	return signals
	
func set_scenario_to_world():
	var scenario_save_path: String = "res://Worlds/" + track_name + "/" + track_name + "-scenarios.cfg"
	var scenario_config = ConfigFile.new()
	var load_response = scenario_config.load(scenario_save_path)
	var scenario_data = scenario_config.get_value("Scenarios", "scenario_data", {})
	var scenario = scenario_data[current_scenario]
	# set world Time:
	time_hour = scenario["TimeH"]
	time_minute = scenario["TimeM"]
	time_second = scenario["TimeS"]
	time = [time_hour,time_minute,time_second]
	
	apply_scenario_to_signals(scenario["Signals"])
	
	## SPAWN TRAINS:
	for train in scenario["Trains"].keys():
		spawn_train(train)
	
	jEssentials.call_delayed(1, $Players/Player, "show_textbox_message", [TranslationServer.translate(scenario["Description"])])
#	$Players/Player.show_textbox_message(TranslationServer.translate(scenario["Description"]))



func spawn_train(train_name):
	if $Players.has_node(train_name):
		print("Train is already loaded! - Abortet loading...")
		return
	var scenario_save_path = "res://Worlds/" + track_name + "/" + track_name + "-scenarios.cfg"
	var scenario_config = ConfigFile.new()
	var load_response = scenario_config.load(scenario_save_path)
	var scenario_data = scenario_config.get_value("Scenarios", "scenario_data", {})
	var scenario = scenario_data[current_scenario]
	var spawn_time = scenario["Trains"][train_name]["SpawnTime"]
	if scenario["Trains"][train_name]["SpawnTime"][0] != -1 and not (spawn_time[0] == time[0] and spawn_time[1] == time[1] and spawn_time[2] == time[2]):
		print("Spawn Time of "+train_name + " not reached, doing spawn later...")
		pending_trains["TrainName"].append(train_name)
		pending_trains["SpawnTime"].append(scenario["Trains"][train_name]["SpawnTime"].duplicate())
		return
	# Find preferred train:
	var player: Node
	var preferred_train = scenario["Trains"][train_name].get("PreferredTrain", "")
	if (preferred_train == "" and not train_name == "Player") or train_name == "Player":
		if not train_name == "Player":
			print("no preferred train specified. Loading player train...")
		player = load(Root.current_train).instantiate()
	else:
		for train_file in train_files:
			print(train_file)
			print(preferred_train)
			if train_file.find(preferred_train) != -1:
				player = load(train_file).instantiate()
		if player == null:
			print("Preferred train not found. Loading player train...")
			player = load(Root.current_train).instantiate()
		
	player.name = train_name
	$Players.add_child(player)
	player.owner = self
	if player.length  +25 > scenario["TrainLength"]:
		player.length = scenario["TrainLength"] -25
	player.route = scenario["Trains"][train_name]["Route"]
	player.start_rail = scenario["Trains"][train_name]["StartRail"]
	player.forward = bool(scenario["Trains"][train_name]["Direction"])
	player.start_position = scenario["Trains"][train_name]["StartRailPosition"]
	player.stations = scenario["Trains"][train_name]["Stations"]
	player.stations["passed"] = []
	for i in range(player.stations["node_name"].size()):
		player.stations["passed"].append(false)
	player.despawn_rail = scenario["Trains"][train_name]["DespawnRail"]
	player.ai = train_name != "Player"
	player.initial_speed = Math.kmh_to_speed(scenario["Trains"][train_name].get("InitialSpeed", 0))
	if scenario["Trains"][train_name].get("InitialSpeedLimit", -1) != -1:
		player.current_speed_limit = scenario["Trains"][train_name].get("InitialSpeedLimit", -1)
	
		
	
	var door_status = scenario["Trains"][train_name]["DoorConfiguration"]
	match door_status:
		0:
			pass
		1: 
			player.door_status = DoorState.LEFT
		2:
			player.door_status = DoorState.RIGHT
		3:
			player.door_status = DoorState.BOTH
	
	player.custom_ready()
	

var checkTrainSpawnTimer = 0
func check_train_spawn(delta):
	checkTrainSpawnTimer += delta
	if checkTrainSpawnTimer < 0.5: return
	checkTrainSpawnTimer = 0
	for i in range (0, pending_trains["TrainName"].size()):
		var spawn_time =  pending_trains["SpawnTime"][i]
		if spawn_time[0] == time[0] and spawn_time[1] == time[1] and spawn_time[2] == time[2]:
			pending_trains["SpawnTime"][i] = [-1, 0, 0]
			spawn_train(pending_trains["TrainName"][i])
			

func update_rail_connections():
	for rail_node in $Rails.get_children():
		rail_node.update_positions_and_rotations()
	for rail_node in $Rails.get_children():
		rail_node.update_connections()

# pathfinding from a start rail to an end rail. returns an array of rail nodes
func get_path_from_to(start_rail : Node, forward : bool, destination_rail : Node):
	if Engine.editor_hint:
		update_rail_connections()
	else:
		print_debug("Be sure you called update_rail_connections once before..")
	var route = _get_path_from_to_helper(start_rail, forward, [], destination_rail)
	print_debug(route)
	return route

# Recursive Function
func _get_path_from_to_helper(start_rail : Node, forward : bool, already_visited_rails : Array, destination_rail : Node):
	already_visited_rails.append(start_rail)
	print(already_visited_rails)
	if start_rail == destination_rail:
		return already_visited_rails
	else:
		var possbile_rails = []
		if forward:
			possbile_rails = start_rail.get_connected_rails_at_ending()
		else:
			possbile_rails = start_rail.get_connected_rails_at_beginning()
		for rail_node in possbile_rails:
			print("Possible rails" + str(possbile_rails))
			if not already_visited_rails.has(rail_node):
				if rail_node.get_connected_rails_at_ending().has(start_rail):
					forward = false
				if rail_node.get_connected_rails_at_beginning().has(start_rail):
					forward = true
				var outcome = _get_path_from_to_helper(rail_node, forward, already_visited_rails, destination_rail)
				if outcome != []:
					return outcome
#				return _get_path_from_to_helper(rail_node, forward, already_visited_rails, destination_rail)
	return []

# Iterates through all currently loaded/visible rails, buildings, flora. Returns an array of chunks in strings
func get_actual_loaded_chunks():
	var actual_loaded_chunks = []
	for rail_node in $Rails.get_children():
		if rail_node.visible and not actual_loaded_chunks.has(chunk_to_string(pos_to_chunk(rail_node.position))): 
			actual_loaded_chunks.append(chunk_to_string(pos_to_chunk(rail_node.position)))
	for building_node in $Buildings.get_children():
		if building_node.visible and not actual_loaded_chunks.has(chunk_to_string(pos_to_chunk(building_node.position))): 
			actual_loaded_chunks.append(chunk_to_string(pos_to_chunk(building_node.position)))
	for flora_node in $Flora.get_children():
		if flora_node.visible and not actual_loaded_chunks.has(chunk_to_string(pos_to_chunk(flora_node.position))): 
			actual_loaded_chunks.append(chunk_to_string(pos_to_chunk(flora_node.position)))
	
	return actual_loaded_chunks

# loads all chunks (for Editor Use) (even if some chunks are loaded, and others not.)
func force_load_all_chunks():
	soll_chunks = get_all_chunks()
	ist_chunks = []
	apply_soll_chunks()

# Accepts an array of chunks noted as strings
func save_chunks(chunks_to_save : Array):
	var current_unloaded_chunks = get_value("unloaded_chunks", []) # String
	for chunk_to_save in chunks_to_save:
		if current_unloaded_chunks.has(chunk_to_save): # If chunk is loaded but unloaded at the same time
			print("Chunk conflict: " + chunk_to_save + " is unloaded, but there are existing some currently loaded objects in this chunk! Trying to fix that...")
			load_chunk(string_to_chunk(chunk_to_save))
			save_chunk(string_to_chunk(chunk_to_save))
			continue
		save_chunk(string_to_chunk(chunk_to_save))
	print("Saved chunks sucessfully.")
	
# Accepts an array of chunks noted as strings
func unload_and_save_chunks(chunks_to_unload : Array):
	save_chunks(chunks_to_unload)
	
	var current_unloaded_chunks = get_value("unloaded_chunks", []) # String
	for chunk_to_unload in chunks_to_unload:
		unload_chunk(string_to_chunk(chunk_to_unload))
		current_unloaded_chunks.append(chunk_to_unload)
	current_unloaded_chunks = jEssentials.remove_duplicates(current_unloaded_chunks)
	save_value("unloaded_chunks", current_unloaded_chunks)
	print("Unloaded chunks sucessfully.")

# Accepts an array of chunks noted as strings
func load_chunks(chunks_to_load : Array):
	for chunk in chunks_to_load:
		load_chunk(string_to_chunk(chunk))

func unload_and_save_all_chunks():
	unload_and_save_chunks(get_all_chunks())

func save_all_chunks():
	save_chunks(get_all_chunks())

# Returns all chunks in form of strings.
func get_chunks_between_rails(start_rail : String, destination_rail : String, include_neighbour_chunks : bool = false):
	var start_rail_node = $Rails.get_node_or_null(start_rail)
	var destination_rail_node = $Rails.get_node_or_null(destination_rail)
	if start_rail_node == null or destination_rail_node == null:
		print("Some rails not found. Are the Names correct? Aborting...")
		return
	var rail_nodes = get_path_from_to(start_rail_node, true, destination_rail_node)
	if rail_nodes.empty():
		rail_nodes = get_path_from_to(start_rail_node, false, destination_rail_node)
	if rail_nodes.empty():
		print("Path between these rails could not be found. Are these rails reachable? Check the connections! Aborting...")
	
	var chunks = []
	for rail_node in rail_nodes:
		chunks.append(chunk_to_string(pos_to_chunk(rail_node.position)))
	chunks = jEssentials.remove_duplicates(chunks)
	if not include_neighbour_chunks:
		return chunks
	
	var chunks_with_neighbours = chunks.duplicate()
	for chunk in chunks:
		var chunks_neighbours = get_chunk_neighbours(string_to_chunk(chunk))
		for chunk_neighbour in chunks_neighbours:
			chunks_with_neighbours.append(chunk_to_string(chunk_neighbour))
	chunks_with_neighbours = jEssentials.remove_duplicates(chunks_with_neighbours)
	return chunks_with_neighbours
	
func update_all_rails_overhead_line_setting(overhead_line : bool): # Not called automaticly. From any instance or button, but very helpful.
	for rail in $Rails.get_children():
		rail.overhead_line = overhead_line
		rail.update_overhead_line()
	
