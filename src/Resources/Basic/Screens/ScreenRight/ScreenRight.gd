extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	$Table/Arrival/Label.text = " " + str(TranslationServer.translate("ARRIVAL:")) + " "
	$Table/Departure/Label.text = " " + str(TranslationServer.translate("DEPARTURE:")) + " "
	$Table/Station/Label.text = " " + str(TranslationServer.translate("STATION:")) + " "
	pass # Replace with function body.

func update_display(arrivals, departures, station_names, stop_types, passed, is_in_station):
	$CurrentStation.visible = is_in_station
	var arr_string = ""
	var dep_string = ""
	var sta_string = ""
	for i in range (0, station_names.size()):
		if passed[i]: continue
		
		if stop_types[i] == StopType.PASS or stop_types[i] == StopType.BEGIN:
			arr_string += "\n"
		else:
			arr_string += Math.time_to_string(arrivals[i]) + "\n"
		
		if stop_types[i] == StopType.END:
			dep_string += "\n"
		else:
			dep_string += Math.time_to_string(departures[i]) + "\n"
			
		sta_string += station_names[i] + "\n"
	
	$Table/Arrival/Label2.text = arr_string
	$Table/Departure/Label2.text = dep_string
	$Table/Station/Label2.text = sta_string

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
