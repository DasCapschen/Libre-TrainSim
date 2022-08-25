tool
extends VBoxContainer

var base: Control
var dir_select_dialog: FileDialog

var IMPORTED_RESOURCE_TYPES := ["StreamTexture", "Mesh"]

func _on_new_mod_pressed() -> void:
	var popup = preload("new_mod_popup.tscn").instance()
	popup.base_control = base
	base.add_child(popup)
	popup.popup_centered()


func _on_LinkButton_pressed() -> void:
	OS.shell_open("https://www.libretrainsim.org/contribute")


func _on_open_addons_dir_pressed() -> void:
	OS.shell_open(ProjectSettings.globalize_path("user://addons"))


func _on_export_mod_pressed() -> void:
	dir_select_dialog = FileDialog.new()
	dir_select_dialog.rect_min_size = Vector2(500, 300)
	dir_select_dialog.rect_size = Vector2(500, 300)
	dir_select_dialog.resizable = true
	dir_select_dialog.window_title = "Select Mod to Export"
	dir_select_dialog.mode = FileDialog.MODE_OPEN_DIR
	dir_select_dialog.access = FileDialog.ACCESS_RESOURCES
	dir_select_dialog.current_dir = "res://Mods"
	dir_select_dialog.connect("dir_selected", self, "_on_export_dir_selected")
	base.add_child(dir_select_dialog)
	dir_select_dialog.popup_centered()


func _on_export_dir_selected(dir: String) -> void:
	dir_select_dialog.queue_free()

	var mod_name = dir.get_file()
	var mod_path = "user://addons/".plus_file(mod_name)

	var directory = Directory.new()
	directory.open("user://")
	directory.make_dir_recursive(mod_path)
	directory.change_dir(mod_path)

	var packer = PCKPacker.new()
	var err = packer.pck_start(mod_path.plus_file(mod_name) + ".pck")
	if err != OK:
		Logger.err("Error creating %s! (Reason: %s)" % [mod_path.plus_file(mod_name) + ".pck", err], self)
		return

	var import_files_to_pack = []

	var files = get_files_in_directory("res://Mods/".plus_file(mod_name))
	for file in files:
		if file.ends_with(".import"):
			import_files_to_pack.append_array(_get_imported_paths(file))

		err = packer.add_file(file, file)
		if err != OK:
			Logger.err("Could not add file %s to pck! (Reason: %s)" % [file, err], self)

	for file in import_files_to_pack:
		err = packer.add_file(file, file)
		if err != OK:
			Logger.err("Could not add file %s to pck! (Reason: %s)" % [file, err], self)

	err = packer.flush(true)
	if err != OK:
		Logger.err("Could not flush pck! (Reason: %s)" % err, self)

	err = directory.copy(dir.plus_file("content.tres"), mod_path.plus_file("content.tres"))
	if err != OK:
		Logger.err("Unable to copy content.tres to mod folder! (Reason: %s)" % err, self)


func _get_imported_paths(file):
	var cfg = ConfigFile.new()
	if cfg.load(file) != OK:
		Logger.err("cannot open .import file", self)
	var type = cfg.get_value("remap", "type", "")

	if type in IMPORTED_RESOURCE_TYPES:
		return cfg.get_value("deps", "dest_files", [])
	return []


func get_files_in_directory(path: String) -> Array:
	var files = []
	var dir = Directory.new()
	dir.open(path)
	dir.list_dir_begin(true, true)
	var file_name = dir.get_next()
	while file_name != "":
		if dir.current_is_dir():
			files.append_array(get_files_in_directory(path.plus_file(file_name)))
		else:
			files.append(path.plus_file(file_name))
		file_name = dir.get_next()
	return files
