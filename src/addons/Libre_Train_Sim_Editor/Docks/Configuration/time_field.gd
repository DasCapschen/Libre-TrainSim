tool
extends Control
class_name TimeField

func _ready():
	pass # Replace with function body.


func get_data():
	return [$Popup/HBoxContainer/H.value, $Popup/HBoxContainer/M.value, $Popup/HBoxContainer/S.value]
	
func set_data(time_array : Array):
	$Popup/HBoxContainer/H.value = time_array[0]
	$Popup/HBoxContainer/M.value = time_array[1]
	$Popup/HBoxContainer/S.value = time_array[2]
	update_button_text()
	


func _on_TimeButton_pressed():
	$Popup.popup_centered_minsize()

func update_button_text():
	$TimeButton.text = Math.time_to_string(get_data())

func _on_Okay_pressed():
	update_button_text()
	$Popup.hide()
