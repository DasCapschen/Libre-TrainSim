extends Control

var save_path
var config

var language_table = {"en" : 0, "de" : 1}

# Called when the node enters the scene tree for the first time.
func _ready():
	save_path = get_parent().save_path
	config = get_parent().config

	$GridContainer/AntiAliasing.add_item(tr("MENU_DISABLED"), Viewport.MSAA_DISABLED)
	$GridContainer/AntiAliasing.add_item("2x", Viewport.MSAA_2X)
	$GridContainer/AntiAliasing.add_item("4x", Viewport.MSAA_4X)
	$GridContainer/AntiAliasing.add_item("8x", Viewport.MSAA_8X)
	$GridContainer/AntiAliasing.add_item("16x", Viewport.MSAA_16X)
	$GridContainer/AntiAliasing.select(config.get_value("Settings", "antiAliasing", ProjectSettings.get_setting("rendering/quality/filters/msaa")))

	updateLanguage()

	$GridContainer/Fullscreen.pressed = config.get_value("Settings", "fullscreen", true)
	$GridContainer/Shadows.pressed = config.get_value("Settings", "shadows", true)
	$GridContainer/ViewDistance.value = config.get_value("Settings", "viewDistance", 1000)
	$GridContainer/Fog.pressed = config.get_value("Settings", "fog", true)
	$GridContainer/MainMenuMusic.pressed = config.get_value("Settings", "mainMenuMusic", true)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_Fullscreen_pressed():
	config.set_value("Settings", "fullscreen", $GridContainer/Fullscreen.pressed)
	config.save(save_path)
	# OS.window_fullscreen = $GridContainer/Fullscreen.pressed

func _on_Shadows_pressed():
	config.set_value("Settings", "shadows", $GridContainer/Shadows.pressed)
	config.save(save_path)

func _on_ViewDistance_value_changed(value):
	config.set_value("Settings", "viewDistance", $GridContainer/ViewDistance.value)
	config.save(save_path)

func _on_AntiAliasing_item_selected(index):
	config.set_value("Settings", "antiAliasing", $GridContainer/AntiAliasing.selected)
	config.save(save_path)

func _on_Fog_pressed():
	config.set_value("Settings", "fog", $GridContainer/Fog.pressed)
	config.save(save_path)

func _on_MainMenuMusic_pressed():
	config.set_value("Settings", "mainMenuMusic", $GridContainer/MainMenuMusic.pressed)
	config.save(save_path)
	get_parent().update_MainMenuMusic()

func _on_Back_pressed():
	hide()
	get_node("../MenuBackground").hide()
	get_node("../Front").show()






func _on_Language_item_selected(index):
	config.set_value("Settings", "language", $GridContainer/Language.get_item_text(index))
	TranslationServer.set_locale($GridContainer/Language.get_item_text(index))
	config.save(save_path)

func updateLanguage():
	## Get all languages, and add MainMenu* and Ingame* to Libre TrainSim
	var language_files = {"Array": []}
	Root.crawl_directory("res://", language_files, "translation")
	var languages = []
	for language_file in language_files["Array"]:
		if language_file.get_file().begins_with("MainMenu") or language_file.get_file().begins_with("Ingame"):
			TranslationServer.add_translation(load(language_file))
			print("Added " + str(language_file))
		var language = language_file.get_file().rsplit(".")[1]
		if not languages.has(language):
			languages.append(language)
	print("Found Languages: " + str(languages))
	languages.sort()
	language_table.clear()
	var i = 0
	for language in languages:
		language_table[language] = i
		i += 1

	## Update&Set Language
	for index in range(language_table.size()):
		$GridContainer/Language.add_item("",index)
	for language in language_table.keys():
		$GridContainer/Language.set_item_text(language_table[language], language)

	var language = config.get_value("Settings", "language", TranslationServer.get_locale().rsplit("_")[0])
	if language == null:
		language = TranslationServer.get_locale()
		if not language_table.has(language):
			language = "en"
	$GridContainer/Language.select(language_table[language])
	TranslationServer.set_locale(language)
