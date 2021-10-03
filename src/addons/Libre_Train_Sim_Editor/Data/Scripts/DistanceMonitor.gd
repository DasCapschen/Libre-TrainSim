extends Node
class_name DistanceMonitor

export (int) var _distance = 0
var _player = null
var _start_dist = 0

signal reached()

func set_distance(val):
	self._distance = val

func set_player(player):
	self._player = player

func _ready():
	self.set_process(false)

# either starts or restarts the monitoring
func start():
	if _player == null:
		printerr("DistanceMonitor: Need to set_player() before calling start()!")
		return
	self._start_dist = _player.distance
	self.set_process(true)

func stop():
	self.set_process(false)

func _process(delta):
	if _player.distance > _start_dist + _distance:
		emit_signal("reached")
		stop()
