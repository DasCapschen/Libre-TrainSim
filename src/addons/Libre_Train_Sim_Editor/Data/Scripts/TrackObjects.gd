tool
extends MultiMeshInstance

export (String) var description = ""
export (String) var attached_rail 
export (float) var on_rail_position
export (float) var length

export (String) var object_path
export var material_paths = []
export (int) var sides = 0#0: No Side, 1: Left, 2: Right 4: Both
export (float) var spawn_rate = 1
export (float) var rows
export (float) var distance_length = 10
export (float) var distance_rows
export (float) var shift
export (float) var height
export (float) var rotation_objects = 0
export (bool) var random_location
export (float) var random_location_factor = 0.3
export (bool) var random_rotation
export (bool) var random_scale 
export (float) var random_scale_factor = 0.2
export (bool) var place_last = false
export (bool) var apply_slope_rotation = false

export (int) var random_seed = 0

export (bool) var whole_rail

var material_updated = false


export (bool) var update setget _update


onready var world = find_parent("World")
var rail
var updated = false

func get_data():
	var d = {}
	d.description = description
	d.attached_rail = attached_rail
	d.on_rail_position = on_rail_position
	d.length = length
	d.object_path = object_path
	d.material_paths = material_paths.duplicate()
	d.sides = sides
	d.spawn_rate = spawn_rate
	d.rows = rows
	d.distance_length = distance_length
	d.distance_rows = distance_rows
	d.shift = shift
	d.height = height
	d.random_location = random_location
	d.random_location_factor = random_location_factor
	d.random_rotation = random_rotation
	d.random_scale = random_scale
	d.random_scale_factor = random_scale_factor
	d.whole_rail = whole_rail
#	d.mesh_set = mesh_set
#	d.multimesh = multimesh.duplicate()
	d.rotation_objects = rotation_objects
	d.place_last = place_last
	d.apply_slope_rotation = apply_slope_rotation
	d.random_seed = random_seed
	return d
	
	
func set_data(d):
	description = d.description
	attached_rail = d.attached_rail
	on_rail_position = d.on_rail_position
	length = d.length
	object_path = d.object_path
	material_paths = d.material_paths
	sides = d.sides
	spawn_rate = d.spawn_rate
	rows = d.rows
	distance_length = d.distance_length
	distance_rows = d.distance_rows
	shift = d.shift
	height = d.height
	random_location = d.random_location
	random_location_factor = d.random_location_factor
	random_rotation = d.random_rotation
	random_scale = d.random_scale
	random_scale_factor = d.random_scale_factor
	whole_rail = d.whole_rail
#	mesh_set = d.mesh_set
#	multimesh = d.multimesh
	rotation_objects = d.rotation_objects
	place_last = d.place_last
	random_seed = d.get("random_seed", 0)
	if d.has("apply_slope_rotation"):
		apply_slope_rotation = d.apply_slope_rotation

func _ready():
	world = find_parent("World")
#	attach_to_rail()
	_update(true)
	pass
		
func _process(delta):
	if world == null:
		world = find_parent("World")
		if world != null:
			print("Updating Track Object...")
			_update(true)
		else:
			print("track_object cant find World Node, retrying..")
			return
	if rail == null:
		attach_to_rail()
	if not material_updated:
		_update(true)
		material_updated = true
	if updated == false:
		_update(true)
			

func attach_to_rail():
	if world == null: 
		return
	var rail = world.get_node("Rails").get_node_or_null(attached_rail)
	if rail != null:
		if not rail.track_objects.has(self):
			rail.track_objects.append(self)#
	else:
		print("track_object " + name + " can't find rail! Deleting...")
		queue_free()

func detach_from_rail():
	var rail = world.get_node("Rails").get_node_or_null(attached_rail)
	if rail != null:
		if rail.track_objects.has(self):
			rail.track_objects.erase(self)

func _exit_tree():
	detach_from_rail()

func _update(newvar):
	updated = true
	world = find_parent("World")
	if world == null: return
	self.set_multimesh(self.multimesh.duplicate(false))
	if whole_rail:
		var rail = world.get_node("Rails").get_node(attached_rail)
		if rail == null:
			queue_free()
			return
		on_rail_position = 0
		length = rail.length
	attach_to_rail()
	## Set to rail:
	if world.has_node("Rails/"+attached_rail) and attached_rail != "":
		rail = world.get_node("Rails/"+attached_rail)
		translation = rail.get_pos_at_rail_distance(on_rail_position)
	
	
	if object_path == "" : return
	var mesh = load(object_path).duplicate(true)
	multimesh.mesh = mesh
	
	for x in range(material_paths.size()):
		if material_paths[x] != "":
			multimesh.mesh.surface_set_material(x, load(material_paths[x]))
	
	var straight_count = int(length / distance_length)
	if place_last:
		straight_count += 1

	
	self.multimesh.instance_count = 0
	multimesh.visible_instance_count = 0
	if sides == 0:
		self.multimesh.instance_count = 0
	if sides == 1 or sides == 2:
		self.multimesh.instance_count = int(straight_count * rows)
	if sides == 3: 
		self.multimesh.instance_count = int(straight_count * rows)*2
	var idx = 0
	var railpos = on_rail_position
	seed(random_seed)
	for a in range(straight_count):
		for b in range(rows):
			if sides == 1 or sides == 3: ## Left Side
				if rand_range(0,1) < spawn_rate:
					var position = rail.get_shifted_pos_at_rail_distance(railpos, -(shift+(b)*distance_rows)) - self.translation + Vector3(0,height,0)
					if random_location:
						var shift_x = rand_range(-distance_length * random_location_factor, distance_length * random_location_factor)
						var shift_z = rand_range(-distance_rows * random_location_factor, distance_rows * random_location_factor)
						position += Vector3(shift_x, 0, shift_z)
					var rot = rail.get_deg_at_rail_distance(railpos)
					if random_rotation:
						rot = rand_range(0,360)
					else:
						rot += rotation_objects
					var slope_rot = 0
					if apply_slope_rotation:
						slope_rot = rail.get_height_rot(railpos)
					var scale = Vector3(1,1,1)
					if random_scale:
						var scale_val = rand_range(1 - random_scale_factor, 1 + random_scale_factor)
						scale = Vector3(scale_val, scale_val, scale_val)
					self.multimesh.set_instance_transform(idx, Transform(Basis.rotated(Vector3(0,0,1), deg2rad(slope_rot)).rotated(Vector3(0,1,0), deg2rad(rot)).scaled(scale), position))
					idx += 1
			if sides == 2 or sides == 3: ## Right Side
				if rand_range(0,1) < spawn_rate:
					var position = rail.get_shifted_pos_at_rail_distance(railpos, (shift+(b)*distance_rows)) - self.translation + Vector3(0,height,0)
					if random_location:
						var shift_x = rand_range(-distance_length * random_location_factor, distance_length * random_location_factor)
						var shift_z = rand_range(-distance_rows * random_location_factor, distance_rows * random_location_factor)
						position += Vector3(shift_x, 0, shift_z)
					var rot = rail.get_deg_at_rail_distance(railpos)
					if random_rotation:
						rot = rand_range(0,360)
					else:
						rot += rotation_objects
					var slope_rot = 0
					if apply_slope_rotation:
						slope_rot = rail.get_height_rot(railpos)
					var scale = Vector3(1,1,1)
					if random_scale:
						var scale_val = rand_range(1 - random_scale_factor, 1 + random_scale_factor)
						scale = Vector3(scale_val, scale_val, scale_val)
					self.multimesh.set_instance_transform(idx, Transform(Basis.rotated(Vector3(0,0,1), deg2rad(slope_rot)).rotated(Vector3(0,1,0), deg2rad(rot)).scaled(scale), position))
					idx += 1
		railpos += distance_length
		self.multimesh.visible_instance_count = idx
#	mesh_set = true


func newSeed():
	randomize()
	random_seed = rand_range(-1000000,1000000)
