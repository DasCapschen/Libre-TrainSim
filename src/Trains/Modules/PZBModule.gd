extends SecuritySystem

# TODO: completely rework this
#       1) add actual magnet "signals" to the rail system
#       2) add "distance timers" that run in the bg and send a "timeout" after x meters

# freeing from restrictive or non restrictive mode and passing a 1000Hz magnet
# resets the 1250 meters of the 1000Hz monitoring
# passing a 500 Hz magnet will cause emergency braking

# 1000 Hz monitoring "hides" after 700m, but stays active until 1250m
# this means you can free after 700m, but monitoring stays
# if you free after 700m, you *CAN* go over 85km/h ; the 1250m monitoring STILL RUNS!!!
# passing an *ACTIVE* 500Hz magnet in those 1250m will:
# - if not freed: enable 500Hz mode
# - if freed: emergency brakes
# - if 500 Hz magnet is inactive: nothing happens
# passing an active 1000Hz magnet within those 1250m (no matter if freed or not) will:
# - reset the 1250 meter monitoring
# - immediately monitor for 85km/h (or 70, or 55, see pzb_type)

enum PZBType {
	HEAVY_FREIGHT = 55, # not yet coded
	LIGHT_FREIGHT = 70, # not yet coded
	PASSENGER = 85
}
var pzb_type = PZBType.PASSENGER setget set_type

enum PZBMode {
	DISABLED,
	IDLE,
	MONITORING,
	RESTRICTIVE,
	EMERGENCY
}
var pzb_mode = PZBMode.IDLE setget set_mode
var pzb_magnet = 0 setget set_magnet
var pzb_speed_limit setget set_speed_limit  # no speed limit
var distance_magnet_start = -1

var monitored_signal = null

# passing the module so that the connected node can get all information it wants
# most likely only needs mode and magnet, but maybe wants speed_limit as well!
signal pzb_changed(pzb_module)

var player
func _ready():
	player = find_parent("Player")
	$"153mMonitor".set_player(player)
	$"700mMonitor".set_player(player)
	$"1250mMonitor".set_player(player)
	pzb_reset()
	# TODO:
	#   check settings, if pzb disabled in difficulty settings, stop.
	#   connect "settings changed" signal, then re-check if pzb is on
	#   in case the player toggles it in the pause-menu options menu


func _on_settings_changed():
	# TODO: see _ready()
	pass


func set_magnet(new_val):
	pzb_magnet = new_val
	emit_signal("pzb_changed", self)

func set_mode(new_val):
	pzb_mode = new_val
	emit_signal("pzb_changed", self)

func set_type(new_val):
	pzb_type = new_val
	emit_signal("pzb_changed", self)

func set_speed_limit(new_val):
	pzb_speed_limit = new_val
	emit_signal("pzb_changed", self)

func pzb_reset():
	pzb_mode = PZBMode.IDLE
	pzb_magnet = 0
	pzb_speed_limit = player.currentSpeedLimit
	distance_magnet_start = -1
	monitored_signal = null
	player.enforced_braking = false
	emit_signal("pzb_changed", self)


func _process(delta: float) -> void:
	if player.speed > pzb_speed_limit:
		#send_message(tr("PZB_OVER_SPEED_LIMIT"))
		emergency_brake()
	
	if pzb_mode == PZBMode.MONITORING:
		if pzb_magnet == 0:
			# TODO: handle 500Hz activation differently, 250m before signal
			if player.distance - distance_magnet_start >= 750:
				mode_500hz()
	
	if player.speed > 0 and player.speed < 10:
		$RestrictiveTimer.start()
	elif not $RestrictiveTimer.is_stopped():
		$RestrictiveTimer.stop()


func _unhandled_key_input(event: InputEventKey) -> void:
	if Input.is_action_just_pressed("pzb_ack"):
		jAudioManager.play_game_sound("res://Resources/Basic/Sounds/click.ogg")
	
	# you can hold down the ack button before the signal and still trigger it :)
	if Input.is_action_just_released("pzb_ack"):
		jAudioManager.play_game_sound("res://Resources/Basic/Sounds/click.ogg")
		if not $AckTimer.is_stopped():
			$AckTimer.stop()
			mode_1000hz()
	
	if Input.is_action_just_pressed("pzb_free"):
		jAudioManager.play_game_sound("res://Resources/Basic/Sounds/click.ogg")
		if (pzb_mode == PZBMode.MONITORING and pzb_magnet == 0) \
		or (pzb_mode == PZBMode.RESTRICTIVE and pzb_magnet == 0) \
		or (pzb_mode == PZBMode.EMERGENCY and player.speed == 0):
			pzb_reset()
	
	if Input.is_action_just_pressed("pzb_command"):
		jAudioManager.play_game_sound("res://Resources/Basic/Sounds/click.ogg")


# TODO: won't work if you are in restrictive mode and then drive over a 1000hz magnet
# god this system is annoying...
func mode_1000hz():
	pzb_mode = PZBMode.MONITORING
	pzb_magnet = 1000
	distance_magnet_start = player.distance
	emit_signal("pzb_changed", self)

	$"700mMonitor".start()
	$"1250mMonitor".start()

	yield( get_tree().create_timer(23), "timeout" )
	set_speed_limit(85)

func mode_500hz():
	# 500 Hz is inactive for green / orange signals
	# BUT it is active if it signals a speed <= 30 km/h
	if monitored_signal.status != SignalStatus.RED \
	and (monitored_signal.speed < 0 or monitored_signal.speed > 30):
		return

	# make sure 1000Hz mode is properly over
	$"153mMonitor".start()

	if pzb_mode == PZBMode.IDLE:
		#send_message(tr("PZB_ILLEGAL_FREE"))
		emergency_brake()
	else:
		if player.speed > 65:
			#send_message(tr("PZB_FAST_500HZ"))
			emergency_brake()
		pzb_magnet = 500
		distance_magnet_start = player.distance
		emit_signal("pzb_changed", self)


# TODO: trigger restrictive mode when reverser is set to forward
#       this is the so called "start program"
func restrictive_mode():
	distance_magnet_start = player.distance
	pzb_mode = PZBMode.RESTRICTIVE
	if pzb_magnet == 500:
		pzb_speed_limit = 25
	else:
		pzb_speed_limit = 45

	# if startup_mode:
	#    $"550mMonitor".start()

	emit_signal("pzb_changed", self)


func _on_passed_signal(signal_instance) -> void:
	if signal_instance.type == "Signal":
		if signal_instance.status == SignalStatus.RED and not Input.is_action_pressed("pzb_command"):
			#send_message(tr("PZB_PASSED_2000HZ"))
			emergency_brake()
		if signal_instance.status == SignalStatus.ORANGE or signal_instance.warn_speed > 0:
			$AckTimer.start()
			monitored_signal = signal_instance
	elif signal_instance.type == "WarnSpeed":
		$AckTimer.start()
		# TODO: monitored signal??


func emergency_brake():
	pzb_magnet = 2000
	pzb_mode = PZBMode.EMERGENCY
	player.enforced_braking = true
	emit_signal("pzb_changed", self)

func _on_153m_reached():
	if pzb_mode == PZBMode.MONITORING and pzb_magnet == 500:
		set_speed_limit(45)

func _on_550m_reached():
	if pzb_mode == PZBMode.RESTRICTIVE and pzb_magnet == 0:
		pzb_reset()

func _on_700m_reached():
	if pzb_magnet == 1000:
		set_magnet(0)

func _on_1250m_reached():
	if pzb_magnet != 2000:
		pzb_reset()
