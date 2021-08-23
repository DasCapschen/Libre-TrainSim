@tool
class_name RailAttachmentsDock extends Control


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var world
var current_rail
var copy_rail
var copy_TO
var copy_TO_array
var current_TO
var eds # Editor Selection
var plugin_root

var track_object_resource = preload("res://addons/Libre_Train_Sim_Editor/Data/Modules/TrackObjects.tscn")
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	$Tab/TrackObjects/Settings.visible = current_TO != null
	pass




func update_selected_rail(node):
	if node.is_in_group("Rail"):
		current_rail = node
		$CurrentRail/Name.text = node.name
		$Tab.visible = true
		var track_object_name = ""
		if is_instance_valid(current_TO):
			track_object_name = current_TO.description
		else:
			current_TO = null
		update_item_list()
		update_materials()
		update_positioning()
		
		# if jList has description, select this one..
		if $Tab/TrackObjects/jListTrackObjects.has_entry(track_object_name):
			$Tab/TrackObjects/jListTrackObjects.select_entry(track_object_name)
			_on_jListTrackObjects_user_selected_entry(track_object_name)
		else:
			current_TO = null
			
			
	else:
		current_rail = null
		$CurrentRail/Name.text = ""
		$Tab.visible = false

func update_item_list():
	$Tab/TrackObjects/jListTrackObjects.clear()
	var track_objects = current_rail.track_objects
	for x in range(track_objects.size()):
		if track_objects[x].description == null:
			track_objects[x].queue_free()
		else:
			$Tab/TrackObjects/jListTrackObjects.add_entry(track_objects[x].description)


#func _on_ClearTOs_pressed():
#	var tos = current_rail.track_objects
#	for x in range(tos.size()):
#		tos[x].queue_free()
#	current_rail.track_objects.clear()
#	update_item_list()
#	update_materials()
#	update_positioning()
#	update_position()
#	print("Cleared track_objects")
	

func _on_jListTrackObjects_user_removed_entries(entry_names):
	for entry_name in entry_names:
		var track_object = current_rail.get_track_object(entry_name)
		var track_object_name = track_object.name
		track_object.queue_free()
		current_rail.track_objects.erase(track_object)
		print("track_object ", track_object_name, " deleted")
	update_item_list()


#func _on_NewTO_pressed():
#	if $Tab/TrackObjects/HBoxContainer/LineEdit.text != "":
#		clear_materials_view()
#		var TO_object = load("res://addons/Libre_Train_Sim_Editor/Data/Modules/TrackObjects.tscn")
#		var to = TO_object.instantiate()
#		to.description = $Tab/TrackObjects/HBoxContainer/LineEdit.text
#		to.name = current_rail.name + " " + $Tab/TrackObjects/HBoxContainer/LineEdit.text
#		to.attached_rail = current_rail.name
#		to.material_paths = []
#		world.get_node("TrackObjects").add_child(to)
#		to.set_owner(world)
#
#		update_selected_rail(current_rail)
#		print("Created track_object: "+to.name)
		


func _on_jListTrackObjects_user_added_entry(entry_name):
	print(entry_name)
	clear_materials_view()
	var track_object = track_object_resource.instantiate()
	track_object.description = entry_name
	track_object.name = str(current_rail.name) + " " + entry_name
	track_object.attached_rail = current_rail.name
	track_object.material_paths = []
	world.get_node("TrackObjects").add_child(track_object)
	track_object.set_owner(world)
	
	print("Created track object ", track_object.name)

#func _on_RenameTO_pressed():
#	if $Tab/TrackObjects/HBoxContainer/LineEdit.text != "":
#		current_rail.track_objects[$Tab/TrackObjects/ItemList.get_selected_items()[0]].description = $Tab/TrackObjects/HBoxContainer/LineEdit.text
#		current_rail.track_objects[$Tab/TrackObjects/ItemList.get_selected_items()[0]].name = current_rail.name + " " + $Tab/TrackObjects/HBoxContainer/LineEdit.text
#	update_item_list()
#	print("track_object renamed: "+ current_rail.track_objects[$Tab/TrackObjects/ItemList.get_selected_items()[0]].name)

func _on_jListTrackObjects_user_renamed_entry(old_name, new_name):
	var track_object = current_rail.get_track_object(old_name)
	track_object.description = new_name
	track_object.name = str(current_rail.name) + " " + new_name
	print("track_object renamed from ", old_name, " to ", new_name)

#
#func _on_DuplicateTO_pressed():
#	var TO_object = load("res://addons/Libre_Train_Sim_Editor/Data/Modules/TrackObjects.tscn")
#	var to = TO_object.instantiate()
#	var data = current_TO.get_data()
#	to.set_data(data)
#	to.description = current_TO.description + " (Duplicate)"
#	to.name = current_TO.name + " (Duplicate)"
#	to.attached_rail = current_rail.name
#	world.get_node("TrackObjects").add_child(to)
#	to.set_owner(world)
#	update_selected_rail(current_rail)
#	to._update(true)
#	print("track_object " + to.name + " duplicated")
	
func _on_jListTrackObjects_user_duplicated_entries(source_entry_names, duplicated_entry_names):
	for i in range(source_entry_names.size()):
		var source_entry_name = source_entry_names[i]
		var duplicated_entry_name = duplicated_entry_names[i]
		var source_track_object = current_rail.get_track_object(source_entry_name)
		copy_track_object_to_current_rail(source_track_object, duplicated_entry_name)
		print("track_object ", source_entry_name, " duplicated.")
	pass # Replace with function body.

func copy_track_object_to_current_rail(source_track_object : Node, new_description : String, mirror : bool  = false):
	var new_track_object = track_object_resource.instantiate()
	var data = source_track_object.get_data()
	new_track_object.set_data(data)
	new_track_object.name = str(current_rail.name) + " " + new_description
	new_track_object.description = new_description
	new_track_object.attached_rail = current_rail.name
	world.get_node("TrackObjects").add_child(new_track_object)
	if mirror:
		new_track_object.rotation_objects = source_track_object.rotation_objects + 180.0
		if source_track_object.sides == 1:
			new_track_object.sides = 2
		elif source_track_object.sides == 2:
			new_track_object.sides = 1
	new_track_object.set_owner(world)
	new_track_object._update(true)


#func _on_DeleteTO_pressed():
#	if current_TO == null: return
#	var id = $Tab/TrackObjects/ItemList.get_selected_items()[0]
#	if id == null:
#		return
#	var to = current_rail.track_objects[id]
#	var n = to.name
#	to.queue_free()
#	current_rail.track_objects.erase(to)
#	current_TO = null
#	update_item_list()
#	print("track_object " + n + " deleted")


#func _on_ItemListTO_item_selected(index):	
#	current_TO = current_rail.track_objects[$Tab/TrackObjects/ItemList.get_selected_items()[0]]
#	if current_TO == null:
#		$"Tab/TrackObjects/Settings".visible = false
#		return
#	else:
#		$"Tab/TrackObjects/Settings".visible = true
#	update_materials()
#	update_positioning()
#	update_position()
#	$Tab/TrackObjects/HBoxContainer/LineEdit.text = current_TO.description
	
func _on_jListTrackObjects_user_selected_entry(entry_name):
	current_TO = current_rail.get_track_object(entry_name)
	if current_TO == null:
		$"Tab/TrackObjects/Settings".visible = false
		return
	else:
		$"Tab/TrackObjects/Settings".visible = true
	update_materials()
	update_positioning()
	update_position()
	pass # Replace with function body.
	

func get_materials(): ## Prepare the View of the Materials-Table
	var materials = current_TO.material_paths.duplicate()
	for x in range(current_TO.material_paths.size()):
		var entry = $"Tab/TrackObjects/Settings/Tab/Object/GridContainer/Material 0".duplicate()
		$Tab/TrackObjects/Settings/Tab/Object/GridContainer.add_child(entry)
		entry.get_node("Label").text = "Material " + str(x+1)
		entry.get_node("LineEdit").text =  current_TO.material_paths[x]
		entry.visible = true


func _on_AddMaterial_pressed():
	var entry = $"Tab/TrackObjects/Settings/Tab/Object/GridContainer/Material 0".duplicate()
	entry.set_script(load("res://addons/Libre_Train_Sim_Editor/Docks/RailAttachments/MaterialSelection.gd"))
	$Tab/TrackObjects/Settings/Tab/Object/GridContainer.add_child(entry)
	entry.get_node("Label").text = entry.name
	entry.visible = true
	print("Material Added")



func _on_SaveMaterials_pressed(): ## The object path is saved too here
	if current_TO == null:
		$"Tab/TrackObjects/Settings".visible = false
		return
	else:
		$"Tab/TrackObjects/Settings".visible = true
	current_TO.object_path = $Tab/TrackObjects/Settings/Tab/Object/HBoxContainer/LineEdit.text
	var childs = $Tab/TrackObjects/Settings/Tab/Object/GridContainer.get_children()
	current_TO.material_paths.clear()
	for child in childs:
		if child.get_node("LineEdit") != null and child.name != "Material 0":
			current_TO.material_paths.append(child.get_node("LineEdit").text)
	print("Materials Saved")
	update_current_rail_attachment()

func clear_materials_view():
	var childs = $Tab/TrackObjects/Settings/Tab/Object/GridContainer.get_children()
	for child in childs:
		if child.name != "Material 0" and child.find_parent("Material 0") == null:
			child.queue_free()
		
func update_materials():
	clear_materials_view()
	$Tab/TrackObjects/Settings/Tab/Object/HBoxContainer/LineEdit.text = ""
	if current_TO:
		var object_path = current_TO.object_path
		if not object_path:
			object_path = ""
		$Tab/TrackObjects/Settings/Tab/Object/HBoxContainer/LineEdit.text = object_path
		get_materials()
		
func update_position():
	if current_TO == null: return
	$Tab/TrackObjects/Settings/Tab/Position/WholeRail.pressed = current_TO.whole_rail
	
	$Tab/TrackObjects/Settings/Tab/Position/StartPos/SpinBox.value = current_TO.on_rail_position
	$Tab/TrackObjects/Settings/Tab/Position/EndPosition/SpinBox.value = current_TO.on_rail_position + current_TO.length
	_on_AssignWholeRail_pressed()


func _on_AssignWholeRail_pressed():
	$Tab/TrackObjects/Settings/Tab/Position/StartPos.visible = not $Tab/TrackObjects/Settings/Tab/Position/WholeRail.pressed
	$Tab/TrackObjects/Settings/Tab/Position/EndPosition.visible = not $Tab/TrackObjects/Settings/Tab/Position/WholeRail.pressed
	
	$Tab/TrackObjects/Settings/Tab/Position/StartPos/SpinBox.value = current_TO.on_rail_position
	$Tab/TrackObjects/Settings/Tab/Position/EndPosition/SpinBox.value = current_TO.on_rail_position + current_TO.length
	
	_on_SavePosition_pressed()
	update_current_rail_attachment()
	


func _on_SavePosition_pressed():
	if $Tab/TrackObjects/Settings/Tab/Position/WholeRail.pressed:
		current_TO.whole_rail = true
		return
	if $Tab/TrackObjects/Settings/Tab/Position/StartPos/SpinBox.value > current_rail.length:
		$Tab/TrackObjects/Settings/Tab/Position/StartPos/SpinBox.value = current_rail.length
	if $Tab/TrackObjects/Settings/Tab/Position/EndPosition/SpinBox.value > current_rail.length:
		$Tab/TrackObjects/Settings/Tab/Position/EndPosition/SpinBox.value = current_rail.length
	if $Tab/TrackObjects/Settings/Tab/Position/EndPosition/SpinBox.value < $Tab/TrackObjects/Settings/Tab/Position/StartPos/SpinBox.value:
		$Tab/TrackObjects/Settings/Tab/Position/EndPosition/SpinBox.value = $Tab/TrackObjects/Settings/Tab/Position/StartPos/SpinBox.value
	current_TO.whole_rail = false
	current_TO.on_rail_position = $Tab/TrackObjects/Settings/Tab/Position/StartPos/SpinBox.value
	current_TO.length = $Tab/TrackObjects/Settings/Tab/Position/EndPosition/SpinBox.value - $Tab/TrackObjects/Settings/Tab/Position/StartPos/SpinBox.value
	current_TO._update(true)
	print("Position Saved")



func _on_SavePositioning_pressed():
	current_TO.sides = $"Tab/TrackObjects/Settings/Tab/Object Positioning/OptionButton".selected
	current_TO.distance_length = $"Tab/TrackObjects/Settings/Tab/Object Positioning/GridContainer/Straight".value
	current_TO.distance_rows = $"Tab/TrackObjects/Settings/Tab/Object Positioning/GridContainer/LeftRight".value
	current_TO.shift = $"Tab/TrackObjects/Settings/Tab/Object Positioning/GridContainer/Shift".value
	current_TO.spawn_rate = $"Tab/TrackObjects/Settings/Tab/Object Positioning/GridContainer/SpawnRate".value
	current_TO.rows = $"Tab/TrackObjects/Settings/Tab/Object Positioning/GridContainer/Rows".value
	current_TO.height = $"Tab/TrackObjects/Settings/Tab/Object Positioning/GridContainer/Height".value
	current_TO.random_location = $"Tab/TrackObjects/Settings/Tab/Object Positioning/GridContainer2/CheckBoxRandLoc".pressed
	current_TO.random_location_factor = $"Tab/TrackObjects/Settings/Tab/Object Positioning/GridContainer2/RandomLocation".value
	current_TO.random_rotation = $"Tab/TrackObjects/Settings/Tab/Object Positioning/GridContainer2/CheckBoxRandRot".pressed
	current_TO.random_scale = $"Tab/TrackObjects/Settings/Tab/Object Positioning/GridContainer2/CheckBoxRadScal".pressed
	current_TO.random_scale_factor = $"Tab/TrackObjects/Settings/Tab/Object Positioning/GridContainer2/RandomScale".value
	current_TO.rotation_objects = $"Tab/TrackObjects/Settings/Tab/Object Positioning/GridContainer/Rotation".value
	current_TO.place_last = $"Tab/TrackObjects/Settings/Tab/Object Positioning/GridContainer/PlaceLast".pressed
	current_TO.apply_slope_rotation = $"Tab/TrackObjects/Settings/Tab/Object Positioning/GridContainer/applySlopeRotation".pressed
	print("Positioning Saved")
	update_current_rail_attachment()

func update_positioning():
	if current_TO == null: return
	$"Tab/TrackObjects/Settings/Tab/Object Positioning/OptionButton".select(current_TO.sides)
	$"Tab/TrackObjects/Settings/Tab/Object Positioning/GridContainer/Straight".value = current_TO.distance_length
	$"Tab/TrackObjects/Settings/Tab/Object Positioning/GridContainer/LeftRight".value = current_TO.distance_rows
	$"Tab/TrackObjects/Settings/Tab/Object Positioning/GridContainer/Shift".value = current_TO.shift
	$"Tab/TrackObjects/Settings/Tab/Object Positioning/GridContainer/SpawnRate".value = current_TO.spawn_rate
	$"Tab/TrackObjects/Settings/Tab/Object Positioning/GridContainer/Rows".value = current_TO.rows
	$"Tab/TrackObjects/Settings/Tab/Object Positioning/GridContainer/Height".value = current_TO.height
	$"Tab/TrackObjects/Settings/Tab/Object Positioning/GridContainer2/CheckBoxRandLoc".pressed = current_TO.random_location
	$"Tab/TrackObjects/Settings/Tab/Object Positioning/GridContainer2/RandomLocation".value = current_TO.random_location_factor
	$"Tab/TrackObjects/Settings/Tab/Object Positioning/GridContainer2/CheckBoxRandRot".pressed = current_TO.random_rotation
	$"Tab/TrackObjects/Settings/Tab/Object Positioning/GridContainer2/CheckBoxRadScal".pressed = current_TO.random_scale
	$"Tab/TrackObjects/Settings/Tab/Object Positioning/GridContainer2/RandomScale".value = current_TO.random_scale_factor
	$"Tab/TrackObjects/Settings/Tab/Object Positioning/GridContainer/Rotation".value = current_TO.rotation_objects
	$"Tab/TrackObjects/Settings/Tab/Object Positioning/GridContainer/PlaceLast".pressed = current_TO.place_last
	$"Tab/TrackObjects/Settings/Tab/Object Positioning/GridContainer/applySlopeRotation".pressed = current_TO.apply_slope_rotation
	print("Updating...")



func update_current_rail_attachment(): ## UPDATE
	print("Updating...")
	current_TO._update(true)
	if current_TO.description.begins_with("Pole"):
		current_rail.update_overhead_line()


#func _on_CopyTO_pressed():
#	copy_TO_array = []
#	for i in $Tab/TrackObjects/ItemList.get_selected_items():
#		copy_TO_array.append (current_rail.track_objects[i])
#	if copy_TO_array == []:
#		$"Tab/TrackObjects/Settings".visible = false
#		return
#	else:
#		$"Tab/TrackObjects/Settings".visible = true
#	print("track_object(s) copied. Please don't delete the track_object(s), until you pasted a copy of it/them.")
	

func _on_jListTrackObjects_user_copied_entries(entry_names):
	if entry_names.size() == 0:
		$"Tab/TrackObjects/Settings".visible = false
		return
	copy_TO_array = []
	for entry_name in entry_names:
		copy_TO_array.append(current_rail.get_track_object(entry_name))
	$"Tab/TrackObjects/Settings".visible = true
	print("track_object(s) copied. Please don't delete the track_object(s), until you pasted a copy of it/them.")





#func _on_PasteTO_pressed():
#	for TO in copy_TO_array:
#		duplicate_newTO(TO)
#	print("track_object(s) pasted")
	

func _on_jListTrackObjects_user_pasted_entries(source_entry_names, source_jList_id, pasted_entry_names):
	assert(pasted_entry_names.size() == copy_TO_array.size())
	for i in range (pasted_entry_names.size()):
		copy_track_object_to_current_rail(copy_TO_array[i], pasted_entry_names[i], $Tab/TrackObjects/MirrorPastedObjects.pressed)
			



#func duplicate_newTO(set):
#	if set != null:
#			var TO_object = load("res://addons/Libre_Train_Sim_Editor/Data/Modules/TrackObjects.tscn")
#			var to = TO_object.instantiate()
#			var data = set.get_data()
#			update_position()
#			to.set_data(data)
#			to.description = set.description
#			to.name = set.name
#			to.attached_rail = current_rail.name
#			world.get_node("TrackObjects").add_child(to)
#			to.set_owner(world)
#			update_selected_rail(current_rail)
#			current_TO = to
#			_on_SavePosition_pressed()
#			_on_Button_pressed()
#			update_item_list()
#			print("Track Object pasted")

#		var to = set.duplicate()
#		to.material_paths = set.material_paths.duplicate()
#		to.attached_rail = current_rail.name
#		to.name = current_rail.name + " " + to.description
#		world.get_node("TrackObjects").add_child(to)
#		to.set_owner(world)
#		current_TO = to
#		_on_SavePosition_pressed() ## Apply Positions and update the the Mesh Instance
#		_on_Button_pressed()
#		update_item_list()
#		print("Track Object pasted")
#

#
#func _on_CopyTrack_pressed():
#	copy_rail = current_rail
#	print("Track Objects copied")

#
#func _on_PasteRail_pressed():
#	print("Pasting Track Objects..")
#	for to in copy_rail.track_objects:
#		duplicate_newTO(to)
	


func _on_PickObject_pressed():
	$FileDialogObjects.popup_centered()
	


func _on_FileDialog_onject_selected(path):
	$Tab/TrackObjects/Settings/Tab/Object/HBoxContainer/LineEdit.text = path
	_on_SaveMaterials_pressed()
	update_current_rail_attachment() # update


var current_material = 0
func _on_FileDialogMaterials_file_selected(path):
	if current_material != 0:
		get_node("Tab/track_objects/Settings/Tab/Object/GridContainer/Material " + str(current_material) + "/LineEdit").text = path
		_on_SaveMaterials_pressed()
		update_current_rail_attachment() # update


func _on_PickMaterial_pressed(): ## Called by material select script.
	$FileDialogMaterials.popup_centered()


#func _on_ItemList_multi_selected(index, selected):
#	_on_ItemListTO_item_selected(index)


func _on_MaterialRemove_pressed():
	var material_row = $Tab/TrackObjects/Settings/Tab/Object/GridContainer.get_children().back()
	if material_row.name != "Material 0":
		$Tab/TrackObjects/Settings/Tab/Object/GridContainer.get_children().back().queue_free()
	pass # Replace with function body.


func _on_Randomize_pressed():
	current_TO.newSeed()
	update_current_rail_attachment() # update
