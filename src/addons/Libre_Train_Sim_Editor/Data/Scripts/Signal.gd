@tool
class_name SignalLogic extends Node3D

const type = SignalType.SIGNAL # Never change this type!!
@onready var world: World = get_tree().current_scene

# blinking if State == Green AND speed > 0
# orange and red signals never blink!
@export_enum(SignalState) var status = SignalState.RED

var signal_after: String = "" # SignalName of the following signal. Set by the route manager from the players train. Just works for the players route. Should only be used for visuals!!
var signal_after_node: Node # Reference to the signal after it. Set by the route manager from the players train. Just works for the players route. Should only be used for visuals!!

@export var set_pass_at_h: int = -1 # If these 3 variables represent a real time (24h format), the signal will be turned green at this specified time.
@export var set_pass_at_m: int = 0
@export var set_pass_at_s: int = 0

@export var speed: float = -1 # SpeedLimit, which will be applied to the train. If -1: Speed Limit won't be changed by overdriving.
var warn_speed: float = -1 # Displays the speed of the following speedlimit. Just used for the player train. It doesn't affect any train..

@export var block_signal: bool = false


@export_node_path var visual_instance_path: NodePath = NodePath("VisualInstance")

@export_node_path(Node3D)
var attached_rail_path: NodePath:
	get: return attached_rail_path
	set(val):
		attached_rail_path = val
		attached_rail = val.get_name(val.get_name_count()-1)
		attached_rail_node = self.get_node(val)

var attached_rail: String # Internal. Never change this via script.
var attached_rail_node: Rail

@export var forward: bool = true # Internal. Never change this via script.
@export var on_rail_position: int # Internal. Never change this via script.

@export var do_update: bool:
	set(val): set_to_rail(val) # Just uesd for the editor. If it will be pressed, then the function set_get rail will be


signal red
signal green
signal orange
signal off
signal warn_speed_changed(new_speed)
signal speed_changed(new_speed)


var timer: Timer
func update_visual_instance():
	update()
	if attached_rail_node == null:
		attached_rail_node = find_parent("World").get_node("Rails" + "/" + attached_rail) as Rail
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
	var visual_instance = null
	if not visual_instance_path.is_empty():
		visual_instance = load(visual_instance_path).instantiate()
	if visual_instance == null:
		visual_instance = load("res://Resources/Basic/Signals/Default.tscn").instantiate()
	add_child(visual_instance)
	visual_instance.name = "VisualInstance"
	visual_instance.owner = self
	connect_visual_instance()
	
func connect_visual_instance():
	# get visual instance
	var visual_instance: Node3D = get_node_or_null("VisualInstance")
	if visual_instance == null:
		return

	# connect signals to visual instance
	self.red.connect(visual_instance.red)
	self.orange.connect(visual_instance.orange)
	self.green.connect(visual_instance.green)
	self.off.connect(visual_instance.off)
	self.speed_changed.connect(visual_instance.update_speed)
	self.warn_speed_changed.connect(visual_instance.update_warn_speed)

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
		signal_after_node = world.get_node("Signals/"+str(signal_after))
	
	if not Engine.is_editor_hint():
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
	timer.timeout.connect(self.update_visual_instance)
	self.add_child(timer)
	timer.start()
	
	if get_node_or_null("VisualInstance") != null:
		connect_visual_instance()
	
	# Set Signal while adding to the Signals node
	if Engine.is_editor_hint() and not get_parent().name == "Signals":
		if get_parent().is_in_group("Rail"):
			attached_rail = get_parent().name
		var signals: Node3D = find_parent("World").get_node("Signals")
		get_parent().remove_child(self)
		signals.add_child(self)
		update()
		
	if block_signal:
		set_state(SignalState.GREEN)
	
	set_to_rail(true)
	update()
	


func set_to_rail(newvar: bool):
	if world == null:
		print("Signal CANT FIND WORLD NODE!")
		return
	if world.has_node("Rails/"+attached_rail) and attached_rail != "":
		var rail: Node3D = get_parent().get_parent().get_node("Rails/"+attached_rail)
		rail.register_signal(self.name, on_rail_position)
		self.position = rail.get_pos_at_rail_distance(on_rail_position)
		self.rotation.y = deg2rad(rail.get_deg_at_rail_distance(on_rail_position))
		if not forward:
			self.rotation.y += deg2rad(180)

func give_signal_free():
	if block_signal:
		set_state(SignalState.GREEN)

func get_scenario_data():
	var d: Dictionary = {}
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
