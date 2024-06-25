extends IO_Component
class_name LED

func _ready():
	super()
	
	if not BoardsController.instance.selected_board.LEDs.size():
		MainMenuStrip.instance.can_convert_board_into_IC(true)
	
	BoardsController.instance.selected_board.LEDs.append(self)
	
	pin.gender = Joint.Gender.female
	pin.holder = self
	pin.value_changed = func(p):sprite.modulate=p.sprite.modulate
	
	is_being_picked = func(point: Vector2):
		return h_width > sqrt(pow(global_position.x - point.x, 2) + pow(global_position.y - point.y, 2))

	on_move = func():
		pin.grab_cables()
		
		for c in children:
			c.on_move.call()
	
	clone = func():
		var new_LED = BoardsController.instance.LED_scene.instantiate() as LED
		BoardsController.instance.selected_board.insert(new_LED)
		new_LED.move_to(global_position)
		return new_LED
	
	on_changing_visibility = func(ancestor: BoardComponentInterface):
		if ancestor != interface:
			interface.unvisible_ancestors += -1 if ancestor.visibility else 1
		
		interface.visibilityIcon.modulate = Color.WHITE if not interface.unvisible_ancestors else Color.DIM_GRAY
		
		if pin.attached_cables.size():
			pin.attached_cables[0].visible = not interface.unvisible_ancestors and visible and not pin.attached_cables[0].point_A.holder.interface.unvisible_ancestors and pin.attached_cables[0].point_A.holder.visible
		
		for child in children:
			child.on_changing_visibility.call(ancestor)

func destructor() -> void:
	super.destructor()
	
	if BoardsController.instance.selected_board.LEDs.size() == 1:
		MainMenuStrip.instance.can_convert_board_into_IC(false)
	
	BoardsController.instance.selected_board.LEDs.erase(self)
