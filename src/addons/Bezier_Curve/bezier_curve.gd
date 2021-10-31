class_name BezierCurve
extends Node

var A: Vector3
var B: Vector3
var C: Vector3
var D: Vector3

var _len = null setget , get_length

# TODO: figure out what this should be
# right now, this is good if we want a bezier curve
# fittet to a circle with radius 1
const CONSTANT = 0.551915024494

# up vector at all points is assumed to be (0,1,0)

static func rot2vec(rot_degrees) -> Vector3:
	return Vector3.RIGHT.rotated(Vector3.UP, deg2rad(rot_degrees))


func from_points_and_rots(a, arot, d, drot):
	var b = a + rot2vec(arot) * CONSTANT * a.distance_to(d)
	var c = d - rot2vec(drot) * CONSTANT * a.distance_to(d)
	self.A = a
	self.B = b
	self.C = c
	self.D = d


func get_point(t: float) -> Vector3:
#	var AB = lerp(A, B, t)
#	var BC = lerp(B, C, t)
#	var CD = lerp(C, D, t)
#	var ABC = lerp(AB, BC, t)
#	var BCD = lerp(BC, CD, t)
#	return lerp(ABC, BCD, t)
	var t2 = pow(t,2)
	var t3 = pow(t,3)
	return \
	  A * (  -t3 + 3*t2 - 3*t + 1) \
	+ B * ( 3*t3 - 6*t2 + 3*t) \
	+ C * (-3*t3 + 3*t2) \
	+ D * t3


func get_speed(t: float) -> Vector3:
	var t2 = pow(t,2)
	return \
	  A * (-3*t2 +  6*t - 3) \
	+ B * ( 9*t2 - 12*t + 3) \
	+ C * (-9*t2 +  6*t) \
	+ D * ( 3*t2)


func get_tangent(t: float) -> Vector3:
	return get_speed(t).normalized()


func get_normal(t: float) -> Vector3:
	return get_tangent(t).cross(Vector3.UP)


func get_accel(t: float) -> Vector3:
	return \
	  A * ( -6*t +  6) \
	+ B * ( 18*t - 12) \
	+ C * (-18*t +  6) \
	+ D * (  6*t)


func find_inflection_point():
	var a = (A.x - 3*B.x + 3*C.x - D.x)
	var b = (-2*B.x + 4*C.x - 2*D.x)
	var c = -(A.x - 3*B.x + 2*C.x)

	var d = b*b - 4*a*c
	assert( d >= 0 )
	d = sqrt(d)

	var t1 = (-b + d)/(2*a)
	var t2 = (-b - d)/(2*a)

	a = (A.z - 3*B.z + 3*C.z - D.z)
	b = (-2*B.z + 4*C.z - 2*D.z)
	c = -(A.z - 3*B.z + 2*C.z)
	d = b*b - 4*a*c
	assert( d >= 0 )
	d = sqrt(d)

	var t3 = (-b + d)/(2*a)
	var t4 = (-b - d)/(2*a)

	if t1 >= 0 and t1 <= 1:
		return t1
	elif t2 >= 0 and t2 <= 1:
		return t2
	if t3 >= 0 and t3 <= 1:
		return t3
	elif t4 >= 0 and t4 <= 1:
		return t4
	else:
		return null



func get_jerk(t: float) -> Vector3:
	return A * -6 + B * 18 + C * -18 + D * 6


func get_curvature(t: float) -> float:
	var speed = get_speed(t)
	var accel = get_accel(t)

	if speed.length_squared() < 1:
		return 0.0
	var cross = speed.cross(accel)
	return -sign(cross.y) * cross.length() / pow(speed.length(),3)


func get_curvature2d(t: float) -> float:
	var s = get_speed(t)
	var a = get_accel(t)

	var det = s.x * a.z - s.z * a.x
	var slen = sqrt(s.x * s.x + s.z * s.z)
	return det / pow(slen,3)



func get_radius(t: float) -> float:
	var curvature2d = get_curvature2d(t)
	var curvature = get_curvature(t)
	if curvature == 0:
		return 0.0
	return 1.0 / curvature2d


func get_length(from: int = 0, to: int = 100) -> float:
	var p1: Vector3 = A
	_len = 0
	for i in range(from,to+1):
		var t = i / float(to-from+1)
		var p2: Vector3 = get_point(t)
		_len += p2.distance_to(p1)
		p1 = p2
	return _len


func split_into_arc_segments():
	var radius = get_radius(0)
	var threshold = 1  # TODO

	var segments = []

	var t = find_inflection_point()
	segments.append({
		'start': get_point(0),
		'startrot': rad2deg(Vector3.RIGHT.angle_to(get_tangent(0))),
		'end': get_point(t),
		#'endrot': rad2deg(Vector3.RIGHT.angle_to(get_tangent(t)))
	})
	segments.append({
		'start': get_point(t),
		'startrot': rad2deg(Vector3.RIGHT.angle_to(get_tangent(t))),
		'end': get_point(1),
		#'endrot': rad2deg(Vector3.RIGHT.angle_to(get_tangent(1)))
	})

#	var last_t = 0
#	var segments = []
#
#	var t = 0.01
#	while t < 1.0:
#		var current_radius = get_radius(t)
#		while abs(current_radius - radius) < threshold and t < 1.0:
#			t += 0.01
#			current_radius = get_radius(t)
#		segments.append({
#			'start': get_point(last_t),
#			'startrot': rad2deg(Vector3.RIGHT.angle_to(get_tangent(last_t))),
#			'end': get_point(t),
#			'endrot': rad2deg(Vector3.RIGHT.angle_to(get_tangent(t))),
#			'length': get_length(last_t, t),
#			'radius': radius
#		})
#		radius = current_radius
#		last_t = t

	return segments
