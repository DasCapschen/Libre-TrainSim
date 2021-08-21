tool
extends Spatial

## Documentation Notes:
# Please be aware of the parallel Mode:
# If 'parallel_rail != ""' All local train Settings apart from 'railType' and 'distance_to_parllel_rail' are deprecated. The rail gets the rest information from parallel rail.


export (String) var rail_type_path = "res://Resources/Basic/RailTypes/Default.tscn"
export (float) var length
export (float) var radius
export (float) var build_distance = 1
export (int) var visible_segments
# warning-ignore:unused_class_variable
export (bool) var update setget _update

export (bool) var manual_moving = false
var fixed_transform

var track_objects = []


var MAX_LENGTH = 1000

export (float) var start_rot
export (float) var end_rot
export (Vector3) var start_pos
export (Vector3) var end_pos

export (float) var others_distance = -4.5
export (float) var others_radius
export (float) var others_length
# warning-ignore:unused_class_variable
export (bool) var calculate setget calc_parallel_rail

export (float) var in_shift = 2.25
# warning-ignore:unused_class_variable
export (float) var in_radius = 400
export (float) var out_length
# warning-ignore:unused_class_variable
export (bool) var calculate_shift setget calc_shift

## Steep
export (float) var start_slope = 0 # Degree
export (float) var end_slope = 0 # Degree

export (float) var start_tend = 0
export (float) var tend1_pos = -1
export (float) var tend1 = 0
export (float) var tend2_pos = 0
export (float) var tend2 = 0
export (float) var end_tend
export (float) var automatic_tendency = false

export (String) var parallel_rail = ""
export (float) var distance_to_parllel_rail = 0

export (bool) var overhead_line = false
var overhead_line_height1 = 5.3
var overhead_line_height2 = 6.85
var overhead_line_thickness = 0.02
var line2height_changing_factor = 0.9
var overhead_line_built = false

var par_rail

var rail_type_node 



onready var world = find_parent("World")
onready var buildings = world.get_node("Buildings")


var attached_signals = []

# Called when the node enters the scene tree for the first time.
func _ready():
	manual_moving = false
	_update(false)
	if not Engine.is_editor_hint():
		$Beginning.queue_free()
		$Ending.queue_free()
	pass # Replace with function body.

var editor_update_timer = 0
func _process(delta):
	check_visual_instance()
	if visible and not overhead_line_built:
		update_overhead_line()
		overhead_line_built = true
	if Engine.is_editor_hint():
		editor_update_timer += delta
		if editor_update_timer < 0.25:
			return
		editor_update_timer = 0
		## Disable moving in editor, if manual Moving is false:
#		print("checking transofrmation....")
		if fixed_transform == null:
			fixed_transform = transform
		if not manual_moving:
			transform = fixed_transform
		else:
			fixed_transform = transform
		if name.match(" "):
			name = name.replace(" ", "_")
		## Move buildings to the buildings Node
		for child in get_children():
			if not child.owner == self:
				remove_child(child)
				buildings.add_child(child)
				child.owner = world

func _update(newvar):
	if ResourceLoader.exists(rail_type_path):
		rail_type_node = load(rail_type_path).instance()
	if rail_type_node == null:
		rail_type_node = preload("res://Resources/Basic/RailTypes/Default.tscn").instance()
	build_distance = rail_type_node.build_distance
	overhead_line_height1 = rail_type_node.overhead_line_height1
	overhead_line_height2 = rail_type_node.overhead_line_height2
	overhead_line_thickness = rail_type_node.overhead_line_thickness
	line2height_changing_factor = rail_type_node.line2height_changing_factor
#	update_overhead_line()
	world = find_parent("World")
	if world == null: return
	if parallel_rail == "":
		update_automatic_tendency()
	if parallel_rail != "":
		par_rail = world.get_node("Rails").get_node(parallel_rail)
		if par_rail == null:
			print("Cant find parallel rail. Updating rail canceled..")
			return

		if par_rail.radius == 0:
			radius = 0
			length = par_rail.length
		else:
			radius = par_rail.radius + distance_to_parllel_rail
			length = par_rail.length * ((radius)/(par_rail.radius))
		translation = par_rail.get_shifted_pos_at_rail_distance(0, distance_to_parllel_rail) ## Hier verstehe ich das minus nicht
		rotation_degrees.y = par_rail.rotation_degrees.y
		fixed_transform = transform
	

	if length > MAX_LENGTH:
		length = MAX_LENGTH
		print(self.name + ": The max length is " + String(MAX_LENGTH) + ". Shrinking the length to maximal length.")
	update_positions_and_rotations()
	visible_segments = length / build_distance +1

	build_rail()
	update_overhead_line()

	if Engine.is_editor_hint():
		$Ending.translation = get_local_transform_at_rail_distance(length).origin


func check_visual_instance():
	if visible:
		if get_node_or_null("MultiMeshInstance") == null:
			load_visible_instance()
	else:
		if get_node_or_null("MultiMeshInstance") != null:
			unload_visible_instance()

func get_track_object(track_object_name : String): # (Searches for the description of track objects
	for track_object in track_objects:
		if track_object.description == track_object_name:
			return track_object
	return null

func build_rail():
	if get_node_or_null("MultiMeshInstance") == null:
		return
	get_node("MultiMeshInstance").set_multimesh(get_node("MultiMeshInstance").multimesh.duplicate(false))
	var multimesh = get_node("MultiMeshInstance").multimesh
	multimesh.mesh = rail_type_node.get_child(0).mesh.duplicate(true)
	for i in range(rail_type_node.get_child(0).get_surface_material_count()):
		multimesh.mesh.surface_set_material(i, rail_type_node.get_child(0).get_surface_material(i))

	multimesh.instance_count = length / build_distance + 1
	multimesh.visible_instance_count = visible_segments
	var distance = 0
	for i in range(0, multimesh.visible_instance_count):
		multimesh.set_instance_transform(i, get_local_transform_at_rail_distance(distance))
		distance += build_distance

func get_transform_at_rail_distance(distance):
	var loc_transform = get_local_transform_at_rail_distance(distance)
	return Transform(loc_transform.basis.rotated(Vector3(0,1,0), deg2rad(rotation_degrees.y)) ,translation + loc_transform.origin.rotated(Vector3(0,1,0), deg2rad(rotation_degrees.y)))

func get_local_transform_at_rail_distance(distance):
	if parallel_rail == "":
		return Transform(Basis().rotated(Vector3(1,0,0),deg2rad(get_tend_at_rail_distance(distance))).rotated(Vector3(0,0,1), deg2rad(get_height_rot(distance))).rotated(Vector3(0,1,0), deg2rad(circle_get_deg(radius, distance))), get_local_pos_at_rail_distance(distance) )
	else:
		var par_distance = distance/length * par_rail.length
		return Transform(Basis().rotated(Vector3(1,0,0),deg2rad(par_rail.get_tend_at_rail_distance(par_distance))).rotated(Vector3(0,0,1), deg2rad(par_rail.get_height_rot(par_distance))).rotated(Vector3(0,1,0), deg2rad(par_rail.circle_get_deg(par_rail.radius, par_distance))), par_rail.get_shifted_local_pos_at_rail_distance(par_distance, distance_to_parllel_rail)+ ((par_rail.start_pos-start_pos).rotated(Vector3(0,1,0), deg2rad(-rotation_degrees.y))))#+(-translation+par_rail.translation).rotated(Vector3(0,1,0), deg2rad(rotation_degrees.y)) )

func speed_to_kmh(speed):
	return speed*3.6

# warning-ignore:unused_argument
func calc_parallel_rail(newvar):
	_update(true)
	if radius == 0:
		others_radius = 0
		others_length = length
		return
	var U = 2.0* PI * radius
	others_radius = radius + others_distance
	if U == 0:
		others_length = length
	else:
		others_length = (length / U) * (2.0 * PI * others_radius)

# warning-ignore:unused_argument
func calc_shift(newvar):
	_update(true)
	if radius == 0:
		out_length = length
		return
	var angle = rad2deg(acos((radius-in_shift)/radius))

	if String(angle) == "nan":
		out_length = length
		return
	out_length = 2.0 * PI * radius * angle / 360.0

func register_signal(name, distance):
	print("Signal " + name + " registered at rail.")
	attached_signals.append({"name": name, "distance": distance})

func get_pos_at_rail_distance(distance):
	var circle_pos = circle_get_pos(radius, distance)
	return(Vector3(circle_pos.x, get_height(distance), -circle_pos.y)).rotated(Vector3(0,1,0), deg2rad(start_rot))+start_pos

func get_local_pos_at_rail_distance(distance):
	var circle_pos = circle_get_pos(radius, distance)
	return(Vector3(circle_pos.x, get_height(distance), -circle_pos.y))

func get_deg_at_rail_distance(distance):
	return circle_get_deg(radius, distance) + start_rot

func get_local_deg_at_rail_distance(distance):
	return circle_get_deg(radius, distance)

func get_shifted_pos_at_rail_distance(distance, shift):
	return get_shifted_local_pos_at_rail_distance(distance, shift).rotated(Vector3(0,1,0),deg2rad(rotation_degrees.y)) + start_pos
#	var railpos = get_pos_at_rail_distance(distance)
#	return railpos + (Vector3(1, 0, 0).rotated(Vector3(0,1,0), deg2rad(get_deg_at_rail_distance(distance)+90))*shift)

func get_shifted_local_pos_at_rail_distance(distance, shift):
	var new_radius = radius + shift
	if radius == 0:
		new_radius = 0
	var new_distance = distance
	if radius != 0:
		new_distance = distance * ((new_radius)/(radius))
	var circle_pos = circle_get_pos(new_radius, new_distance)
	return(Vector3(circle_pos.x, get_height(distance), -circle_pos.y+shift))

func unload_visible_instance():
	print("Unloading visible Instance for rail "+name)
	visible = false
	$MultiMeshInstance.queue_free()

func load_visible_instance():
	visible = true
	if get_node_or_null("MultiMeshInstance") != null: return
	print("Loading visible Instance for rail "+name)
	var multimesh_instance = MultiMeshInstance.new()#
	multimesh_instance.multimesh = MultiMesh.new().duplicate(true)
	multimesh_instance.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh_instance.name = "MultiMeshInstance"
	add_child(multimesh_instance)
	multimesh_instance.owner = self
	_update(true)
	print("Loading of visual instance complete")

################################################### Easy Circle Functions:
func circle_get_pos(radius, distance):
	if radius == 0:
		return Vector2(distance, 0)
	## Calculate: Coordinate:
	var degree = circle_get_deg(radius, distance)
	var middle_of_circle = Vector2(0, radius)
	var a = cos(deg2rad(degree)) * radius
	var b = sin(deg2rad(degree)) * radius
	return middle_of_circle + Vector2(b, -a)  ## See HowACircleIsCalculated.pdf in github repository


func circle_get_deg(radius, distance):
	if radius == 0:
		return 0

	# Calculate needed degree:
	var extend = radius * 2.0 * PI
	return float(distance / extend * 360)

#### Height Functions:
func get_height(distance):
	if par_rail != null:
		var new_radius = radius - distance_to_parllel_rail
		if radius == 0:
			new_radius = 0
		var new_distance = distance
		if radius != 0:
			new_distance = distance * ((new_radius)/(radius))
		return par_rail.get_height(new_distance)
	var start_gradient = rad2deg(atan(start_slope/100))
	var end_gradient = rad2deg(atan(end_slope/100))

	var basic_height = float(tan(deg2rad(start_gradient)) * distance)
	if end_gradient - start_gradient == 0:
		return basic_height
	var height_radius = (360*length)/(2*PI*(end_gradient - start_gradient))
	return circle_get_pos(height_radius, distance).y + basic_height

func get_height_rot(distance): ## Get Slope
	if par_rail != null:
		var new_radius = radius - distance_to_parllel_rail
		if radius == 0:
			new_radius = 0
		var new_distance = distance
		if radius != 0:
			new_distance = distance * ((new_radius)/(radius))
		return par_rail.get_height_rot(new_distance)
	var start_gradient = rad2deg(atan(start_slope/100))
	var end_gradient = rad2deg(atan(end_slope/100))

	var basic_rot = start_gradient
	if end_gradient - start_gradient == 0:
		return basic_rot
	var height_radius = (360*length)/(2*PI*(end_gradient - start_gradient))
	return circle_get_deg(height_radius, distance) + basic_rot


func get_tend_at_rail_distance(distance):
	if par_rail != null:
		var new_radius = radius - distance_to_parllel_rail
		if radius == 0:
			new_radius = 0
		var new_distance = distance
		if radius != 0:
			new_distance = distance * ((new_radius)/(radius))
		return par_rail.get_tend_at_rail_distance(new_distance)
	if distance >= tend1_pos and distance < tend2_pos:
		return -(tend1 + (tend2-tend1) * (distance - tend1_pos)/(tend2_pos - tend1_pos))
	if distance <= tend1_pos:
		return -(start_tend + (tend1-start_tend) * (distance)/(tend1_pos))
	if tend2_pos > 0 and distance >= tend2_pos:
		return -(tend2 + (end_tend-tend2) * (distance -tend2_pos)/(length-tend2_pos))
	return -(start_tend + (end_tend-start_tend) * (distance/length))
	return 0

func get_tendSlopeData():
	var d = {}
	var s = self
	d.start_slope = s.start_slope
	d.end_slope = s.end_slope
	d.start_tend = s.start_tend
	d.end_tend = s.end_tend
	d.tend1_pos = s.tend1_pos
	d.tend1 = s.tend1
	d.tend2_pos = s.tend2_pos
	d.tend2 = s.tend2
	d.automatic_tendency = s.automatic_tendency
	return d

func set_tendSlopeData(data):
	var d = self
	var s = data
	d.start_slope = s.start_slope
	d.end_slope = s.end_slope
	d.start_tend = s.start_tend
	d.end_tend = s.end_tend
	d.tend1_pos = s.tend1_pos
	d.tend1 = s.tend1
	d.tend2_pos = s.tend2_pos
	d.tend2 = s.tend2
	d.automatic_tendency = s.automatic_tendency

var automatic_point_distance = 50
func update_automatic_tendency():
	if automatic_tendency and radius != 0 and length > 3*automatic_point_distance:
		tend1_pos = automatic_point_distance
		tend2_pos = length -automatic_point_distance
		var tendency = 300/radius * 5
		tend1 = tendency
		tend2 = tendency
	elif automatic_tendency and radius == 0:
		tend1 = 0
		tend2 = 0





###############################################################################
## Overhad Line
var vertices
var indices
func update_overhead_line():
	if get_node_or_null("OverheadLine") != null:
		$OverheadLine.free()
	
	if not overhead_line: 
		return
		
	var overhead_line_mesh_instance = MeshInstance.new()
	overhead_line_mesh_instance.name = "OverheadLine"
	self.add_child(overhead_line_mesh_instance)
	overhead_line_mesh_instance.owner = self
	
	vertices = PoolVector3Array()
	indices = PoolIntArray()

	## Get Pole Points:
	var pole_positions = []
	pole_positions.append(0)
	
	for track_object in track_objects:
		if track_object == null:
			continue
		print(track_object.description)
		if track_object.description.begins_with("Pole"):
			var pos = 0
			if track_object.on_rail_position == 0:
				pos += track_object.distance_length
			while pos <= track_object.length:
				pole_positions.append(pos + track_object.on_rail_position)
				pos += track_object.distance_length
			if not track_object.place_last and pole_positions.size() > 1:
				pole_positions.remove(pole_positions.size()-1)
			## Maybe here comes a break in. (If we only want to search for one trackobkject which begins with "pole"
	pole_positions.append(length)
	pole_positions = jEssentials.remove_duplicates(pole_positions)
	for i in range (pole_positions.size()-2):
		build_overhead_line_segment(pole_positions[i], pole_positions[i+1])
		
	if pole_positions[pole_positions.size()-2] != length:
		build_overhead_line_segment(pole_positions[pole_positions.size()-2], length)
		
		
	
	var mesh = ArrayMesh.new()

	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = indices

	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh.surface_set_material(0, preload("res://Resources/Basic/Materials/Black_Plastic.tres"))
	$OverheadLine.mesh = mesh

func build_overhead_line_segment(start, end):
	var start_pos = get_local_pos_at_rail_distance(start)+Vector3(0,overhead_line_height1,0)
	var end_pos = get_local_pos_at_rail_distance(end)+Vector3(0,overhead_line_height1,0)
	var direct_vector = (end_pos-start_pos).normalized()
	var direct_distance = start_pos.distance_to(end_pos)
	
	create_3D_line(get_local_pos_at_rail_distance(start)+Vector3(0,overhead_line_height1,0), get_local_pos_at_rail_distance(end)+Vector3(0,overhead_line_height1,0), overhead_line_thickness)
	
	var segments = int(direct_distance/10)
	if segments == 0:
		segments = 1
	var segment_distance = direct_distance/segments
	var current_pos1 = start_pos
	var current_pos2 = start_pos + direct_vector*segment_distance
	for i in range(segments):
		create_3D_line(current_pos1+Vector3(0,overhead_line_height2-overhead_line_height1-sin(i*segment_distance/direct_distance*PI)*line2height_changing_factor,0), current_pos2+Vector3(0,overhead_line_height2-overhead_line_height1-sin((i+1)*segment_distance/direct_distance*PI)*line2height_changing_factor,0), overhead_line_thickness)

		var line_height2changing_at_half = sin((i+1)*segment_distance/direct_distance*PI)*line2height_changing_factor - (sin((i+1)*segment_distance/direct_distance*PI)*line2height_changing_factor - sin(i*segment_distance/direct_distance*PI)*line2height_changing_factor)/2.0
		create_3D_line_up(current_pos1+direct_vector*segment_distance/2, current_pos1+direct_vector*segment_distance/2+Vector3(0,overhead_line_height2-overhead_line_height1-line_height2changing_at_half,0), overhead_line_thickness)
		current_pos1+=direct_vector*segment_distance
		current_pos2+=direct_vector*segment_distance
	return {"vertices" : vertices, "indices" : indices}
	
	
	

func create_3D_line(start, end, thickness):
	var x = vertices.size()
	vertices.push_back(start + Vector3(0,thickness,0))
	vertices.push_back(start + Vector3(0,0,-thickness))
	vertices.push_back(start + Vector3(0,-thickness,0))
	vertices.push_back(start + Vector3(0,0,thickness))
	
	vertices.push_back(end + Vector3(0,thickness,0))
	vertices.push_back(end + Vector3(0,0,-thickness))
	vertices.push_back(end + Vector3(0,-thickness,0))
	vertices.push_back(end + Vector3(0,0,thickness))
	
	var indices_array = PoolIntArray([0+x, 2+x, 4+x,  2+x, 4+x, 6+x,  1+x, 5+x, 7+x,  1+x, 7+x, 3+x])

	indices.append_array(indices_array)
	
func create_3D_line_up(start, end, thickness):
	var x = vertices.size()
	vertices.push_back(start + Vector3(thickness,0,0))
	vertices.push_back(start + Vector3(0,0,-thickness))
	vertices.push_back(start + Vector3(-thickness,0,0))
	vertices.push_back(start + Vector3(0,0,thickness))
	
	vertices.push_back(end + Vector3(thickness,0,0))
	vertices.push_back(end + Vector3(0,0,-thickness))
	vertices.push_back(end + Vector3(-thickness,0,0))
	vertices.push_back(end + Vector3(0,0,thickness))
	
	var indices_array = PoolIntArray([0+x, 2+x, 4+x,  2+x, 4+x, 6+x,  1+x, 5+x, 7+x,  1+x, 7+x, 3+x])

	indices.append_array(indices_array)

###############################################################################
func update_positions_and_rotations():
	start_pos = self.get_translation()
	start_rot = self.rotation_degrees.y
	end_rot = get_deg_at_rail_distance(length)
	end_pos = get_pos_at_rail_distance(length)

export var is_switch_part = ["", ""]
# 0: is rail at beginning part of switch? 1: is the rail at end part of switch if not 
# It is saved the name of the other rail which is part of switch
func update_is_switch_part():
	is_switch_part = ["", ""]
	var found_rails_at_begin = []
	var found_rails_at_end = []
	for rail in world.get_node("Rails").get_children():
		if rail == self:
			continue
		# Check for beginning
		if start_pos.distance_to(rail.start_pos) < 0.1 and abs(Math.norm_deg(start_rot) - Math.norm_deg(rail.start_rot)) < 1:
			found_rails_at_begin.append(rail.name)
		elif start_pos.distance_to(rail.end_pos) < 0.1 and abs(Math.norm_deg(start_rot) - Math.norm_deg(rail.end_rot+180)) < 1:
			found_rails_at_begin.append(rail.name)
		#check for ending
		if end_pos.distance_to(rail.start_pos) < 0.1 and abs((Math.norm_deg(end_rot) - Math.norm_deg(rail.start_rot+180))) < 1:
			found_rails_at_end.append(rail.name)
		elif end_pos.distance_to(rail.end_pos) < 0.1 and abs((Math.norm_deg(end_rot) - Math.norm_deg(rail.end_rot))) < 1:
			found_rails_at_end.append(rail.name)
			
	if found_rails_at_begin.size() > 0:
		is_switch_part[0] = found_rails_at_begin[0]
		pass
	
	if found_rails_at_end.size() > 0:
		is_switch_part[1] = found_rails_at_end[0]
		pass


var _connected_rails_at_beginning = [] # Array of rail nodes
var _connected_rails_at_ending = [] # Array of rail nodes
# The code of update_connections and update_is_switch_part can't be summarized, because 
# we are searching for different rails in these functions. (Rotation of searched 
# rails differs by 180 degrees)

# This function should be called before get_connected_rails_at_beginning() 
# or get_connected_rails_at_ending once.
func update_connections():
	print("HUHU")
	_connected_rails_at_beginning = []
	_connected_rails_at_ending = []
	for rail in world.get_node("Rails").get_children():
		if rail == self:
			continue
		# Check for beginning
		if start_pos.distance_to(rail.start_pos) < 0.1 and abs(Math.norm_deg(start_rot) - Math.norm_deg(rail.start_rot+180)) < 1:
			_connected_rails_at_beginning.append(rail)
		elif start_pos.distance_to(rail.end_pos) < 0.1 and abs(Math.norm_deg(start_rot) - Math.norm_deg(rail.end_rot)) < 1:
			_connected_rails_at_beginning.append(rail)
		#check for ending
		if end_pos.distance_to(rail.start_pos) < 0.1 and abs((Math.norm_deg(end_rot) - Math.norm_deg(rail.start_rot))) < 1:
			_connected_rails_at_ending.append(rail)
		elif end_pos.distance_to(rail.end_pos) < 0.1 and abs((Math.norm_deg(end_rot) - Math.norm_deg(rail.end_rot+180))) < 1:
			_connected_rails_at_ending.append(rail)

# Returns array of rail nodes
func get_connected_rails_at_beginning():
	return _connected_rails_at_beginning

# Returns array of rail nodes
func get_connected_rails_at_ending():
	return _connected_rails_at_ending

