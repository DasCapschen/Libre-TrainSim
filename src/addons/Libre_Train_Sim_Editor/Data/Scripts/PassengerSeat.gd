extends Node3D

func _ready():
	$MeshInstance3D.queue_free()
	$MeshInstance2.queue_free()
