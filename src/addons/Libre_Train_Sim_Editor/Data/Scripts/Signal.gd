tool
extends Spatial
const type = "Signal" # Never change this type!!
onready var world = find_parent("World")

# blinking if State == Green AND speed > 0
# orange and red signals never blink!
export(int, "Off", "Red", "Green", "Orange") var status = SignalState.RED

var signalAfter = "" # SignalName of the following signal. Set by the route manager from the players train. Just works for the players route. Should only be used for visuals!!
var signalAfterNode # Reference to the signal after it. Set by the route manager from the players train. Just works for the players route. Should only be used for visuals!!

export var setPassAtH = -1 # If these 3 variables represent a real time (24h format), the signal will be turned green at this specified time.
export var setPassAtM = 0
export var setPassAtS = 0

export var speed = -1 # SpeedLimit, which will be applied to the train. If -1: Speed Limit won't be changed by overdriving.
var warnSpeed = -1 # Displays the speed of the following speedlimit. Just used for the player train. It doesn't affect any train..

export var blockSignal = false


export var visualInstancePath = ""

export (String) var attachedRail # Internal. Never change this via script.
var attachedRailNode
export var forward = true # Internal. Never change this via script.
export (int) var onRailPosition # Internal. Never change this via script.

export (bool) var update setget setToRail # Just uesd for the editor. If it will be pressed, then the function set_get rail will be


signal red
signal green
signal orange
signal off
signal warn_speed_changed(new_speed)
signal speed_changed(new_speed)


var timer

func updateVisualInstance():
	update()
	if attachedRailNode == null:
		attachedRailNode = find_parent("World").get_node("Rails" + "/" + attachedRail)
		if attachedRailNode == null:
			return
			
	visible = attachedRailNode.visible
	if not attachedRailNode.visible:
		if get_node_or_null("VisualInstance") != null:
			$VisualInstance.queue_free()
		return

	if get_node_or_null("VisualInstance") == null:
		create_visual_instance()


func create_visual_instance():
	print("creating visual instance")
	var visualInstanceResource = null
	if visualInstancePath != "":
		visualInstanceResource = load(visualInstancePath)
	if visualInstanceResource == null:
		visualInstanceResource = load("res://Resources/Basic/Signals/Default.tscn")
	var visualInstance = visualInstanceResource.instance()
	add_child(visualInstance)
	visualInstance.name = "VisualInstance"
	visualInstance.owner = self
	connect_visual_instance()
	
func connect_visual_instance():
	# get visual instance
	var visualInstance = get_node_or_null("VisualInstance")
	if visualInstance == null:
		return

	# connect signals to visual instance
	self.connect("red", visualInstance, "red")
	self.connect("orange", visualInstance, "orange")
	self.connect("green", visualInstance, "green")
	self.connect("off", visualInstance, "off")
	self.connect("speed_changed", visualInstance, "update_speed")
	self.connect("warn_speed_changed", visualInstance, "update_warn_speed")

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
	emit_signal("warn_speed_changed", warnSpeed)


func update():
	if Engine.is_editor_hint() and blockSignal:
		set_state(SignalState.GREEN)
	
	if world == null:
		world = find_parent("World")
	
	if signalAfterNode == null and signalAfter != "":
		signalAfterNode = world.get_node("Signals/"+String(signalAfter))
	
	if not Engine.is_editor_hint() and world.time != null:
		if world.time[0] >= setPassAtH and world.time[1] >= setPassAtM and world.time[2] >= setPassAtS:
			set_state(SignalState.GREEN)
	
	# check next signal if this signal is not red.
	# is next signal red? If yes, go Orange, else stay green
	if status != SignalState.RED and signalAfterNode != null:
		match signalAfterNode.status:
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
	warnSpeed = new_speed
	emit_signal("warn_speed_changed", new_speed)

func _ready():
	timer = Timer.new()
	timer.connect("timeout", self, "updateVisualInstance")
	self.add_child(timer)
	timer.start()
	
	if get_node_or_null("VisualInstance") != null:
		connect_visual_instance()
	
	# Set Signal while adding to the Signals node
	if Engine.is_editor_hint() and not get_parent().name == "Signals":
		if get_parent().is_in_group("Rail"):
			attachedRail = get_parent().name
		var signals = find_parent("World").get_node("Signals")
		get_parent().remove_child(self)
		signals.add_child(self)
		update()
		
	if blockSignal:
		set_state(SignalState.GREEN)
	
	setToRail(true)
	update()
	


func setToRail(newvar):
	var world = find_parent("World")
	if world == null:
		print("Signal CANT FIND WORLD NODE!")
		return
	if world.has_node("Rails/"+attachedRail) and attachedRail != "":
		var rail = get_parent().get_parent().get_node("Rails/"+attachedRail)
		rail.register_signal(self.name, onRailPosition)
		self.translation = rail.get_pos_at_RailDistance(onRailPosition)
		self.rotation_degrees.y = rail.get_deg_at_RailDistance(onRailPosition)
		if not forward:
			self.rotation_degrees.y += 180

func giveSignalFree():
	if blockSignal:
		set_state(SignalState.GREEN)

func get_scenario_data():
	var d = {}
	d.status = status
	d.setPassAtH = setPassAtH
	d.setPassAtM = setPassAtM
	d.setPassAtS = setPassAtS
	d.speed = speed
	d.blockSignal = blockSignal
	return d

func set_scenario_data(d):
	set_state(d.status)
	setPassAtH = d.setPassAtH
	setPassAtM = d.setPassAtM
	setPassAtS = d.setPassAtS
	set_speed(d.speed)
	blockSignal = d.get("blockSignal", false)


func reset():
	set_state(SignalState.RED)
	setPassAtH = 25
	setPassAtM = 0
	setPassAtS = 0
	set_speed(-1)
	blockSignal = false
