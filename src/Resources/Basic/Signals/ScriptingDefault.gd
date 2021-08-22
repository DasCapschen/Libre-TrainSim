tool
extends Node

onready var Signal = get_parent()
onready var world = find_parent("World")


var timer

func _ready():
	# blink once a second
	timer = Timer.new()
	timer.connect("timeout", self, "blink")
	self.add_child(timer)
	
	$Viewport.set_clear_mode(Viewport.CLEAR_MODE_ONLY_NEXT_FRAME)
	var texture = $Viewport.get_texture()
	$Screen1.material_override = $Screen1.material_override.duplicate(true)
	$Screen1.material_override.emission_texture = texture
	
	$Viewport2.set_clear_mode(Viewport.CLEAR_MODE_ONLY_NEXT_FRAME)
	texture = $Viewport2.get_texture()
	$Screen2.material_override = $Screen2.material_override.duplicate(true)
	$Screen2.material_override.emission_texture = texture


func blink():
	$Green.visible = ! $Green.visible

func green():
	$Red.visible = false
	$Orange.visible = false
	$Green.visible = true
	if Signal.warn_speed != -1:
		timer.start()

func red():
	$Red.visible = true
	$Orange.visible = false
	$Green.visible = false
	$Screen1.visible = false
	$Screen2.visible = false
	timer.stop()

func orange():
	$Red.visible = false
	$Orange.visible = true
	$Green.visible = false
	timer.stop()
	
func off():
	$Red.visible = false
	$Orange.visible = false
	$Green.visible = false
	timer.stop()


func update_speed(new_speed):
	if new_speed < 0:
		$Screen2.visible = false
	else:
		if new_speed - 100 >= 0:
			var output_speed = int(new_speed / 10)
			$Viewport2/Node2D/Label.text = String(output_speed)
		else: 
			var output_speed = int(new_speed / 10)
			var string = " " + String(output_speed)
			$Viewport2/Node2D/Label.text = string
		$Screen2.visible = true


func update_warn_speed(new_speed):
	if new_speed < 0:
		$Screen1.visible = false
	else:
		if new_speed - 100 >= 0:
			var output_speed = int(new_speed / 10)
			$Viewport/Node2D/Label.text = String(output_speed)
		else: 
			var output_speed = int(new_speed / 10)
			var string = " " + String(output_speed)
			$Viewport/Node2D/Label.text = string
		$Screen1.visible = true
		# start the timer in case we updated the speed after the state!
		if Signal.status == SignalState.GREEN:
			timer.start()
	
