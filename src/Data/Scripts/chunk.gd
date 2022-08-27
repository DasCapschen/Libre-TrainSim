class_name Chunk
extends Spatial

export var is_empty := true
export var generate_grass := true  # set this to false when we have terrain

export var chunk_position: Vector3

# array of node names
export (Array, String) var rails := []

var default_grass_prefab = preload("res://Data/Modules/chunk_prefab_default_grass.tscn")

# see chunk_prefab.tscn
# TrackObjects are saved in global coordinates, NOT relative to the chunk!
# this is because they are attached to the Rails!
# Buildings are also stored in global coordinates
# DefaultGrass is stored relative to the chunk, we must move it to the correct global position
# thus, Chunks should always be at (0,0,0)


func _ready() -> void:
	translation = Vector3(0, 0, 0)
	if not generate_grass:
		if has_node("DefaultGrass") and is_instance_valid($DefaultGrass):
			$DefaultGrass.queue_free()
	else:
		if not has_node("DefaultGrass"):
			var default_grass = default_grass_prefab.instance()
			default_grass.name = "DefaultGrass"
			add_child(default_grass)
			default_grass.owner = self
		$DefaultGrass.translation = chunk_position * 1000  # 1000 = ChunkManager.chunk_size
		$DefaultGrass.translation.y = -0.5

	if Root.Editor:
		for building in $Buildings.get_children():
			var old_script = building.get_script()
			building.set_script(load("res://Data/Scripts/aabb_to_collider.gd"))
			building.target = NodePath(".")
			building.generate_collider()
			building.set_script(old_script)

	Root.connect("world_origin_shifted", self, "_on_world_origin_shifted")


func update():
	for obj in $TrackObjects.get_children():
		obj.update()


func _prepare_saving():
	# do NOT save world origin shift!!
	if has_node("DefaultGrass"):
		$DefaultGrass.translation = Vector3(0, 0, 0)
	$Buildings.translation = Vector3(0, 0, 0)

	# clear multimesh data, it is generated at runtime
	# saves disk space
	for obj in $TrackObjects.get_children():
		obj.multimesh = null

	for building in $Buildings.get_children():
		var node = building.find_node("SelectCollider")
		if is_instance_valid(node):
			node.queue_free()


func _on_world_origin_shifted(delta):
	if generate_grass:
		$DefaultGrass.translation += delta

	# buildings are just mesh instances, we need to shift them!
	$Buildings.translation += delta

	# FIXME: this does not actually work...
	#        it would be so nice, if we could just shift the entire chunk node
	#        instead of all the track objects,
	#        but I think that will require a TrackObject refactor
	#        ask me about it for 0.10
	#translation += delta
