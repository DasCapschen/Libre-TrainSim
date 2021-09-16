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
	DISABLED =    0b0000_0000, # 0
	IDLE =        0b0000_0001  # 1
	MONITORING =  0b0000_0010, # 2
	RESTRICTIVE = 0b0000_0100, # 4
	EMERGENCY =   0b0000_1000  # 8
	MASK_MODE =   0b0000_1111,
	_HIDDEN =     0b0001_0000, # 16
	_500Hz =      0b0010_0000, # 32
	_1000Hz =     0b0100_0000, # 64
	_2000Hz =     0b1000_0000, # 128
	MASK_MAGNET = 0b1111_0000
}
var pzb_mode = PZBMode.IDLE setget set_mode
var pzb_speed_limit setget set_speed_limit  # no speed limit

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
	if pzb_speed_limit == null:
		pzb_speed_limit = 1000
	# TODO:
	#   check settings, if pzb disabled in difficulty settings, stop.
	#   connect "settings changed" signal, then re-check if pzb is on
	#   in case the player toggles it in the pause-menu options menu


func _on_settings_changed():
	# TODO: see _ready()
	pass

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
	pzb_speed_limit = player.currentSpeedLimit
	monitored_signal = null
	release_emergency_brakes()
	emit_signal("pzb_changed", self)


func _process(delta: float) -> void:
	if player.speed > pzb_speed_limit:
		#send_message(tr("PZB_OVER_SPEED_LIMIT"))
		emergency_brake()
	
	if player.speed > 0 and player.speed < Math.kmHToSpeed(10):
		if $RestrictiveTimer.is_stopped() and not (pzb_mode & PZBMode.RESTRICTIVE):
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
		if not (pzb_mode & (PZBMode._1000Hz | PZBMode._500Hz | PZBMode.EMERGENCY)) \
		or (pzb_mode == PZBMode.EMERGENCY and player.speed == 0):
			pzb_reset()
	
	if Input.is_action_just_pressed("pzb_command"):
		jAudioManager.play_game_sound("res://Resources/Basic/Sounds/click.ogg")


# TODO: won't work if you are in restrictive mode and then drive over a 1000hz magnet
# god this system is annoying...
func mode_1000hz():
	var was_already_monitoring = pzb_mode & (PZBMode.MONITORING | PZBMode.RESTRICTIVE)

	# 1000 Hz magnet ALWAYS resets to Monitoring 1000Hz!!
	pzb_mode = PZBMode.MONITORING | PZBMode._1000Hz
	emit_signal("pzb_changed", self)

	$"700mMonitor".start()
	$"1250mMonitor".start() # if monitoring was on before, 1250m RESETS!!

	# if monitoring was on before (ie 2x 1000Hz magnet within 1250m)
	# then we SKIP the 23 seconds timer!
	if not was_already_monitoring:
		# the false is important, it prevents the timer from running when the game is paused
		yield( get_tree().create_timer(23, false), "timeout" )
	set_speed_limit(Math.kmHToSpeed(85))


func mode_500hz():
	if pzb_mode == PZBMode.IDLE:
		send_message(tr("PZB_ILLEGAL_FREE"))
		emergency_brake()
	elif not (pzb_mode & PZBMode.EMERGENCY):
		if player.speed > Math.kmHToSpeed(65):
			send_message(tr("PZB_FAST_500HZ"))
			emergency_brake()

		pzb_mode &= ~PZBMode.MASK_MAGNET  # disable any magnet info
		pzb_mode |= PZBMode._500Hz  # enable 500Hz
		$"153mMonitor".start()

		emit_signal("pzb_changed", self)


# TODO: trigger restrictive mode when reverser is set to forward
#       this is the so called "start program"
func restrictive_mode():
	pzb_mode &= ~PZBMode.MASK_MODE   # disable current mode
	pzb_mode |= PZBMode.RESTRICTIVE  # enable restrictive

	# set speed limit
	if pzb_mode & PZBMode._500Hz:
		pzb_speed_limit = Math.kmHToSpeed(25)
	else:
		pzb_speed_limit = Math.kmHToSpeed(45)

	# start mode is equal to RESTRICTIVE_HIDDEN (ie. 1000Hz mode after 700m)
	# this means it deactivates after 550 meters
	if (pzb_mode & PZBMode.MASK_MAGNET) == 0:  # if no magnet is active
		$"1250mMonitor".start()
		$"1250mMonitor"._start_dist = player.distance - 700
	
	emit_signal("pzb_changed", self)


func _on_passed_signal(signal_instance) -> void:
	if signal_instance.type == "PZBMagnet" and signal_instance.is_active:
		monitored_signal = signal_instance.attached_signal
		match signal_instance.hz:
			1000:
				$AckTimer.start()
			500:
				mode_500hz()
			2000:
				send_message(tr("PZB_PASSED_2000HZ"))
				emergency_brake()


func emergency_brake():
	pzb_mode = PZBMode.EMERGENCY
	enable_emergency_brakes()
	emit_signal("pzb_changed", self)


func _on_153m_reached():
	if not pzb_mode & PZBMode._500Hz:
		return
	if pzb_mode & PZBMode.MONITORING:
		set_speed_limit(Math.kmHToSpeed(45))
	elif pzb_mode & PZBMode.RESTRICTIVE:
		set_speed_limit(Math.kmHToSpeed(25))

func _on_700m_reached():
	if not pzb_mode & PZBMode._1000Hz:
		return
	pzb_mode &= ~PZBMode._1000Hz  # disable 1000Hz
	pzb_mode |= PZBMode._HIDDEN   # enable hidden
	emit_signal("pzb_changed", self)

func _on_1250m_reached():
	if pzb_mode != PZBMode.EMERGENCY:
		pzb_reset()

func send_message(msg):
	player.send_message(msg)
