tool
extends Control


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
export var version = ""
export (bool) var mobile_version setget update_project_for_mobile
var save_path = OS.get_executable_path().get_base_dir()+"config.cfg"

# Called when the node enters the scene tree for the first time.
func _ready():
	if Engine.is_editor_hint():
		return
	update_config()
	$Version.text = "Version: " + String(version)
	var open_times = jSaveManager.get_value("open_times", 0)
	open_times += 1
	jSaveManager.save_value("open_times", open_times)
	var feedback_pressed = jSaveManager.get_value("feedback_pressed", false)
	if open_times > 3 and not feedback_pressed and not mobile_version:
		$FeedBack/VBoxContainer/RichTextLabel.text = TranslationServer.translate("MENU_FEEDBACK_QUESTION")
		$FeedBack.popup()
	$MusicPlayer.play(0)


	Root.mobile_version = mobile_version

	if mobile_version:
		set_menu_to_mobile()

	
func set_menu_to_mobile():
	$Front/VBoxContainer.hide()
	$Front/VBoxContainerAndoid.show()
	$Front/Feedback.hide()
	$Play/Buttons/Play.add_font_override("font", preload("res://addons/Libre_Train_Sim_Editor/Data/Misc/FontMenu.tres"))
	$Play/Buttons/Back.add_font_override("font", preload("res://addons/Libre_Train_Sim_Editor/Data/Misc/FontMenu.tres"))
	$Play/Selection/Tracks/Label.add_font_override("font", preload("res://addons/Libre_Train_Sim_Editor/Data/Misc/FontMenu.tres"))
	$Play/Selection/Tracks/ItemList.add_font_override("font", preload("res://addons/Libre_Train_Sim_Editor/Data/Misc/FontMenu.tres"))
	$Play/Selection/Scenarios/Label.add_font_override("font", preload("res://addons/Libre_Train_Sim_Editor/Data/Misc/FontMenu.tres"))
	$Play/Selection/Scenarios/ItemList.add_font_override("font", preload("res://addons/Libre_Train_Sim_Editor/Data/Misc/FontMenu.tres"))
	$Play/Selection/Trains/Label.add_font_override("font", preload("res://addons/Libre_Train_Sim_Editor/Data/Misc/FontMenu.tres"))
	$Play/Selection/Trains/ItemList.add_font_override("font", preload("res://addons/Libre_Train_Sim_Editor/Data/Misc/FontMenu.tres"))
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Engine.is_editor_hint():
		return
	load_scene(delta)
	update_bottom_labels()


var found_tracks = []
var found_content_packs = []
var found_trains = []

var current_track = ""
var current_train = ""
var current_scenario = ""

func _on_Quit_pressed():
	get_tree().quit()


func update_bottom_labels():
	$Label_Music.visible = jSaveManager.get_setting("musicVolume", 0.0) != 0.0
	$Version.visible = $Front.visible

func _on_BackPlay_pressed():
	$Play.hide()
	$MenuBackground.hide()
	$Front.show()
	$Version.show()




func _on_PlayFront_pressed():
	update_track_list()
	$Play.show()
	$MenuBackground.show()
	$Front.hide()
	$Version.hide()

func _on_Content_pressed():
	update_content()
	$Front.hide()
	$MenuBackground.show()
	$Content.show()

func _on_SettingsFront_pressed():
#	$Front.hide()
	jSettings.open_window()
#	$MenuBackground.show()
#	$Settings.show()

func update_config():
	## Get All .pck files:
	found_content_packs = []
	var dir = Directory.new()
	dir.open(OS.get_executable_path().get_base_dir())
	dir.list_dir_begin()
	while(true):
		var file = dir.get_next()
		if file == "":
			break
		if file.get_extension() == "pck":
			found_content_packs.append(file)
	dir.list_dir_end()
	print("Found Content Packs: " + String(found_content_packs))

	for content_pack in found_content_packs:
		if ProjectSettings.load_resource_pack(content_pack, false):
			print("Loading Content Pack "+ content_pack+" successfully finished")

	## Get all Tracks:
	var found_files = {"Array": []}
	Root.crawl_directory("res://Worlds",found_files,"tscn")
	print(found_files)
	found_tracks = found_files["Array"].duplicate(true)

	## Get all Trains
	found_files = {"Array": []}
	Root.crawl_directory("res://Trains",found_files,"tscn")
	found_trains = found_files["Array"].duplicate(true)


func update_track_list():
	$Play/Selection/Tracks/ItemList.clear()
	for track in found_tracks:
		$Play/Selection/Tracks/ItemList.add_item(track.get_file().get_basename())

func update_train_list():
	$Play/Selection/Trains/ItemList.clear()
	for train in found_trains:
		$Play/Selection/Trains/ItemList.add_item(train.get_file().get_basename())


# Play Page:
func _on_PlayPlay_pressed():
	if current_scenario == "" or current_track == "" or current_train == "": return
	var index = $Play/Selection/Tracks/ItemList.get_selected_items()[0]
	Root.current_scenario = current_scenario
	Root.current_train = current_train
	Root.easy_mode = $Play/Info/Info/EasyMode.pressed
	$MenuBackground.hide()
	$Play.hide()
	$Loading.show()
	## Load Texture
	var save_path = found_tracks[index].get_basename() + "-scenarios.cfg"
	var config = ConfigFile.new()
	var load_response = config.load(save_path)
	var w_data = config.get_value("WorldConfig", "Data", null)
	$Background.texture = load(w_data["ThumbnailPath"])
	load_scene_path = found_tracks[index]

var load_scene_path = ""
var load_scene_timer = 0
func load_scene(delta):
	if load_scene_path != "":
		load_scene_timer += delta
		if load_scene_timer > 0.2:
			get_tree().change_scene(load_scene_path)

func _on_ItemList_itemTracks_selected(index):
	current_track = found_tracks[index]
	Root.check_and_load_translations_for_track(current_track.get_file().get_basename())
	current_scenario = ""
	var save_path = found_tracks[index].get_basename() + "-scenarios.cfg"
	var config = ConfigFile.new()
	var load_response = config.load(save_path)

	var w_data = config.get_value("WorldConfig", "Data", null)
	if w_data == null:
		print(save_path)
		$Play/Info/Description.text = TranslationServer.translate("MENU_NO_SCENARIO_FOUND")
		$Play/Info/Description.text = TranslationServer.translate(save_path)
		$Play/Selection/Scenarios.hide()
		return
	$Play/Info/Description.text = TranslationServer.translate(w_data["TrackDesciption"])
	$Play/Info/Info/Author.text = " "+ TranslationServer.translate("MENU_AUTHOR") + ": " + w_data["Author"] + " "
	$Play/Info/Info/ReleaseDate.text = " "+ TranslationServer.translate("MENU_RELEASE") + ": " + String(w_data["ReleaseDate"][1]) + " " + String(w_data["ReleaseDate"][2]) + " "
	$Play/Info/Screenshot.texture = load(w_data["ThumbnailPath"])

	$Play/Selection/Scenarios.show()
	$Play/Selection/Scenarios/ItemList.clear()
	$Play/Selection/Trains.hide()
	$Play/Info/Info/EasyMode.hide()
	var scenarios = config.get_value("Scenarios", "List", [])
	for scenario in scenarios:
		if mobile_version and (scenario == "The Basics" or scenario == "Advanced Train Driving"):
			continue
		if not mobile_version and scenario == "The Basics - Mobile Version":
			continue
		$Play/Selection/Scenarios/ItemList.add_item(scenario)

## Content Page:
func update_content():
	$Content/Label.text = TranslationServer.translate("MENU_TO_ADD_CONTENT") + " " + OS.get_executable_path().get_base_dir()
	$Content/ItemList.clear()
	for content_pack in found_content_packs:
		$Content/ItemList.add_item(content_pack)



func _on_BackContent_pressed():
	$MenuBackground.hide()
	$Content.hide()
	$Front.show()

func _on_ReloadContent_pressed():
	update_config()
	update_content()


func _on_ItemList_scenario_selected(index):
	current_scenario = $Play/Selection/Scenarios/ItemList.get_item_text(index)
	var save_path = found_tracks[$Play/Selection/Tracks/ItemList.get_selected_items()[0]].get_basename() + "-scenarios.cfg"
	var config = ConfigFile.new()
	var load_response = config.load(save_path)
	var scenario_data = config.get_value("Scenarios", "scenario_data", {})
	$Play/Info/Description.text = TranslationServer.translate(scenario_data[current_scenario]["Description"])
	$Play/Info/Info/Duration.text = TranslationServer.translate("MENU_DURATION")+": " + String(scenario_data[current_scenario]["Duration"]) + " min"
	$Play/Selection/Trains.show()
	$Play/Info/Info/EasyMode.hide()
	update_train_list()

	# Search and preselect train from scenario:
	$Play/Selection/Trains/ItemList.unselect_all()
	var preferred_train = scenario_data[current_scenario]["Trains"].get("Player", {}).get("PreferredTrain", "")
	if preferred_train != "":
		for i in range(found_trains.size()):
			if found_trains[i].find(preferred_train) != -1:
				$Play/Selection/Trains/ItemList.select(i)
				_on_ItemList_Train_selected(i)






func _on_ItemList_Train_selected(index):
	current_train = found_trains[index]
	Root.check_and_load_translations_for_train(current_train.get_base_dir())
	var train = load(current_train).instance()
	current_train = found_trains[index]
	print("Current Train: "+current_train)
	$Play/Info/Description.text = TranslationServer.translate(train.description)
	$Play/Info/Info/ReleaseDate.text = TranslationServer.translate("MENU_RELEASE")+": "+ train.release_date
	$Play/Info/Info/Author.text = TranslationServer.translate("MENU_AUTHOR")+": "+ train.author
	$Play/Info/Screenshot.texture = load(train.screenshot_path)#
	var electric = TranslationServer.translate("YES")
	if not train.electric:
		electric = TranslationServer.translate("NO")
	$Play/Info/Info/Duration.text = TranslationServer.translate("MENU_ELECTRIC")+ ": " + electric
	if not Root.mobile_version:
		$Play/Info/Info/EasyMode.show()
	else:
		$Play/Info/Info/EasyMode.pressed = true
	train.queue_free()



func _on_ButtonFeedback_pressed():
	jSaveManager.save_value("feedback_pressed", true)
	OS.shell_open("https://www.libre-trainsim.de/feedback")



func _on_OpenWebBrowser_pressed():
	_on_ButtonFeedback_pressed()
	$FeedBack.hide()


func _on_Later_pressed():
	$FeedBack.hide()









func update_project_for_mobile(value):
	Root.set_low_resolution(value)
	mobile_version = value






func _on_FrontCreate_pressed():
	OS.shell_open("https://www.libre-trainsim.de/contribute")




func _on_Options_pressed_delme():
	jSettings.open_window()
