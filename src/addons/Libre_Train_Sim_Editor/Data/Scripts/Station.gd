@tool
class_name Station extends Node3D

const type = SignalType.STATION
@onready var world: World = find_parent("World")
var persons_node

@export var station_length: int

@export_enum("None", "Left", "Right", "Both") var platform_side: int
@export var person_system = true
@export var platform_height = 1.2
@export var platform_start = 2.5
@export var platform_end = 4.5

@export_node_path(Node3D) # Why can I not use "Rail" here ? I made it a class_name >_>
var attached_rail_path: NodePath:
	get: return attached_rail_path
	set(val): 
		attached_rail_path = val # NodePath
		attached_rail = val.get_name(val.get_name_count()-1) # Node Name

var attached_rail: String


@export var on_rail_position: int
@export var update: bool:
	get: return update
	set(val): set_to_rail(val)

@export var forward = true

var waiting_person_count = 5
var attached_persons = []

var rail
func _ready():
	if Engine.is_editor_hint():
		if get_parent().name == "Signals":
			return
		if get_parent().is_in_group("Rail"):
			attached_rail = get_parent().name
		var signals = find_parent("World").get_node("Signals")
		get_parent().remove_child(self)
		signals.add_child(self)
		set_to_rail(true)
	if not Engine.is_editor_hint():
		$MeshInstance3D.queue_free()
		set_to_rail(true)
		person_system = person_system and jSettings.get_persons() and not Root.mobile_version
		
		
func _process(delta):
	if rail == null:
		set_to_rail(true)
	
	if not Engine.editor_hint:
		if person_system:
			handle_persons()



# warning-ignore:unused_argument
func set_to_rail(newvar):
	if find_parent("World") == null:
		return
	if find_parent("World").has_node("Rails/"+attached_rail) and attached_rail != "":
		rail = get_parent().get_parent().get_node("Rails/"+attached_rail)
		rail.register_signal(self.name, on_rail_position)
		self.position = rail.get_pos_at_rail_distance(on_rail_position)
		
		
func get_scenario_data():
	return null
func set_scenario_data(d):
	return

func spawn_persons_at_beginning():
	if not person_system:
		return
	if platform_side == PlatformSide.NONE:
		return
	while(rail.visible and attached_persons.size() < waiting_person_count):
		spawn_random_person()

func set_waiting_persons(count : int):
	waiting_person_count = count
	spawn_persons_at_beginning() 
	

func handle_persons():
	if platform_side == PlatformSide.NONE:
		return
	if rail == null:
		return
	
	if rail.visible and attached_persons.size() < waiting_person_count:
		spawn_random_person()
		
		
func spawn_random_person():
	randomize()
	var person = preload("res://addons/Libre_Train_Sim_Editor/Data/Modules/Person.tscn")
	var person_vi = world.person_visual_instances[int(randi_range(0, world.person_visual_instances.size()))]
	var person_i = person.instantiate()
	person_i.add_child(person_vi.instantiate())
	person_i.attached_station = self
	person_i.transform = get_random_transform_at_platform()
	person_i.owner = world
	persons_node.add_child(person_i)
	
	attached_persons.append(person_i)
	
	
func get_random_transform_at_platform():
	if forward:
		var rand_rail_distance = int(randi_range(on_rail_position, on_rail_position+station_length))
		if platform_side == PlatformSide.LEFT:
			return Transform3D(Basis(Vector3(0,deg2rad(rail.get_deg_at_rail_distance(rand_rail_distance)), 0)),  rail.get_shifted_pos_at_rail_distance(rand_rail_distance, randf_range(-platform_start, -platform_end)) + Vector3(0, platform_height, 0))
		if platform_side == PlatformSide.RIGHT:
			return Transform3D(Basis(Vector3(0,deg2rad(rail.get_deg_at_rail_distance(rand_rail_distance)+180.0), 0)) , rail.get_shifted_pos_at_rail_distance(rand_rail_distance, randf_range(platform_start, platform_end)) + Vector3(0, platform_height, 0))
	else:
		var rand_rail_distance = int(randi_range(on_rail_position, on_rail_position-station_length))
		if platform_side == PlatformSide.LEFT:
			return Transform3D(Basis(Vector3(0,deg2rad(rail.get_deg_at_rail_distance(rand_rail_distance)+180.0), 0)), rail.get_shifted_pos_at_rail_distance(rand_rail_distance, randf_range(platform_start, platform_end)) + Vector3(0, platform_height, 0))
		if platform_side == PlatformSide.RIGHT:
			return Transform3D(Basis(Vector3(0,deg2rad(rail.get_deg_at_rail_distance(rand_rail_distance)), 0)) , rail.get_shifted_pos_at_rail_distance(rand_rail_distance, randf_range(-platform_start, -platform_end)) + Vector3(0, platform_height, 0))
		
func set_door_positions(doors, doors_wagon): ## Called by the train
	if doors.size() == 0:
		return
	for person in attached_persons:
		person.clear_destinations()
		var nearest_door_index = 0
		for i in range(doors.size()):
			if doors[i].world_pos.distance_to(person.position) <  doors[nearest_door_index].world_pos.distance_to(person.position):
				nearest_door_index = i
		person.destination_pos.append(doors[nearest_door_index].world_pos)
		person.transition_to_wagon = true
		person.assigned_door = doors[nearest_door_index]
		person.attached_wagon = doors_wagon[nearest_door_index]
		
		
func deregister_person(personToDelete):
	if attached_persons.has(personToDelete):
		attached_persons.erase(personToDelete)
		waiting_person_count -= 1

			
func register_person(person_node):
	attached_persons.append(person_node)
	person_node.get_parent().remove_child(person_node)
	person_node.owner = world
	persons_node.add_child(person_node)
	person_node.destination_pos.append(get_random_transform_at_platform().origin)
