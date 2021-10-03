extends SecuritySystem

var is_sifa_enabled = true

var was_sifa_reset = false

# trigger a lamp in the trains cabin
# this is a signal, so different trains can implement it differently
signal sifa_visual_hint(is_turned_on)

var player
func _ready():
	player = find_parent("Player")
	# TODO: 
	#   check settings, if sifa disabled in difficulty settings, stop.
	#   connect "settings changed" signal, then re-check if sifa is on
	#   in case the player toggles it in the pause-menu options menu
	# is_sifa_enabled = Options.Difficulty.Sifa  # something like that
	pass


func _on_settings_changed():
	# TODO: see _ready()
	# is_sifa_enabled = Options.Difficulty.Sifa  # something like that
	pass


func _process(delta: float) -> void:
	if player.speed < 3:
		$WarningTimer.stop()
	elif $WarningTimer.is_stopped():
		$WarningTimer.start()


func _unhandled_key_input(event: InputEventKey) -> void:
	if Input.is_action_just_pressed("SiFa"):
		jAudioManager.play_game_sound("res://Resources/Basic/Sounds/click.ogg")
		$SifaTimer.start()
		$SifaSound.stop()
		emit_signal("sifa_visual_hint", false)
		was_sifa_reset = true


func _on_SifaTimer_timeout() -> void:
	emit_signal("sifa_visual_hint", true)
	$WarningTimer.start()
	was_sifa_reset = false
	
	yield( $WarningTimer, "timeout" )
	if was_sifa_reset:
		return
		
	$SifaSound.play()
	$WarningTimer.start()
	
	yield( $WarningTimer, "timeout" )
	if was_sifa_reset:
		return
	
	player.enforced_braking = true
