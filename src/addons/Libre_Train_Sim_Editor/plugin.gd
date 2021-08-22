tool
extends EditorPlugin

var rail_builder
var rail_attachements
var configuration
var eds = get_editor_interface().get_selection()
#var fileSelecting = ""
#var fileResult = ""
#var fileDialog

func _process(delta):
	configuration.world = get_editor_interface().get_edited_scene_root()
	
#	if fileSelecting != "":
#		var fileDialog = EditorFileDialog.new()
#		get_parent().add_child(fileDialog)
#		fileDialog = 
#		fileDialog.popup_centered(Vector2(10,10))
#		fileSelecting = ""

func _enter_tree():
	# Initialization of the plugin goes here
	rail_builder = preload("res://addons/Libre_Train_Sim_Editor/Docks/RailBuilder/RailBuilder.tscn").instance()
	add_control_to_dock(DOCK_SLOT_RIGHT_UL, rail_builder)

	rail_builder.world = get_editor_interface().get_edited_scene_root()
	rail_builder.eds = eds
	

	
	rail_attachements = preload("res://addons/Libre_Train_Sim_Editor/Docks/RailAttachments/RailAttachments.tscn").instance()
	add_control_to_dock(DOCK_SLOT_RIGHT_UL, rail_attachements)
	rail_attachements.world = get_editor_interface().get_edited_scene_root()
	rail_attachements.eds = eds
	rail_attachements.plugin_root = self
	
	eds.connect("selection_changed", self, "_on_selection_changed")
	
	configuration = preload("res://addons/Libre_Train_Sim_Editor/Docks/Configuration/Configuration.tscn").instance()
	add_control_to_dock(DOCK_SLOT_RIGHT_UL, configuration)
	configuration.world = get_editor_interface().get_edited_scene_root()

	pass

func _exit_tree():
	remove_control_from_docks(rail_builder)
	rail_builder.free()
	
	remove_control_from_docks(rail_attachements)
	rail_attachements.free()
	
	remove_control_from_docks(configuration)
	configuration.free()
	
	# Clean-up of the plugin goes here
	pass



		
func _on_selection_changed():
	rail_builder.world = get_editor_interface().get_edited_scene_root()
	rail_attachements.world = get_editor_interface().get_edited_scene_root()
	# Returns an array of selected nodes
	var selected = eds.get_selected_nodes() 

	if not selected.empty():
		# Always pick first node in selection
		rail_builder.update_selected_rail(selected[0])
		rail_attachements.update_selected_rail(selected[0])
		
