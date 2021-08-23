@tool
extends MultiMeshInstance3D

@export var x = 100
@export var z = 50
@export var spacing = 4
@export var random_location: bool
@export var random_location_factor = 0.3
@export var random_rotation: bool
@export var random_scale: bool
@export var random_scale_factor = 0.2
@export var update:bool:
	set(val): _update(val)

func _ready():
	if not Engine.is_editor_hint():
		$MeshInstance3D.visible = false
	$MeshInstance3D.position = Vector3(x/2,0,z/2)
	$MeshInstance3D.scale = Vector3(x,randf_range(0,10),z)


func _update(newvar):
	## Cube For Editor:
	self.set_multimesh(self.multimesh.duplicate(false))
	self.multimesh.instance_count = int(x / spacing * z / spacing)
	var idx = 0
	for a in range(int(x / spacing)):
		for b in range(int(z / spacing)):
			var position = Vector3(a*spacing, 0, b * spacing)
			if random_location:
				var shift_x = randf_range(-spacing * random_location_factor, spacing * random_location_factor)
				var shift_z = randf_range(-spacing * random_location_factor, spacing * random_location_factor)
				position += Vector3(shift_x, 0, shift_z)
				#position = position.translated(Vector3(shift_x, 0, shift_z))
			
			var rot = 0
			if random_rotation:
				rot = randf_range(0,1)
				#position = position.rotated(Vector3(0, 1, 0), rand_range(0, 1))
				#position = Vector3(Basis().rotated(Vector3(0, 1, 0), rand_range(0, 1), position.
			var scale = Vector3(1,1,1)
			if random_scale:
				var scale_val = randf_range(1 - random_scale_factor, 1 + random_scale_factor)
				scale = Vector3(scale_val, scale_val, scale_val)
				
			self.multimesh.set_instance_transform(idx, Transform3D(Basis().rotated(Vector3(0,1,0), rot).scaled(scale), position))
			idx += 1
