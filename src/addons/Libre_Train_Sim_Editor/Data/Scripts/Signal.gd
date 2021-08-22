tool
extends Spatial
const type = SignalType.SIGNAL # Never change this type!!
onready var world = find_parent("World")

# blinking if State == Green AND speed > 0
# orange and red signals never blink!
export(int, "Off", "Red", "Green", "Orange") var status = SignalState.RED

var signal_after = "" # SignalName of the following signal. Set by the route manager from the players train. Just works for the players route. Should only be used for visuals!!
var signal_after_node # Reference to the signal after it. Set by the route manager from the players train. Just works for the players route. Should only be used for visuals!!

export var set_pass_at_h = -1 # If these 3 variables represent a real time (24h format), the signal will be turned green at this specified time.
export var set_pass_at_m = 0
export var set_pass_at_s = 0

export var speed = -1 # SpeedLimit, which will be applied to the train. If -1: Speed Limit won't be changed by overdriving.
var warn_speed = -1 # Displays the speed of the following speedlimit. Just used for the player train. It doesn't affect any train..

export var block_signal = false


export var visual_instance_path = ""

export (String) var attached_rail # Internal. Never change this via script.
var attached_rail_node
export var forward = true # Internal. Never change this via script.
export (int) var on_rail_position # Internal. Never change this via script.

export (bool) var update setget set_to_rail # Just uesd for the editor. If it will be pressed, then the function set_get rail will be


signal red
signal green
signal orange
signal off
signal warn_speed_changed(new_speed)
signal speed_changed(new_speed)


var timer

func update_visual_instance():
	update()
	if attached_rail_node == null:
		attached_rail_node = find_parent("World").get_node("Rails" + "/" + attached_rail)
		if attached_rail_node == null:
			return
			
	visible = attached_rail_node.visible
	if not attached_rail_node.visible:
		if get_node_or_null("VisualInstance") != null:
			$VisualInstance.queue_free()
		return

	if get_node_or_null("VisualInstance") == null:
		create_visual_instance()


func create_visual_instance():
	print("creating visual instance")
	var visual_instance_resource = null
	if visual_instance_path != "":
		visual_instance_resource = load(visual_instance_path)
	if visual_instance_resource == null:
		visual_instance_resource = load("res://Resources/Basic/Signals/Default.tscn")
	var visual_instance = visual_instance_resource.instance()
	add_child(visual_instance)
	visual_instance.name = "VisualInstance"
	visual_instance.owner = self
	connect_visual_instance()
	
func connect_visual_instance():
	# get visual instance
	var visual_instance = get_node_or_null("VisualInstance")
	if visual_instance == null:
		return

	# connect signals to visual instance
	self.connect("red", visual_instance, "red")
	self.connect("orange", visual_instance, "orange")
	self.connect("green", visual_instance, "green")
	self.connect("off", visual_instance, "off")
	self.connect("speed_changed", visual_instance, "update_speed")
	self.connect("warn_speed_changed", visual_instance, "update_warn_speed")

	# signal current state to visual instance
	match status:
		SignalState.RED:
			emit_signal("red")
		SignalState.ORANGE:
			emit_signal("orange")
		SignalState.GREEN:
			emit_signal("green")
		SignalState.OFF:
			emit_signal("off")
	emit_signal("speed_changed", speed)
	emit_signal("warn_speed_changed", warn_speed)


func update():
	if Engine.is_editor_hint() and block_signal:
		set_state(SignalState.GREEN)
	
	if world == null:
		world = find_parent("World")
	
	if signal_after_node == null and signal_after != "":
		signal_after_node = world.get_node("Signals/"+String(signal_after))
	
	if not Engine.is_editor_hint() and world.time != null:
		if world.time[0] >= set_pass_at_h and world.time[1] >= set_pass_at_m and world.time[2] >= set_pass_at_s:
			set_state(SignalState.GREEN)
	
	# check next signal if this signal is not red.
	# is next signal red? If yes, go Orange, else stay green
	if status != SignalState.RED and signal_after_node != null:
		match signal_after_node.status:
			SignalState.RED:
				set_state(SignalState.ORANGE)
			_: # else...
				set_state(SignalState.GREEN)
	


func set_state(new_state):
	if new_state == status:
		return
	status = new_state
	match new_state:
		SignalState.RED:
			emit_signal("red")
		SignalState.ORANGE:
			emit_signal("orange")
		SignalState.GREEN:
			emit_signal("green")
		SignalState.OFF:
			emit_signal("off")

func set_speed(new_speed):
	speed = new_speed
	emit_signal("speed_changed", new_speed)

func set_warn_speed(new_speed):
	warn_speed = new_speed
	emit_signal("warn_speed_changed", new_speed)

func _ready():
	timer = Timer.new()
	timer.connect("timeout", self, "update_visual_instance")
	self.add_child(timer)
	timer.start()
	
	if get_node_or_null("VisualInstance") != null:
		connect_visual_instance()
	
	# Set Signal while adding to the Signals node
	if Engine.is_editor_hint() and not get_parent().name == "Signals":
		if get_parent().is_in_group("Rail"):
			attached_rail = get_parent().name
		var signals = find_parent("World").get_node("Signals")
		get_parent().remove_child(self)
		signals.add_child(self)
		update()
		
	if block_signal:
		set_state(SignalState.GREEN)
	
	set_to_rail(true)
	update()
	


func set_to_rail(newvar):
	var world = find_parent("World")
	if world == null:
		print("Signal CANT FIND WORLD NODE!")
		return
	if world.has_node("Rails/"+attached_rail) and attached_rail != "":
		var rail = get_parent().get_parent().get_node("Rails/"+attached_rail)
		rail.register_signal(self.name, on_rail_position)
		self.translation = rail.get_pos_at_rail_distance(on_rail_position)
		self.rotation_degrees.y = rail.get_deg_at_rail_distance(on_rail_position)
		if not forward:
			self.rotation_degrees.y += 180

func give_signal_free():
	if block_signal:
		set_state(SignalState.GREEN)

func get_scenario_data():
	var d = {}
	d.status = status
	d.set_pass_at_h = set_pass_at_h
	d.set_pass_at_m = set_pass_at_m
	d.set_pass_at_s = set_pass_at_s
	d.speed = speed
	d.block_signal = block_signal
	return d

func set_scenario_data(d):
	set_state(d.status)
	set_pass_at_h = d.set_pass_at_h
	set_pass_at_m = d.set_pass_at_m
	set_pass_at_s = d.set_pass_at_s
	set_speed(d.speed)
	block_signal = d.get("block_signal", false)


func reset():
	set_state(SignalState.RED)
	set_pass_at_h = 25
	set_pass_at_m = 0
	set_pass_at_s = 0
	set_speed(-1)
	block_signal = false
