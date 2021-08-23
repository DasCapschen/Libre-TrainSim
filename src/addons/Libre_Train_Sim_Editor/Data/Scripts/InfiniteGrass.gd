@tool
extends Node3D

# Called when the node enters the scene tree for the first time.
func _ready():
	var mesh = get_tree().edited_scene_root.get_node("Grass/MultiMeshInstance3D")
	mesh.multimesh = MultiMesh.new()
	mesh.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	mesh.multimesh.mesh = PlaneMesh.new()
	mesh.multimesh.mesh.size = Vector2(2000,2000)
	mesh.multimesh.mesh.material = load("res://Resources/Basic/Materials/Grass.tres")
	mesh.multimesh.instance_count = 25
	for i in range(0,5):
		for j in range(0,5):
			var x = i-2
			var y = j-2
			mesh.multimesh.set_instance_transform(5*i+j, Transform3D(Basis(), Vector3(2000 * x, 0, 2000 * y)))
	pass # Replace with function body.
