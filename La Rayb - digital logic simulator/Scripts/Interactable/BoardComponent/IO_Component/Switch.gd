extends IO_Component
class_name Switch

var toggle_timer: float

func _init():
	toggle_timer = 0.25
	
	is_being_picked = func(point: Vector2):
		if h_width > sqrt(pow(global_position.x - point.x, 2) + pow(global_position.y - point.y, 2)):
			if toggle_timer > 0:
				toggle()
			toggle_timer = 0.25
			return true
		return false
	
	clone = func():
		var new_Switch = BoardsController.instance.switch_scene.instantiate() as Switch
		BoardsController.instance.selected_board.insert(new_Switch)
		new_Switch.pin.output_color = pin.output_color
		new_Switch.move_to(global_position)
		return new_Switch

func _ready():
	super()
		
	on_move = func():
		pin.grab_cables()
		
		for c in children:
			c.on_move.call()
	
	pin.sprite.scale = Vector2(0.08333333, 0.08333333)
	pin.radius = pin.sprite.texture.get_width() * pin.sprite.scale.x * 0.5
	pin.holder = self
	pin.gender = Joint.Gender.male
	pin.value_changed = func(_pin: Pin):
		_pin.sprite.modulate = pin.output_color if _pin.high else Color(0.1451, 0.1451, 0.1451, 1)#idle color
		for attached_cable in _pin.attached_cables:
			attached_cable.modulate = _pin.sprite.modulate
			if attached_cable.point_B:
				attached_cable.point_B.sprite.modulate = _pin.sprite.modulate
				attached_cable.point_B.set_high(_pin.high)
	
	on_changing_visibility = func(ancestor: BoardComponentInterface):
		if ancestor != interface:
			interface.unvisible_ancestors += -1 if ancestor.visibility else 1
		
		interface.visibilityIcon.modulate = Color.WHITE if not interface.unvisible_ancestors else Color.DIM_GRAY
		
		for cable in pin.attached_cables:
			cable.visible = not interface.unvisible_ancestors and visible and not cable.point_B.holder.interface.unvisible_ancestors and cable.point_B.holder.visible
		
		for child in children:
			child.on_changing_visibility.call(ancestor)

func _process(delta):
	if toggle_timer > 0:
		toggle_timer -= delta

func toggle():
	pin.set_high(not pin.high)
