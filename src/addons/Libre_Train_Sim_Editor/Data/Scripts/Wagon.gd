extends Spatial


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
export (float) var length = 17.5

export (bool) var cabin_mode = false

var baked_route
var baked_route_direction
var route_index = 0
var forward
var current_rail 
var distance_on_rail = 0
var distance_on_route = 0
var speed = 0

var left_doors = []
var right_doors = []

var seats = [] # In here the Seats Refernces are safed
var seats_occupancy = [] # In here the Persons are safed, they are currently sitting on the seats. Index equal to index of seats

var passenger_path_nodes = []

var distance_to_player = -1

export var is_pantograph_enabled = false


var player
var world

var attached_persons = []

var initial_set = false
# Called when the node enters the scene tree for the first time.
func _ready():
	if cabin_mode:
		length = 4
		return
	register_doors()
	register_passenger_path_nodes()
	register_seats()
	
	var persons_node = Spatial.new()
	persons_node.name = "Persons"
	add_child(persons_node)
	persons_node.owner = self
	
	initialize_outside_announcement_player()
	pass # Replace with function body.

var initial_switch_check = false
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	
	if player == null or player.despawning: 
		queue_free()
		return
	
	if not initial_switch_check:
		update_switch_on_next_change()
		initial_switch_check = true
		
	speed = player.speed
	
	if cabin_mode:
		drive(delta)
		return
	
	$MeshInstance.show()
	if get_parent().name != "Players": return
	if distance_to_player == -1:
		distance_to_player = abs(player.distance_on_rail - distance_on_rail)
	visible = player.wagons_visible
	if not initial_set or not visible:
		$MeshInstance.hide()
	if speed != 0 or not initial_set: 
		drive(delta)
		initial_set = true
	check_doors()
	
	if is_pantograph_enabled:
		check_pantograph()
	
	if not visible: return
	if forward:
		self.transform = current_rail.get_transform_at_rail_distance(distance_on_rail)
	else:
		self.transform = current_rail.get_transform_at_rail_distance(distance_on_rail)
		rotate_object_local(Vector3(0,1,0), deg2rad(180))
	
	if has_node("InsideLight"):
		$InsideLight.visible = player.inside_light
	
	



func drive(delta):
	if current_rail  == player.current_rail:
		## It is IMPORTANT that the `distance > length` and `distance < 0` are SEPARATE!
		if player.forward:
			distance_on_rail = player.distance_on_rail - distance_to_player # possibly < 0 !
			distance_on_route = player.distance_on_route - distance_to_player
			if distance_on_rail > current_rail.length:
				change_to_next_rail()
		else:
			distance_on_rail = player.distance_on_rail + distance_to_player # possibly > current_rail.length !
			distance_on_route = player.distance_on_route + distance_to_player
			if distance_on_rail < 0:
				change_to_next_rail()
	else: 
		## Real Driving - Only used, if wagon isn't at the same rail as his player.
		var driven_distance = speed * delta
		if player.reverser == ReverserState.REVERSE:
			driven_distance = -driven_distance
		distance_on_route += driven_distance

		if not forward:
			driven_distance = -driven_distance
		distance_on_rail += driven_distance

		if distance_on_rail > current_rail.length or distance_on_rail < 0:
			change_to_next_rail()


# TODO: this is almost 100% duplicate code also in Player.gd
#       can we have a single method that both of them use?
func change_to_next_rail():
	if forward and (player.reverser == ReverserState.FORWARD):
		distance_on_rail -= current_rail.length
	if not forward and (player.reverser == ReverserState.REVERSE):
		distance_on_rail -= current_rail.length

	if player.reverser == ReverserState.REVERSE:
		route_index -= 1
	else:
		route_index += 1

	if baked_route.size() == route_index:
		print(name + ": Route no more rail found, despawning me...")
		queue_free()
		return

	current_rail =  world.get_node("Rails").get_node(baked_route[route_index])
	forward = baked_route_direction[route_index]

	update_switch_on_next_change()

	if not forward and (player.reverser == ReverserState.FORWARD):
		distance_on_rail += current_rail.length
	if forward and (player.reverser == ReverserState.REVERSE):
		distance_on_rail += current_rail.length

var last_door_status = DoorState.CLOSED
func check_doors():
	if (player.door_status & DoorState.RIGHT) and not (last_door_status & DoorState.RIGHT):
		$DoorRight.play("open")
	if (last_door_status & DoorState.RIGHT) and player.door_status == DoorState.CLOSING:
		$DoorRight.play_backwards("open")
	if (player.door_status & DoorState.LEFT) and not (last_door_status & DoorState.LEFT):
		$DoorLeft.play("open")
	if (last_door_status & DoorState.LEFT) and player.door_status == DoorState.CLOSING:
		$DoorLeft.play_backwards("open")
		
	last_door_status = player.door_status

var last_pantograph = false
var last_pantograph_up = false
func check_pantograph():
	if not self.has_node("Pantograph"): return
	if not last_pantograph_up and player.pantograph_up:
		print("Started Pantograph Animation")
		$Pantograph/AnimationPlayer.play("Up")
	if last_pantograph and not player.pantograph:
		$Pantograph/AnimationPlayer.play_backwards("Up")
	last_pantograph = player.pantograph
	last_pantograph_up = player.pantograph_up


## This function is very very basic.. It only checks, if the "end" of the current rail, or the "beginning" of the next rail is a switch. Otherwise it sets nextSwitchRail to null..
#var nextSwitchRail = null
#var nextSwitchOnBeginning = false
#func findNextSwitch():
#	if forward and current_rail.is_switch_part[1] != "":
#		nextSwitchRail = current_rail
#		nextSwitchOnBeginning = false
#		return
#	elif not forward and current_rail.is_switch_part[0] != "":
#		nextSwitchRail = current_rail
#		nextSwitchOnBeginning = true
#		return
#
#	if baked_route.size() > route_index+1:
#		var next_rail = baked_route[route_index+1]
#		var next_forward = baked_route_direction[route_index+1]
#		if next_forward and next_rail.is_switch_part[0] != "":
#			nextSwitchRail = next_rail
#			nextSwitchOnBeginning = true
#			return
#		elif not next_forward and next_rail.is_switch_part[1] != "":
#			nextSwitchRail = next_rail
#			nextSwitchOnBeginning = true
#			return
#
#	nextSwitchRail = null
	


func register_doors():
	for child in get_children():
		if child.is_in_group("PassengerDoor"):
			if child.translation[2] > 0:
				child.translation += Vector3(0,0,0.5)
				right_doors.append(child)
			else:
				child.translation -= Vector3(0,0,0.5)
				left_doors.append(child)

func register_person(person, door):
	var seat_index = get_random_free_seat_index()
	if seat_index == -1:
		person.queue_free()
		return
	attached_persons.append(person)
	person.get_parent().remove_child(person)
	person.owner = self
	$Persons.add_child(person)
	person.translation = door.translation
	
	var passenger_route_path = get_path_from_to(door, seats[seat_index]) 
	if passenger_route_path == null:
		printerr("Some seats of "+ name + " are not reachable from every door!!")
		return
#	print(passenger_route_path)
	person.destination_pos = passenger_route_path
	person.is_destination_seat = true
	person.attached_seat = seats[seat_index]
	seats_occupancy[seat_index] = person
	
	

func get_random_free_seat_index():
	if attached_persons.size()+1 > seats.size():
		return -1
	while (true):
		var rand_index = int(rand_range(0, seats.size()))
		if seats_occupancy[rand_index] == null:
			return rand_index
			
			
func get_path_from_to(start, destination):
	var passenger_route_path = [] ## Array of Vector3
	var real_start_node = start
#	print(start.get_groups())
	if start.is_in_group("PassengerDoor") or start.is_in_group("PassengerSeat"):
		 # find the connected passengerNode
		for passenger_path_node in passenger_path_nodes:
			for connection in passenger_path_node.connections:
#				print(connection + "  " + start.name)
				if connection == start.name:
					passenger_route_path.append(passenger_path_node.translation)
#					print("Equals!")
					real_start_node = passenger_path_node
#					print(real_start_node.name)
	
	if not real_start_node.is_in_group("PassengerPathNode"):
#		printerr("At " + name + " " + start.name + " is not connected to a passenger_path_node!")
		return null
	
	var rest_of_passenger_route_path = get_path_from_to_helper(real_start_node, destination, [])
	if rest_of_passenger_route_path == null:
		return null
	for route_path_position in rest_of_passenger_route_path:
		passenger_route_path.append(route_path_position)
	return passenger_route_path

func get_path_from_to_helper(start, destination, visited_nodes): ## Recursion, Simple Pathfinding, Start  has to be a PassengerPathNode.
#	print("Recursion: " + start.name + " " + destination.name + " " + String(visited_nodes))
	for connection in start.connections:
		var connection_n = get_node(connection)
		if connection_n == destination:
			return [connection_n.translation]
		if connection_n.is_in_group("PassengerPathNode"):
			if visited_nodes.has(connection_n):
				continue
			visited_nodes.append(connection_n)
			var passenger_route_path = get_path_from_to_helper(connection_n, destination, visited_nodes)
			if  passenger_route_path != null:
				passenger_route_path.push_front(connection_n.translation)
				return passenger_route_path
	return null

	
func register_passenger_path_nodes():
	for child in get_children():
		if child.is_in_group("PassengerPathNode"):
			passenger_path_nodes.append(child)

func register_seats():
	for child in get_children():
		if child.is_in_group("PassengerSeat"):
			seats.append(child)
			seats_occupancy.append(null)

var leaving_passenger_nodes = []
## Called by the train when arriving
## Randomly picks some to the waggon attached persons, picks randomly a door
## on the given side, sends the routeInformation for that to the persons.
func send_persons_to_door(door_direction, proportion : float = 0.5): 
	leaving_passenger_nodes.clear()
	 #0: No platform, 1: at left side, 2: at right side, 3: at both sides
	var possible_doors = []
	if door_direction == 1 or door_direction == 3: # Left
		for door in left_doors:
			possible_doors.append(door)
	if door_direction == 2 or door_direction == 3: # Right
		for door in right_doors:
			possible_doors.append(door)
		
		
	if possible_doors.empty():
		print(name + ": No Doors found for door_direction: " + String(door_direction) )
		return
		
	randomize()
	for person_node in $Persons.get_children():
		if rand_range(0, 1) < proportion:
			leaving_passenger_nodes.append(person_node)
			var random_door = possible_doors[int(rand_range(0, possible_doors.size()))]
			
			var seat_index = -1
			for i in range(seats_occupancy.size()):
				if seats_occupancy[i] == person_node:
					seat_index = i
					break
			if seat_index == -1:
				print(name + ": Error: Seat from person" + person_node.name+  " not found!")
				return
			
			var passenger_route_path = get_path_from_to(seats[seat_index], random_door)
			if passenger_route_path == null:
				printerr("Some doors are not reachable from every door! Check your Path configuration")
				return
			
			# Update position of door. (The Persons should stick inside the train while waiting ;)
			if passenger_route_path.back().z < 0:
				passenger_route_path[passenger_route_path.size()-1].z += 1.3
			else:
				passenger_route_path[passenger_route_path.size()-1].z -= 1.3

			person_node.destination_pos = passenger_route_path # Here maybe .append could be better
			person_node.attached_station = player.current_station_node
			person_node.transition_to_station = true
			person_node.assigned_door = random_door
			person_node.attached_seat = null
			seats_occupancy[seat_index] = null
			# Send Person to door
			pass
	pass

func deregister_person(person_node):
	if leaving_passenger_nodes.has(person_node):
		leaving_passenger_nodes.erase(person_node)

var outside_announcement_player
func initialize_outside_announcement_player():
	var audio_stream_player = AudioStreamPlayer3D.new()
	
	audio_stream_player.unit_size = 10
	audio_stream_player.bus = "Game"
	outside_announcement_player = audio_stream_player
	
	add_child(audio_stream_player)

func play_outside_announcement(sound_path : String):
	if sound_path == "":
		return
	if cabin_mode:
		return
	var stream = load(sound_path)
	if stream == null:
		return
	stream.loop = false
	if stream != null:
		outside_announcement_player.stream = stream
		outside_announcement_player.play()
	
var switch_on_next_change = false
func update_switch_on_next_change(): ## Exact function also in player.gd. But these are needed: When the player drives over many small rails that could be inaccurate..
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
