@tool
extends Node3D

const type = SignalType.SPEED

@export var speed: int

@export var attached_rail: String
@export var on_rail_position: int
@export var update: bool:
	set(val): set_to_rail(val)
@export var forward = true


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
		set_to_rail(true)



# warning-ignore:unused_argument
func set_to_rail(newvar):
	$Viewport.set_clear_mode(Viewport.CLEAR_MODE_ONLY_NEXT_FRAME)
	var texture = $Viewport.get_texture()
	$Object/Display.material_override = $Object/Display.material_override.duplicate(true)
	$Object/Display.material_override.albedo_texture = texture
	
	
	if speed - 100 >= 0:
		var output_speed = int(speed / 10)
		$Viewport/Speed/Label.text = str(output_speed)
	else: 
		var output_speed = int(speed / 10)
		var string = " " + str(output_speed)
		$Viewport/Speed/Label.text = string
	
	
	if not find_parent("World"):
		print("SpeedSign can't find World Parent!'")
		return
	
	if find_parent("World").has_node("Rails/"+attached_rail) and attached_rail != "":
		var rail = find_parent("World").get_node("Rails/"+attached_rail)
		rail.register_signal(self.name, on_rail_position)
		self.position = rail.get_pos_at_rail_distance(on_rail_position)
		self.rotation.y = deg2rad(rail.get_deg_at_rail_distance(on_rail_position))
		if not forward:
			self.rotation.y += deg2rad(180)


func set_scenario_data(d):
	return
func get_scenario_data():
	return null
