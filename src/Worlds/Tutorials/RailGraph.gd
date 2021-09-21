extends Spatial

# Nodes == Children
# Edges are stored on each Node

# Node Structure:
# { rails_after: [Edge], rails_before: [Edge], attached_signals: Dict{name -> distance_on_rail} }

# Edge Structure:
# { name: str, flip_forward: bool, length: float }

# TODO: switches
#       need to sync "active_rail_before" and "active_rail_after"
#       between connected nodes!!!

func get_next_rail(current_rail, current_forward):
	var rail_node = get_node(current_rail)
	
	var next
	if current_forward:
		next = rail_node.rails_after[rail_node.active_rail_after]
	else:
		next = rail_node.rails_before[rail_node.active_rail_before]
	
	var next_forward = current_forward
	if next["flip_forward"]:
		next_forward = !current_forward
	
	return {
		"name": next["name"],
		"forward": next_forward
	}


# get path from rail to other rail, starting in forward direction
# from and to are included in the path!
# if no path can be found, returns []
# if from == to, returns [from]
# return an array of dictionaries: [{name, forward}]
func get_any_path_from_to(from, to, forward) -> Array:
	if from == to:
		return [{"name": from, "forward": forward}]
	
	# TODO: rewrite using distance to get the shortest path!!
	# TODO: traffic rules (prefer right track over left track) ??
	
	# initialize algo
	var visited_rails = {from: forward}  # name -> forward
	var previous = {from: null}          # name -> rail
	#var distance = {from: 0}             # name -> distance
	var rails_to_visit_stack = []
	var found = false
	
	if forward:
		rails_to_visit_stack.append_array(get_node(from).rails_after)
	else:
		rails_to_visit_stack.append_array(get_node(from).rails_before)
	
	var rail = {"name": from, "flip_forward": false, "length": get_node(from).length}
	
	# search rails until we found `to`
	while(not rails_to_visit_stack.empty()):
		var next = rails_to_visit_stack.pop_front()
		previous[next.name] = rail
		#distance[next.name] = distance[rail.name] + next.length
		rail = next
		
		if rail.flip_forward:
			forward = !forward
		
		if visited_rails.has(rail.name):
			printerr("Cycle detected! Cannot find path from ", from, " to ", to, "!")
			return []
		else:
			visited_rails[rail.name] = forward
		
		if rail.name == to:
			found = true
			break
		elif forward:
			rails_to_visit_stack.append_array(get_node(rail.name).rails_after)
		else:
			rails_to_visit_stack.append_array(get_node(rail.name).rails_before)
	
	if found == false:
		printerr("Cannot find path from ", from, " to ", to, "!")
		return []
	
	# build path backwards
	var path = []
	while(rail != null):
		path.append({"name": rail.name, "forward": visited_rails[rail.name]})
		rail = previous[rail.name]
	
	path.invert()  # invert() reverses the order of the array in-place
	return path


# determines which rails are connected, and how they are connected
func build_rail_graph():
	for rail in get_children():
		rail.rails_before = []
		rail.rails_after = []
		
		for other in get_children():
			if rail.name == other.name:
				continue
			
			# check rails before
			if rail.startpos.distance_to(other.startpos) < 0.2 and Math.angle_distance_deg(rail.startrot-180.0, other.startrot) < 1:
				rail.rails_before.append({ "name": other.name, "flip_forward": true, "length": other.length })
			elif rail.startpos.distance_to(other.endpos) < 0.2 and Math.angle_distance_deg(rail.startrot-180.0, other.endrot+180.0) < 1:
				rail.rails_before.append({ "name": other.name, "flip_forward": false, "length": other.length })
			
			# check rails after
			elif rail.endpos.distance_to(other.startpos) < 0.2 and Math.angle_distance_deg(rail.endrot, other.startrot) < 1:
				rail.rails_after.append({ "name": other.name, "flip_forward": false, "length": other.length })
			elif rail.endpos.distance_to(other.endpos) < 0.2 and Math.angle_distance_deg(rail.endrot, other.endrot+180.0) < 1:
				rail.rails_after.append({ "name": other.name, "flip_forward": true, "length": other.length })
