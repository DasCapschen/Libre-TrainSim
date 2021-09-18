tool
extends Node

# Example: "res://Levels/Level1/Level1.save"
export (String) var save_path = ""

func set_save_path(save_path : String):
	self.save_path = save_path
	reload()

func save_value(key : String, value):
	_save.data[key] = value

func get_value(key,  default_value = null):
	if save_path == "":
		print_debug("Save path not configured correctly. Returning default_value.")
		return default_value
	elif _save.data.has(key):
		var value =  _save.data.get(key, default_value)
		return value
	else:
		return default_value

func reload():
	_load_current_config()

func write_to_disk():
	if save_path == "":
		print_debug("Save path not configured correctly. Not saving anything...")
		return
	ResourceSaver.save(save_path, _save)

## Internal Code ###############################################################
var _save = SaveableDictionary.new()

func _ready():
	_load_current_config()

func _load_current_config():
	if _save == null:
		_save = SaveableDictionary.new()
	if save_path == "":
		print_debug("Save path not configured correctly. Not initializing jSaveModule "+ name + ".")
		return

	var dir = Directory.new()
	if not dir.dir_exists(save_path.get_base_dir()):
		dir.make_dir_recursive(save_path.get_base_dir())

	if dir.file_exists(save_path):
		_save = load(save_path)
		if _save == null:
			printerr("even bigger wtf, was null after load!!")
			_save = SaveableDictionary.new() # fix for crash (why???)
	else:
		var old_path1 = save_path.replace(".tres", ".cfg")
		var old_path2 = save_path.replace("-chunks.tres", ".save")
		if dir.file_exists(old_path1):
			migrate(old_path1)
		elif dir.file_exists(old_path2):
			migrate(old_path2)
			

func migrate(old_path):
	var _config = ConfigFile.new()
	_config.load(old_path)
	for key in _config.get_section_keys("Main"):
		_save.data[key] = _config.get_value("Main", key, null)
	write_to_disk()

func _enter_tree():
	pass

func _exit_tree():
	write_to_disk()
