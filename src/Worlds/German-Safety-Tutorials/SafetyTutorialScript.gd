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
	player.enforced_braking = false
	player.command = 0
	player.soll_command = 0
	
	if player != null and scenario == "Sifa":
		player.find_node("PZBModule").queue_free()
		sifa_module = player.find_node("SifaModule")
		sifa_module.set_process_unhandled_key_input(false)
	if player != null and scenario == "PZB":
		player.speed = Math.kmHToSpeed(120)
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
		pzb(delta)
		return
	
	message_sent = true


func sifa():
	match step:
		0:
			message = "Hallo, heute lernen wir, wie das Sicherheitssystem \"Sifa\" bedient wird.\nUm zu beginnen, beschleunigen Sie."
			if not sifa_module.get_node("SifaTimer").is_stopped():
				next_step()
		1:
			message = "Sie haben die Geschwindigkeit von 3 km/h überschritten. Das Sifa System wurde nun aktiviert. Das System erwartet, dass Sie spätestens alle 30 Sekunden den Sifa Schalter (Leertaste) betätigen. Fahren Sie nun 30 Sekunden lang weiter."
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
			yield( get_tree().create_timer(1, false), "timeout" )  # required, else 5 is skipped
			if Input.is_action_just_released("SiFa"):
				next_step()
		6:
			message = "Herzlichen Glückwunsch, damit haben Sie die Sifa Einweisung abgeschlossen!"


var _sig_green_timer = 0
var _restrictive_timer = 0
func pzb(delta):
	match step:
		0:
			message = "Hallo. Heute lernen Sie, wie Sie das Sicherheitssystem PZB verwenden. Um zu beginnen fahren Sie bis zum nächsten Signal."
			var signal1 = world.get_node("Signals/Signal")
			if player.global_transform.origin.distance_to(signal1.global_transform.origin) < 100:
				next_step()
		1:
			message = "Das nächste Signal steht auf Gelb. Das bedeutet, dass es mit der \"PZB Wachsam\" Taste (Bild runter) bestätigt werden muss. Geschieht dies nicht, erfolgt eine Zwangsbremsung. Drücken und halten Sie die PZB Wachsam Taste bevor Sie am Signal vorbeifahren, und lassen Sie sie nach dem Signal los. Sie haben 4 Sekunden Zeit die Wachsam Taste zu betätien, nachdem Sie das Signal überfahren haben.\n\nFolgende Signale müssen immer bestätigt werden:\n- orangene Signale\n- Geschwindigkeitsankündigung (orangene Zahl, bzw. orangenes Schild mit schwarzer Zahl) unter 100 km/h.\n\nGrüne Signale und Geschwindigkeiten über 100 km/h müssen nicht bestätigt werden."
			if pzb_module.pzb_mode & pzb_module.PZBMode.MONITORING:
				next_step()
			elif pzb_module.pzb_mode & pzb_module.PZBMode.EMERGENCY:
				step = 100
				message_sent = false
				send_message_timer = 0
		100:
			message = "Sie haben die PZB Wachsam Taste nicht rechtzeitig betätigt und dadurch eine Zwangsbremsung ausgelöst. Bitte starten Sie die Einweisung erneut."
		2:
			message = "Sehr gut. Das PZB System befindet sich nun im Überwachungsmodus, wie an der blinkenden \"85\" zu erkennen ist. Außerdem leuchtet die 1000Hz Lampe, sie heißt so, weil sie durch den 1000Hz Magnet neben dem Signal ausgelöst wird. Die 1000Hz-Überwachung bedeutet, dass Sie innerhalb der nächstes 23 Sekunden Ihre Geschwindigkeit auf 85 km/h verringern müssen, und diese 85 km/h danach nicht mehr überschreiten dürfen. Bremsen Sie jetzt auf unter 85 km/h ab."
			if pzb_module.pzb_speed_limit == Math.kmHToSpeed(85):
				next_step()
			elif pzb_module.pzb_mode & pzb_module.PZBMode.EMERGENCY:
				step = 200
				message_sent = false
				send_message_timer = 0
		200:
			message = "Sie haben nicht schnell genug auf 85 km/h abgebremst. Bitte starten Sie die Einweisung erneut."
		3:
			message = "Sehr gut, sie haben rechtzeitig auf 85 km/h abgebremst. 700 Meter nach dem 1000Hz Magnet wird sich die 1000Hz Lampe deaktivieren. Fahren Sie bis dahin weiter."
			if pzb_module.pzb_mode & pzb_module.PZBMode._HIDDEN:
				next_step()
		4:
			message = "Die 1000Hz-Lampe ist erloschen, das beudeutet aber nicht, dass die Überwachung beendet ist. Die Überwachung läuft noch für etwa 550 Meter, also beschleunigen Sie nicht über 85 km/h. Falls Sie am nächsten Signal ein grünes Licht sehen UND die Geschwindigkeit nicht auf 30 km/h oder weniger beschränkt wird, können Sie die \"PZB Frei\" Taste (Ende) drücken. Diese beendet die Überwachung durch PZB und Sie dürfen wieder auf Höchstgeschwindigkeit beschleunigen. Eine Befreiung ist nur möglich, wenn weder die 1000Hz Lampe, noch die 500Hz Lampe leuchten. Sollten Sie sich befreien, während das nächste Signal rot oder eine Geschwindigkeit kleiner gleich 30 km/h zeigt, erfolgt eine Zwangsbremsung.\n\nIn diesem Fall zeigt das nächste Signal Rot, das bedeutet, dass Sie Ihre Geschwindigkeit auf 65 km/h reduzieren müssen, bevor Sie den 500Hz Magneten erreichen. Bremsen Sie weiter ab."
			if pzb_module.pzb_mode & pzb_module.PZBMode._500Hz:
				next_step()
		5:
			message = "Die 500Hz Lampe wurde aktiviert. Sie können sich ab sofort nicht mehr aus der PZB Überwachung befreien. Innerhalb der nächsten 153 Meter müssen Sie Ihre Geschwindigkeit auf 45 km/h reduzieren. Sollte das Signal jetzt auf grün wechseln, bleiben Sie unter 45 km/h! Die PZB Überwachung deaktiviert sich 250 Meter nach dem Signal von selbst.\n\nIn diesem Fall bleibt das Signal Rot, also müssen wir vor dem Signal anhalten. Sollten Sie ein rotes Signal überfahren, erfolgt eine Zwangsbremsung."
			if player.speed == 0:
				next_step()
		6:
			message = "Warten Sie darauf, dass das Signal auf grün umschaltet."
			_sig_green_timer += delta
			if _sig_green_timer > 5:
				world.get_node("Signals/Signal2").set_status(SignalStatus.GREEN)
				next_step()
		7:
			message = "Das Signal hat auf grün umgeschaltet. Sie können jetzt losfahren. Aber achten Sie darauf, die Geschwindigkeit von 45 km/h nicht zu überschreiten, bis sich die PZB Überwachung deaktiviert."
			if pzb_module.pzb_mode == pzb_module.PZBMode.IDLE:
				next_step()
		8:
			message = "Die PZB Überwachung wurde deaktiviert. Sie können jetzt auf die erlaubte Höchstgeschwindgikeit beschleunigen. Zu demonstrationszwecken, bremsen Sie bitte auf unter 10 km/h ab."
			if player.speed < Math.kmHToSpeed(10):
				next_step()
		9:
			player.speed = Math.kmHToSpeed(8)
			player.command = 0
			player.soll_command = 0
			message = "Jetzt gibt es noch eine Besonderheit des PZB Systems: die restriktive Überwachung. Diese wird aktiviert, wenn Sie zum ersten mal mit dem Zug abfahren, oder wenn Sie länger als 15 Sekunden lang weniger als 10 km/h fahren. Warten Sie, bis die restriktive Überwachung aktiviert wird."
			if pzb_module.pzb_mode & pzb_module.PZBMode.RESTRICTIVE:
				next_step()
		10:
			message = "Die restriktive Überwachung wurde nun aktiviert. Sie ist daran zu erkennen, dass abwechselnd die Leuchten \"85\" und \"70\" blinken. Jetzt gibt es 2 Fälle:\n- keine, oder die 1000Hz Leuchte ist aktiv: Sie dürfen 45 km/h nicht überschreiten\n- die 500Hz Leuchte ist aktiv: Sie dürfen 25 km/h nicht überschreiten.\n\nFahren Sie zunächst weiter."
			# yes, this really is necessary... yield() and _process() do not get along at all!
			_restrictive_timer += delta
			if _restrictive_timer > 5:
				next_step()
		11:
			message = "Zum Glück gibt es die Möglichkeit, sich aus der restriktiven Überwachung zu mithilfe der \"PZB Frei\" Taste zu befreien. Das funktioniert nur, wenn weder die 1000Hz Lampe, noch die 500Hz Lampe leuchten. Achten Sie aber darauf, dass innerhalb der nächsten 550 Meter keine erneute Beeinflussung vorkommt! Sollte nach der Befreiung innerhalb von 550 Metern eine 1000Hz Beeinflussing stattfinden, wird diese SOFORT auf 85 km/h überwachen, danach gilt der normale Ablauf für den 1000Hz Modus. Sollte nach der Befreiung innerhalb von 550 Metern ein aktiver 500Hz Magnet überfahren werden, so erfolgt eine Zwangsbremsung. Wenn Sie sich nicht befreien, endet der restriktive Modus nach 550 Metern automatisch.\n\nAußerdem: Wenn Sie sich nicht befreien, und über einen 1000Hz Magnet fahren, so wird die restriktive Überwachung ebenfalls beendet, und stattdessen der 1000Hz Modus und die 85 km/h Überwachung gestartet.\n\nBefreien Sie sich nun aus der restriktiven Überwachung indem Sie die \"PZB Frei\" Taste (Ende) drücken."
			if pzb_module.pzb_mode == pzb_module.PZBMode.IDLE:
				next_step()
		12:
			message = "Herzlichen Glückwunsch! Sie haben die Einweisung in das PZB Sicherheitssystem abgeschlossen!\n\nZum Schluss noch ein Hinweis: falls sie vor einem roten Signal stehen und den Befehl bekommen, an diesem vorbei zu fahren, dann halten Sie die \"PZB Befehl\" Taste (Entf) gedrückt, und fahren Sie über das Signal ohne 40 km/h zu überschreiten. Es wird KEINE Zwangsbremsung erfolgen. 250 Meter nach dem Signal deaktiviert sich PZB."



func send_message(delta):
	send_message_timer += delta
	if not message_sent and send_message_timer > 1:
		message_sent = true
		player.show_textbox_message(message)


func next_step():
	step += 1
	message_sent = false
	send_message_timer = 0
