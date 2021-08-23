extends Node3D

# TODO: NodePath ?
@export var connections: Array[String]

func _ready():
	$MeshInstance3D.queue_free()

