extends Node2D

var tower = null

# https://docs.godotengine.org/en/3.5/tutorials/2d/custom_drawing_in_2d.html
func draw_circle_arc():
	assert(tower != null, "must set tower before drawing")
	var radius = tower.my_stats.RANGE_RADIUS
	var nb_points = 32	
	var points_arc = PoolVector2Array()

	for i in range(nb_points + 1):
		var angle_point = deg2rad(0 + i * 360 / nb_points - 90)
		points_arc.push_back(Vector2(cos(angle_point), sin(angle_point)) * radius)
	
	var white = Color("#FFFFFF")

	draw_polygon(points_arc, PoolColorArray([white]))
	# for index_point in range(nb_points):
		# draw_line(points_arc[index_point], points_arc[index_point + 1], white)

func _draw():
	draw_circle_arc()
