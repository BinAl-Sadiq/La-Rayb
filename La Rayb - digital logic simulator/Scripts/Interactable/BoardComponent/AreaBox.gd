extends BoardComponent
class_name AreaBox

var compass: Compass = null

func _ready():
	super()
	
	compass = Compass.create(self)
	
	is_being_picked = func(point: Vector2):
		return sprite.global_position.x - h_width < point.x and sprite.global_position.x + h_width > point.x and sprite.global_position.y + h_height > point.y and sprite.global_position.y - h_height < point.y
	
	pick = func():
		if not is_picked:
			is_picked = true
			var h = BoardsController.instance.highlighterSquare_scene.instantiate() as Sprite2D
			add_child(h)
			h.position = sprite.position
			h.scale = Vector2(h_width, h_height) * 2 / h.texture.get_width()
			BoardsController.instance.selected_board.picked_interactables.push_back(self)
			select()
	
	unpick = func(_point: Vector2):
		if is_picked:
			is_picked = false
			get_node("highlighter").free()
			deselect()
	
	detach = func(): pass
	
	on_move = func():
		for c in children:
			c.on_move.call()
	
	reoffset_label = func():
		free_label.position.x = sprite.position.x + -free_label.size.x/2
		free_label.position.y = sprite.position.y + h_height + 4
	
	create_label()
	
	clone = func():
		var new_AreaBox = BoardsController.instance.areaBox_scene.instantiate() as AreaBox
		BoardsController.instance.selected_board.insert(new_AreaBox)
		new_AreaBox.set_color(sprite.modulate)
		new_AreaBox.move_to(global_position)
		return new_AreaBox
	
	on_changing_visibility = func(ancestor: BoardComponentInterface):
		if ancestor != interface:
			interface.unvisible_ancestors += -1 if ancestor.visibility else 1
		
		interface.visibilityIcon.modulate = Color.WHITE if not interface.unvisible_ancestors else Color.DIM_GRAY
		
		for child in children:
			child.on_changing_visibility.call(ancestor)

func destructor() -> void:
	super.destructor()
	
	compass.free()

func resize() -> void:
	if children.size():
		var ch = children[0]
		var left = ch.position.x - ch.h_width
		var right = ch.position.x + ch.h_width
		var up = ch.position.y - ch.h_height
		var down = ch.position.y + ch.h_height
		var offspring: Array[BoardComponent] = []
		var index: int = 1
		for child in ch.children:
			offspring.push_back(child)
		while index < children.size():
			offspring.push_back(children[index])
			index += 1
		while offspring.size():
			ch = offspring.pop_front()
			var pos = to_local(ch.global_position)
			if left > pos.x - ch.h_width:
				left = pos.x - ch.h_width
			if right < pos.x + ch.h_width:
				right = pos.x + ch.h_width
			if up > pos.y - ch.h_height:
				up = pos.y - ch.h_height
			if down < pos.y + ch.h_height:
				down = pos.y + ch.h_height
			for child in ch.children:
				offspring.push_back(child)
		sprite.scale = Vector2((right - left) / sprite.texture.get_width(), (down - up) / sprite.texture.get_height()) + Vector2(0.77, 0.77)
		sprite.position = Vector2((right + left) / 2.0, (up + down) / 2.0)
		calculate_half_width()
		calculate_half_height()
		
		reoffset_label.call()

func set_component_name(new_name: String) -> void:
	if new_name.contains("$"):
		Utilities.instance.trigger_error_msbox("An areabox cannot contain $ in its name!")
	else:
		name = new_name
		interface.label.text = name

func set_color(new_color: Color) -> void:
	sprite.modulate = new_color
	compass.modulate = Color(new_color.r, new_color.g, new_color.b, 0.5)
