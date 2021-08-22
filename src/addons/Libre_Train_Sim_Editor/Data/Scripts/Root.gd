tool
extends Node

var current_scenario
var current_train
var easy_mode = true
var mobile_version = false



var world ## Reference to world

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func check_and_load_translations_for_track(track_name): # Searches for translation files with track_name in res://Translations/
	print(track_name.get_file().get_basename())
	var track_translations = []
	var dir = Directory.new()
	dir.open("res://Translations")
	dir.list_dir_begin()
	while(true):
		var file = dir.get_next()
		if file == "":
				break
		if file.get_extension() == "translation":
			if file.get_file().begins_with(track_name):
				track_translations.append("res://Translations/" + file.get_file())
				print("Track Translation Found " + "res://Translations/" + file.get_file())
	for track_translation_path in track_translations:
		var track_translation = load(track_translation_path)
		print(track_translation.locale)
		TranslationServer.add_translation(track_translation)

func check_and_load_translations_for_train(train_dir_path): # Searches for translation files wich are located in the same folder as the train.tscn. Gets the full path to train.tscn as input
	print(train_dir_path)
	var train_translations = []
	var dir = Directory.new()
	dir.open(train_dir_path)
	dir.list_dir_begin()
	while(true):
		var file = dir.get_next()
		if file == "":
				break
		if file.get_extension() == "translation":
			train_translations.append(train_dir_path+"/"+file)
			print("Track Translation Found " + "res://Translations/" + file.get_file())
	for train_translation_path in train_translations:
		var train_translation = load(train_translation_path)
		print(train_translation.locale)
		TranslationServer.add_translation(train_translation)

## found_files has to be an dict: {"Array" : []}
func crawl_directory(directory_path,found_files,file_extension): 
	var dir = Directory.new()
	if dir.open(directory_path) != OK: return
	dir.list_dir_begin()
	while(true):
		var file = dir.get_next()
		if file == "": break
		if file.begins_with("."): continue
		if dir.current_is_dir():
			if directory_path.ends_with("/"):
				crawl_directory(directory_path+file, found_files, file_extension)
			else:
				crawl_directory(directory_path+"/"+file, found_files, file_extension)
		else:
			if file.get_extension() == file_extension:
				var export_string 
				if directory_path.ends_with("/"):
					export_string = directory_path +file
				else:
					export_string = directory_path +"/"+file
				found_files["Array"].append(export_string)
	dir.list_dir_end()
	
# approaches 'ist' value to 'soll' value in one second  (=smooth transitions from current 'ist' value to 'soll' value)
func clamp_via_time(soll : float, ist : float, delta : float):
	ist += (soll-ist)*delta
	return ist

func fix_frame_drop():
	if not jSettings.get_framedrop_fix():
		return
	jEssentials.call_delayed(0.7, self,  "set_fullscreen", [!jSettings.get_fullscreen()])
	jEssentials.call_delayed(0.9, self,  "set_fullscreen", [jSettings.get_fullscreen()])
	
func set_fullscreen(value : bool):
	OS.window_fullscreen = value

func set_low_resolution(value : bool):
	if value:
		if ProjectSettings.get_setting("display/window/stretch/mode") == "viewport":
			return
		ProjectSettings.set_setting("display/window/stretch/mode", "viewport")
		ProjectSettings.set_setting("display/window/stretch/aspect", "keep")
		ProjectSettings.set_setting("display/window/size/width", "1280")
		ProjectSettings.set_setting("display/window/size/height", "720")
		ProjectSettings.save()
	else:
		ProjectSettings.set_setting("display/window/stretch/mode", "disabled")
		ProjectSettings.set_setting("display/window/stretch/aspect", "ignore")
		ProjectSettings.set_setting("display/window/size/width", "800")
		ProjectSettings.set_setting("display/window/size/height", "600")
		ProjectSettings.save()
