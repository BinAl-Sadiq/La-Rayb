extends Interactable
class_name Cable

var straight_points: PackedVector2Array = []
var selected_point_index: int = -1

var point_A: Joint = null
var point_B: Joint = null

@onready var line: Line2D = $Line2D
@onready var h_w: int = int(line.width / 2)
@onready var point_radius: int = int(line.width)

func _ready():
	super()
	
	is_being_picked = func(point: Vector2):
		return Input.is_key_pressed(KEY_CTRL) and clicked_on(point)
	pick = func(): BoardsController.instance.selected_board.picked_interactables.push_back(self)
	unpick = func(_point: Vector2): pass
	
	BoardsController.instance.selected_board.cables.push_back(self)

func _process(_delta):
	queue_redraw()

func _exit_tree():
	if point_B is Pin:
		point_B.sprite.modulate = Color(0.1451, 0.1451, 0.1451, 1)#idle color
		point_B.set_high(false)
	elif point_B is Port:
		point_B.set_values(false)
	
	super.destructor()
	
	BoardsController.instance.selected_board.cables.erase(self)

func _draw():
	if Input.is_key_pressed(KEY_CTRL):
		draw_polyline(straight_points, Color(1.0, 1.0, 1.0, 0.5), line.width, true)
		var point_index = 1
		while point_index < straight_points.size()-1:
			draw_circle(straight_points[point_index], point_radius, Color.WHITE)
			point_index += 1

func clicked_on(point) -> bool:
	var index = 1
	while index < straight_points.size():
		if index < straight_points.size()-1 and straight_points[index].distance_to(point) < point_radius:
			selected_point_index = index
			return true
		
		var left: float = straight_points[index-1].x if straight_points[index-1].x < straight_points[index].x else straight_points[index].x
		var right: float = straight_points[index-1].x if straight_points[index-1].x > straight_points[index].x else straight_points[index].x
		var top: float = straight_points[index-1].y if straight_points[index-1].y > straight_points[index].y else straight_points[index].y
		var bottom: float = straight_points[index-1].y if straight_points[index-1].y < straight_points[index].y else straight_points[index].y
		
		if point.x < left or point.x > right or point.y > top or point.y < bottom:
			index += 1
			continue
		
		var m = (straight_points[index-1].y-straight_points[index].y)/(straight_points[index-1].x-straight_points[index].x)
		var b = straight_points[index].y - m*straight_points[index].x
		
		var y1 = b if m == INF else m*point.x + b
		var x1 = 0 if m == INF else (y1-b)/m
		var x2 = 0 if m == INF else (point.y-b)/m
		var y2 = b if m == INF else m*x2 + b
		var len1: float = sqrt(pow(point.x-x1, 2)+pow(point.y-y1, 2))
		var len2: float = sqrt(pow(point.x-x2, 2)+pow(point.y-y2, 2))
		
		if h_w > min(len1, len2):
			var left_side = straight_points.slice(0, index)
			var right_side = straight_points.slice(index, straight_points.size())
			straight_points.clear()
			for p in left_side:
				straight_points.append(p)
			straight_points.append(point)
			for p in right_side:
				straight_points.append(p)
			selected_point_index = index
			make_smooth()
			return true
		
		index += 1
	
	return false

func add_new_point(point = Vector2.ZERO, index = points_count()) -> void:
	straight_points.insert(index, point)
	make_smooth()

func remove_close_point(pos) -> bool:
	var index: int = 1
	while index < straight_points.size()-1:
		if straight_points[index].distance_to(pos) < point_radius:
			straight_points.remove_at(index)
			make_smooth()
			return true
		index += 1
	return false

func move_point(point_index, pos):
	straight_points[point_index] = pos
	make_smooth()

func points_count():
	return straight_points.size()

func make_smooth() -> void:
	var curve: Curve2D = Curve2D.new()
	for p in straight_points:
		curve.add_point(p)
	
	var point_index = 1
	while point_index < straight_points.size()-1:
		var dir = curve.get_point_position(point_index-1).direction_to(curve.get_point_position(point_index+1))*30
		curve.set_point_in(point_index, -dir)
		curve.set_point_out(point_index, dir)
		point_index += 1
	
	var baked_points = curve.get_baked_points()
	line.clear_points()
	for p in baked_points:
		line.add_point(p)
