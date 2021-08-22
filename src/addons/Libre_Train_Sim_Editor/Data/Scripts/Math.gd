tool
extends Node

# Get Next Position from a point on a circle after a specific Distance. 
#Used for building rails, and driving on rail.
## Circle:
func get_next_pos(radius, pos, world_rot, distance):#  Vector3 position, float world_rot, float distance):
	# Straigt
	if radius == 0:
		return pos + Vector3(cos(deg2rad(world_rot))*distance, 0, -sin(deg2rad(world_rot))*distance) ##!!!!
	# Curve
	var extend = radius * 2.0 * PI
	var degree = distance / extend * 360    + world_rot
	return degree_to_coordinate(radius, pos, degree, world_rot)

# Calculate aut from radius of circle, the rotation of the object, and a specific Distande the next rotation of the object.
#Used for building rails, and driving on rail.
func get_next_deg(radius, world_rot, distance):
	# Straight:
	if radius == 0: 
		return world_rot
	# Curve:
	var extend = radius * 2.0 * PI
	return distance / extend * 360    + world_rot


# Calculates from the radius of the circle, the position and rotation from the object the middlepoint of the circle.
# Whith that the Function returns in the end the position after for example 2 degrees on "driving" on the rail.
# only used sed by get_next_pos()
func degree_to_coordinate(radius, pos, degree, world_rot):
	degree = float(degree)
	var mittelpunkt = pos - Vector3(sin(deg2rad(world_rot)) * radius,0,cos(deg2rad(world_rot)) * radius)
	var a = cos(deg2rad(degree)) * radius
	var b = sin(deg2rad(degree)) * radius
	return mittelpunkt + Vector3(b, 0, a)

## converts m/s to km/h
func speed_to_kmh(speed):
	return speed*3.6
	
func kmh_to_speed(speed):
	return speed/3.6
	
func norm_deg(degree):
	while degree > 180.0:
		degree -= 360.0
	while degree < 180.0:
		degree += 360.0
	return degree
	

#func sort_signals(signal_table, forward = true):
#	var signal_t = [signal_table.values(), signal_table.keys()]
#	var export_t = [] 
#	for a in range(0, signal_t[0].size()):
#		var minimum = 0
#		for i in range(0, signal_t[0].size()):
#			if signal_t[0][i] < signal_t[0][minimum]:
#				minimum = i
#		export_t.append(signal_t[1][minimum])
#		signal_t[0].remove(minimum)
#		signal_t[1].remove(minimum)
#	if forward:
#		return export_t
#	else:
#		export_t.invert()
#		return export_t

func sort_signals(signal_table, forward = true): # Gets A Dict like {"name": [], "position" : []}, returns the array of the signal	
	var signal_t = signal_table.duplicate(true)
#	if not signal_t.has("position"):
#		signal_t["position"] = []
#		for signal_s in signal_t["name"]:
#			var signal_n = Root.world.get_node("Signals").get_node(signal_s)
#			if signal_n != null:
#				signal_t["position"].append(signal_n.on_rail_position)
#			else:
#				signal_t["position"] = -1
#				print("Math.sort_signals: Some Signal not found!")

	var export_t = [] 
	for a in range(0, signal_t["name"].size()):
		var minimum = 0
		for i in range(0, signal_t["name"].size()):
			if signal_t["position"][i] < signal_t["position"][minimum]:
				minimum = i
		export_t.append(signal_t["name"][minimum])
		signal_t["name"].remove(minimum)
		signal_t["position"].remove(minimum)
	if forward:
		return export_t
	else:
		export_t.invert()
		return export_t

		
func time_to_string(time):
	var hour = String(time[0])
	var minute = String(time[1])
	var second = String(time[2])
	if hour.length() == 1:
		hour = "0" + hour
	if minute.length() == 1:
		minute = "0" + minute
	if second.length() == 1:
		second = "0" + second
	return (hour + ":" + minute +":" + second)
	
func distance_to_string(distance):
	if distance > 10000:
		return String(int(distance/1000)) + " km"
	if distance > 1000:
		return String(int(distance/100)/10.0) + " km"
	if distance > 100:
		return String((int(distance/100))*100) + " m"
	else:
		return String((int(distance-10)/10)*10) + " m"
		
