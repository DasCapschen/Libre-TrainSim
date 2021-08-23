extends Node3D

@export  var walking_speed = 1.5

var attached_station
var attached_wagon
var attached_seat
var assigned_door
var is_destination_seat = false

var transition_to_wagon = false
var transition_to_station = false

# TODO: this variable is unused?
var status = PersonState.WALKING

var destination_pos = []

func _ready():
	walking_speed = randf_range(walking_speed, walking_speed+0.3)

func _process(delta):
	handle_walk(delta)

var leave_wagon_timer = 0
func handle_walk(delta):
	
	# If Doors where closed (or closing) to early, and the person is at the station..
	if transition_to_wagon == true and (attached_wagon.last_door_status & DoorState.CLOSED):
		if attached_wagon.player.current_station_node != attached_station:
			transition_to_wagon = false
			destination_pos.clear()
		else:
			status = PersonState.STOPPING
			if $VisualInstance/AnimationPlayer.current_animation != "Standing":
				$VisualInstance/AnimationPlayer.play("Standing")
	elif status == PersonState.STOPPING:
		status = PersonState.WALKING
	
	if destination_pos.size() == 0:
		if transition_to_wagon: 
			attached_station.deregister_person(self)
			attached_station = null
			transition_to_wagon = false
			attached_wagon.register_person(self, assigned_door)
			assigned_door = null
		if transition_to_station and (attached_wagon.last_door_status & DoorState.BOTH):
			leave_wagon_timer += delta
			if leave_wagon_timer > 1.8:
				leave_wagon_timer = 0
				transition_to_station = false
				leave_current_wagon()
		if is_destination_seat and position.distance_to(attached_seat.position) < 0.1:
			is_destination_seat = false
			rotation.y = attached_seat.rotation.y + deg2rad(90)
			status = PersonState.SITTING
			## Animation Sitting
			$VisualInstance/AnimationPlayer.play("Sitting")
		elif !$VisualInstance/AnimationPlayer.is_playing() and attached_seat == null:
			status = PersonState.STANDING
			$VisualInstance/AnimationPlayer.play("Standing")

		return
	
	if !$VisualInstance/AnimationPlayer.is_playing():
		status = PersonState.WALKING
		$VisualInstance/AnimationPlayer.play("Walking")
	
	if position.distance_to(destination_pos[0]) < 0.1:
		destination_pos.pop_front()
		return
	else:
		if status != PersonState.STOPPING:
			position = position.move_toward(destination_pos[0], delta*walking_speed)
			var vector_delta = destination_pos[0] - position
#			rotation.y = position.angle_to(destination_pos[0])
			if vector_delta.z != 0:
				if vector_delta.z > 0:
					rotation.y = atan(vector_delta.x/vector_delta.z)
				else:
					rotation.y = atan(vector_delta.x/vector_delta.z)+deg2rad(180)

func leave_current_wagon():
	destination_pos.append(assigned_door.to_global(Vector3(0,0,0)))
	position = to_global(Vector3(0,0,0))
	attached_wagon.deregister_person(self)
	attached_station.register_person(self)
	transition_to_station = false
	attached_wagon = null
	assigned_door = null

func despawn():
	if attached_station:
		attached_station.deregister_person(self)
	if attached_wagon:
		attached_wagon.deregister_person(self)
		
	queue_free()

func clear_destinations():
	destination_pos.clear()
