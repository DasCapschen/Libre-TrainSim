extends Node3D

var world_pos ## Only updated by the player in function send_door_positions_to_current_station()

func _ready():
	$MeshInstance3D.queue_free()
