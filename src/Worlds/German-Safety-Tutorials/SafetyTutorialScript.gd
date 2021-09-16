extends Node

var scenario = null
var world = null
var player = null

var message_sent = false
var send_message_timer = 0
var message = ""

var step = 0

var sifa_module
var pzb_module

var init_done = false
func init():
	scenario = Root.currentScenario
	world = find_parent("World")
	player = world.get_node("Players/Player")
	
	player.force_close_doors()
	player.force_pantograph_up()
	player.startEngine()
	
	if player != null and scenario == "Sifa":
		player.find_node("PZBModule").queue_free()
		sifa_module = player.find_node("SifaModule")
		sifa_module.set_process_unhandled_key_input(false)
	if player != null and scenario == "PZB":
		player.find_node("SifaModule").queue_free()
		pzb_module = player.find_node("PZBModule")
	
	if scenario != null and player != null and world != null:
		init_done = true


func _process(delta: float) -> void:
	if not init_done:
		init()
		return
	
	send_message(delta)
	
	if scenario == "Sifa":
		sifa()
		return
	elif scenario == "PZB":
		pzb()
		return
	
	message_sent = true


func sifa():
	match step:
		0:
			message = "Hallo, heute lernen wir, wie das Sicherheitssystem \"Sifa\" bedient wird.\nUm zu beginnen, beschleunigen Sie."
			if not sifa_module.get_node("SifaTimer").is_stopped():
				next_step()
		1:
			message = "Sie haben die Geschwindigkeit von 3km/h überschritten. Das Sifa System wurde nun aktiviert. Das System erwartet, dass Sie spätestens alle 30 Sekunden den Sifa Schalter (Leertaste) betätigen. Fahren Sie nun 30 Sekunden lang weiter."
			if sifa_module.stage == 1:
				next_step()
		2:
			message = "Die 30 Sekunden wurden erreicht. Sehen Sie den leuchtenden \"Sifa\" Schriftzug? Dieser zeigt ihnen, dass es höchste Zeit wird den Schalter zu drücken. Zu demonstatrionszwecken warten Sie noch ein paar Sekunden ab."
			if sifa_module.stage == 2:
				next_step()
		3:
			message = "Hören Sie das Warnsignal? Sie haben noch 2,5 Sekunden um den Schalter zu betätigen! Doch wir wollen sehen was passiert, wenn Sie es nicht tun."
			if sifa_module.stage == 3:
				next_step()
		4:
			message = "Jetzt hat das Sifa System die Zwangsbremsung ausgelöst, da der Sifa Schalter nicht betätigt wurde. Drücken Sie den Schalter (Leertaste) jetzt um sich SOFORT aus der Zwangsbremsung zu befreien."
			sifa_module.set_process_unhandled_key_input(true)
			if sifa_module.stage == 0:
				next_step()
		5:
			message = "Sie haben sich aus der Zwangsbremsung befreit. Beachten Sie, dass dies nur möglich ist, wenn kein anderes Sicherheitssystem eine Zwangsbremsung fordert. Das Sifa System wurde zurückgesetzt. Sie haben erneut 30 Sekunden Zeit den Schalter zu betätigen, probieren Sie es aus!\n\nTipp: Sie müssen die 30 Sekunden nicht abwarten. Das System wird immer zurückgesetzt wenn Sie den Schalter betätigen, egal wie viele Sekudnen verbleiben."
			yield( get_tree().create_timer(1), "timeout" )  # required, else 5 is skipped
			if Input.is_action_just_released("SiFa"):
				next_step()
		6:
			message = "Herzlichen Glückwunsch, damit haben Sie die Sifa Einweisung abgeschlossen!"


func pzb():
	match step:
		0:
			pass
	pass



func send_message(delta):
	send_message_timer += delta
	if not message_sent and send_message_timer > 1:
		message_sent = true
		player.show_textbox_message(message)


func next_step():
	step += 1
	message_sent = false
	send_message_timer = 0
