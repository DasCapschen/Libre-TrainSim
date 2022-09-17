extends Node

class Biarc:
	var start_pos: Vector3
	var length: float
	var radius: float


func convert_bezier_to_arc(bezier: Curve3D) -> Array:
	var current_bezier = null
	var next_bezier = bezier

	var biarcs = []

	while next_bezier != null:
		current_bezier = next_bezier
		next_bezier = null

		var curves = split_at_curvature_change(current_bezier)
		if len(curves) > 1:
			next_bezier = curves[1]
		current_bezier = curves[0]

		while current_bezier != null:
			# step 3
			var angle = estimate_biarc_angle(current_bezier)
			if angle <= deg2rad(90):
				biarcs.append(calculate_biarc(current_bezier))  # step 6
				current_bezier = null

			# step 4
			elif angle <= deg2rad(180):
				curves = split_into_equal_parts(bezier)  # step 4
				biarcs.append(calculate_biarc(curves[0]))  # step 6
				biarcs.append(calculate_biarc(curves[1]))  # step 8
				current_bezier = null

			# step 5
			else:
				curves = split_off_90deg_segment(bezier)
				biarcs.append(calculate_biarc(curves[0]))  # step 6
				current_bezier = curves[1]  # step 7
	return biarcs


func split_at_curvature_change(bezier: Curve3D) -> Array:
	return []

func estimate_biarc_angle(bezier: Curve3D) -> float:
	return 0.0

func split_into_equal_parts(bezier: Curve3D) -> Array:
	return []

func split_off_90deg_segment(bezier: Curve3D) -> Array:
	return []

func calculate_biarc(bezier: Curve3D) -> Biarc:
	var start_pos = bezier.get_point_position(0)
	var end_pos = bezier.get_point_position(bezier.get_point_count()-1)

	var start_tangent = bezier.get_point_out(0) - start_pos
	var end_tangent = bezier.get_point_in(bezier.get_point_count()-1) - end_pos

	var V = find_line_intersection(start_pos, start_tangent, end_pos, end_tangent)
	var G = find_incentre_point(start_pos, end_pos, V)

	var biarc = Biarc.new()
	biarc.start_pos = start_pos
	biarc.length = 0
	biarc.radius = 0

	return biarc


func find_line_intersection(pos1, dir1, pos2, dir2) -> Vector3:
	var x1 = pos1.x
	var x2 = pos1.x + dir1.x
	var x3 = pos2.x
	var x4 = pos2.x + dir2.x
	var z1 = pos1.z
	var z2 = pos1.z + dir1.z
	var z3 = pos2.z
	var z4 = pos2.z + dir2.z

	var div = dir1.x * dir2.z - dir1.z * dir2.x
	var x = (dir1.x * (x3*z4 - z3*x4) - dir2.x * (x1*z2 - z1*x2)) / div
	var z = (dir1.z * (x3*z4 - z3*x4) - dir2.z * (x1*z2 - z1*x2)) / div

	return Vector3(x, 0, z)


func find_incentre_point(a, b, c):
	pass
