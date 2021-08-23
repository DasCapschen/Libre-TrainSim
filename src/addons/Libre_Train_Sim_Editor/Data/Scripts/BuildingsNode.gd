@tool
extends Node3D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
var update_timer = 0
func _process(delta):
	update_timer += delta
	if update_timer > 0.5:
		update_timer = 0
		var world = get_parent()
		for child in get_children():
			if child.get_children().size() != 0 and child.is_class("MeshInstance3D"):
				for child2 in child.get_children():
					print("Correcting MeshInstance3D Position in Scene Tree...")
					child.remove_child(child2)
					add_child(child2)
					child2.owner = world
					child2.position = child.position + child2.global_transform.origin
					
	pass
