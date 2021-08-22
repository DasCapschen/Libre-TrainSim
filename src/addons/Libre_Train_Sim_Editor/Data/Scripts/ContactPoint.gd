tool
extends Spatial

const type = SignalType.CONTACT_POINT

export var affected_signal = ""
export var by_specific_train = ""
export var new_status = 1
export var new_speed = -1
export var affect_time = 0

export (String) var attached_rail
export (int) var on_rail_position
export (bool) var update setget set_to_rail
export var forward = true


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
		$Timer.wait_time = affect_time
		$MeshInstance.queue_free()
		set_to_rail(true)



# warning-ignore:unused_argument
func set_to_rail(newvar):
	if not find_parent("World"):
		print("SpeedSign can't find World Parent!'")
		return
	
	if find_parent("World").has_node("Rails/"+attached_rail) and attached_rail != "":
		var rail = find_parent("World").get_node("Rails/"+attached_rail)
		rail.register_signal(self.name, on_rail_position)
		self.translation = rail.get_pos_at_rail_distance(on_rail_position)
		self.rotation_degrees.y = rail.get_deg_at_rail_distance(on_rail_position)
		if not forward:
			self.rotation_degrees.y += 180


func set_scenario_data(d):
	var a = self
	var b = d
	a.affected_signal = b.affected_signal
	a.by_specific_train = b.by_specific_train
	a.new_status = b.new_status
	a.affect_time = b.affect_time
	a.new_speed = b.get("new_speed", -1)
	
func get_scenario_data():
	var a = {}
	var b = self
	a.affected_signal = b.affected_signal
	a.by_specific_train = b.by_specific_train
	a.new_status = b.new_status
	a.affect_time = b.affect_time
	a.new_speed = b.new_speed
	return a
	
func reset():
	affected_signal = ""
	by_specific_train = ""
	new_status = 1
	affect_time = 0

func activate_contact_point(train_name):
	if affected_signal == "": return
	if by_specific_train != "" and train_name != by_specific_train: return
	$Timer.start()

func _on_Timer_timeout():
	var signal_n = get_parent().get_node(affected_signal)
	if signal_n == null: 
		print("Contact Point "+ name + " could not find signal "+affected_signal+" aborting...")
		return
	if signal_n.type != "Signal":
		print("Contact Point "+ name + ": Specified signal point is no Signal. Aborting...")
		return
	signal_n.set_state(new_status)
	signal_n.set_speed(new_speed)
