extends Joint
class_name Port

var values_buffer: Array[bool] = [false]

func _ready():
	super()
	
	BoardsController.instance.selected_board.ports.append(self)
	
	is_being_picked = func(point: Vector2):
		return global_position.x + radius > point.x and global_position.x - radius < point.x and global_position.y + radius > point.y and global_position.y - radius < point.y

	pick = func():
		if attached_cables.size() and gender == Joint.Gender.female:
			return
		is_picked = true
		BoardsController.instance.selected_board.picked_interactables.push_back(self)
		var new_cable = BoardsController.instance.cable_scene.instantiate() as Cable
		attached_cables.append(new_cable)
		new_cable.point_A = self
		new_cable.get_node("Line2D").width = 24
		BoardsController.instance.selected_board.insert(new_cable)
		new_cable.add_new_point(global_position)
		new_cable.add_new_point(global_position)
		new_cable.modulate = sprite.modulate

	unpick = func(point: Vector2):
		is_picked = false
		var connect_with: Port = null
		for port in BoardsController.instance.selected_board.ports:
			if port.global_position.x + radius > point.x and port.global_position.x - radius < point.x and port.global_position.y + radius > point.y and port.global_position.y - radius < point.y:
				connect_with = port
				break
		connect_to(connect_with)
 
func destructor():
	super.destructor()
	
	BoardsController.instance.selected_board.ports.erase(self)

func set_value(index: int, val: bool) -> void:
	values_buffer[index] = val
	value_changed.call(self)

func set_values(val: bool) -> void:
	var i: int = 0
	while i < values_buffer.size():
		values_buffer[i] = val
		i += 1
	value_changed.call(self)

func rescale_buffer(size: int) -> void:
	values_buffer.resize(size)
	
	if holder is Distributor and gender == Gender.male:
		holder.linkers[self].resize(size)

func send_values() -> void:
	if gender == Joint.Gender.male:
		for cable in attached_cables:
			cable.point_B.values_buffer = values_buffer.duplicate()
			cable.point_B.value_changed.call(cable.point_B)

func connect_to(joint: Joint, create_new_cable: bool = false) -> void:
	var new_cable: Cable
	if create_new_cable:
		new_cable = BoardsController.instance.cable_scene.instantiate() as Cable
		BoardsController.instance.selected_board.insert(new_cable)
		new_cable.get_node("Line2D").width = 24
		new_cable.modulate = sprite.modulate
		attached_cables.append(new_cable)
		new_cable.add_new_point()
		new_cable.add_new_point()
	else:
		new_cable = attached_cables.back()
	if joint and joint.gender != gender and values_buffer.size() == joint.values_buffer.size() and (not joint.holder or joint.holder != holder):
		if not (joint.gender == Joint.Gender.female and joint.attached_cables.size()):
			if joint.gender == Joint.Gender.female:
				new_cable.point_A = self
				new_cable.point_B = joint
			else:
				sprite.modulate = joint.sprite.modulate
				new_cable.point_A = joint
				new_cable.point_B = self
			new_cable.move_point(0, new_cable.point_A.global_position)
			new_cable.move_point(new_cable.points_count()-1, new_cable.point_B.global_position)
			joint.attached_cables.append(new_cable)
			new_cable.point_A.send_values()
	if new_cable.point_B == null:
		attached_cables.pop_back().free()
