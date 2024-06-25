extends Joint
class_name Pin

var high: bool = false
var output_color: Color = Color(0.3098, 0.4863, 0.8314, 1.0)#the default high color

func _ready():
	super()
	
	BoardsController.instance.selected_board.pins.append(self)
	
	is_being_picked = func(point: Vector2):
		return radius > sqrt(pow(global_position.x - point.x, 2) + pow(global_position.y - point.y, 2))

	pick = func():
		if gender == Joint.Gender.female and attached_cables.size():
			return
		is_picked = true
		BoardsController.instance.selected_board.picked_interactables.push_back(self)
		var new_wire = BoardsController.instance.cable_scene.instantiate() as Cable
		attached_cables.append(new_wire)
		new_wire.point_A = self
		BoardsController.instance.selected_board.insert(new_wire)
		new_wire.add_new_point(global_position)
		new_wire.add_new_point(global_position)
		new_wire.modulate = sprite.modulate

	unpick = func(point: Vector2):
		is_picked = false
		var connect_with: Pin = null
		for pin in BoardsController.instance.selected_board.pins:
			if pin.radius > sqrt(pow(pin.global_position.x - point.x, 2) + pow(pin.global_position.y - point.y, 2)):
				connect_with = pin
				break
		connect_to(connect_with)

func destructor():
	super.destructor()
	
	BoardsController.instance.selected_board.pins.erase(self)

func set_high(value: bool) -> void:
	high = value
	value_changed.call(self)

func connect_to(joint: Joint, create_new_wire: bool = false) -> void:
	var new_wire: Cable
	if create_new_wire:
		new_wire = BoardsController.instance.cable_scene.instantiate() as Cable
		BoardsController.instance.selected_board.insert(new_wire)
		attached_cables.append(new_wire)
		new_wire.add_new_point()
		new_wire.add_new_point()
		new_wire.modulate = sprite.modulate
	else:
		new_wire = attached_cables.back()
	if joint and joint.gender != gender and (not joint.holder or joint.holder != holder):
		if not (joint.gender == Joint.Gender.female and joint.attached_cables.size()):
			if joint.gender == Joint.Gender.female:
				joint.sprite.modulate = new_wire.modulate
				joint.set_high(high)
				new_wire.point_A = self
				new_wire.point_B = joint
			else:
				new_wire.modulate = joint.sprite.modulate
				sprite.modulate = joint.sprite.modulate
				set_high(joint.high)
				new_wire.point_A = joint
				new_wire.point_B = self
			new_wire.move_point(0, new_wire.point_A.global_position)
			new_wire.move_point(new_wire.points_count()-1, new_wire.point_B.global_position)
			joint.attached_cables.append(new_wire)
	if new_wire.point_B == null:
		attached_cables.pop_back().free()

func set_output_color(new_color: Color) -> void:
	output_color = new_color
	if high:
		sprite.modulate = new_color
		for wire in attached_cables:
			wire.modulate = new_color
			wire.point_B.sprite.modulate = new_color
			if wire.point_B.holder is LED:
				wire.point_B.holder.sprite.modulate = new_color
