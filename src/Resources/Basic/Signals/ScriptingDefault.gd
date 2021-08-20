tool
extends Node

onready var Signal = get_parent()
onready var world = find_parent("World")

var blinking = false
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
	if blinking:
		green()
	else:
		off()
	blinking = !blinking

func green():
	print("green")
	$Red.visible = false
	$Orange.visible = false
	$Green.visible = true
	if Signal.warnSpeed != -1:
		timer.start()

func red():
	print("Red")
	$Red.visible = true
	$Orange.visible = false
	$Green.visible = false
	$Screen1.visible = false
	$Screen2.visible = false
	timer.stop()

func orange():
	print("orange")
	$Red.visible = false
	$Orange.visible = true
	$Green.visible = false
	timer.stop()
	
func off():
	print("off")
	$Red.visible = false
	$Orange.visible = false
	$Green.visible = false
	timer.stop()


func update_speed(new_speed):
	print("speed update")
	if new_speed < 0:
		$Screen2.visible = false
	else:
		if new_speed - 100 >= 0:
			var outputSpeed = int(new_speed / 10)
			$Viewport2/Node2D/Label.text = String(outputSpeed)
		else: 
			var outputSpeed = int(new_speed / 10)
			var string = " " + String(outputSpeed)
			$Viewport2/Node2D/Label.text = string
		$Screen2.visible = true


func update_warn_speed(new_speed):
	print("warn speed update")
	if new_speed < 0:
		$Screen1.visible = false
	else:
		if new_speed - 100 >= 0:
			var outputSpeed = int(new_speed / 10)
			$Viewport/Node2D/Label.text = String(outputSpeed)
		else: 
			var outputSpeed = int(new_speed / 10)
			var string = " " + String(outputSpeed)
			$Viewport/Node2D/Label.text = string
		$Screen1.visible = true
		
