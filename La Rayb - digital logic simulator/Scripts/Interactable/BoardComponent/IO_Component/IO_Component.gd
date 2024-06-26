extends BoardComponent
class_name IO_Component

@onready var pin: Pin = $Pin

func _ready():
	BoardsController.instance.selected_board.IO_Components.append(self)
	
	create_label.call_deferred()

	pick = func():
		if not is_picked:
			is_picked = true
			select()
			var h = BoardsController.instance.highlighterSquare_scene.instantiate() as Sprite2D
			add_child(h)
			h.scale = Vector2(h_width * 2, h_width * 2) / h.texture.get_width()
			BoardsController.instance.selected_board.picked_interactables.push_back(self)

	unpick = func(_point: Vector2):
		if is_picked:
			is_picked = false
			$highlighter.free()
			deselect()
	
	detach = func():
		pin.detach.call()
	
	reoffset_label = func():
		free_label.position.x = -free_label.size.x/2
		free_label.position.y = h_width + 4
	
	super()

func destructor() -> void:
	super.destructor()
	
	BoardsController.instance.selected_board.IO_Components.erase(self)
	
	if name.contains("$"):
		var current_port: String = name.left(name.find("$", 1)+1)
		var old_name: String = name
		var after: Array[IO_Component] = []
		name = "d"
		for c in BoardsController.instance.selected_board.IO_Components:
			if c.name.contains(current_port) and c.name.substr(0) > old_name:
				after.push_back(c)
		after.sort_custom(func(a, b): return a.name.substr(0) < b.name.substr(0))
		for c in after:
			c.name = current_port + str(int(c.name.substr(c.name.find("$", 1)+1)) - 1)
			c.interface.label.text = c.name
	
	pin.destructor()

func set_component_name(new_name: String) -> void:
	for c in BoardsController.instance.selected_board.IO_Components:
		if self is LED and c is Switch or self is Switch and c is LED:
			if c.name == new_name or (new_name.contains("$") and c.name.contains(new_name)):
				Utilities.instance.trigger_error_msbox("Inputs and Outputs components cannot have the same names!")
				return
	
	if new_name.contains("$"):
		if new_name.left(1) == "$" and new_name.right(1) == "$" and new_name.count("$") == 2:
			if name.contains(new_name):
				return
			
			if name.contains("$"):
				var current_port: String = name.left(name.find("$", 1)+1)
				for c in BoardsController.instance.selected_board.IO_Components:
					if c.name.contains(current_port):
						if c.name > name:
							c.set_component_name(current_port + str(int(c.name.substr(c.name.find("$", 1)+1)) - 1))
							c.interface.label.text = c.name
				
			var current_index: int = 0
			var c_index: int = 0
			for c in  BoardsController.instance.selected_board.IO_Components:
				if c.name.contains(new_name):
					c_index = int(c.name.substr(c.name.find("$", 1)+1))
					if c_index >= current_index:
						current_index = c_index + 1
			name = new_name + str(current_index)
		else:
			Utilities.instance.trigger_error_msbox("The name must match the following format: $new name$")
			return
	else:
		var old_name: String = name
		name = new_name
		if old_name.contains("$"):
			var current_port: String = old_name.left(old_name.find("$", 1)+1)
			var after: Array[Switch] = []
			for c in BoardsController.instance.selected_board.IO_Components:
				if c.name.contains(current_port) and c.name.substr(0) > old_name:
					after.push_back(c)
			after.sort_custom(func(a, b): return a.name.substr(0) < b.name.substr(0))
			for c in after:
				c.name = current_port + str(int(c.name.substr(c.name.find("$", 1)+1)) - 1)
				c.interface.label.text = c.name
	
	interface.label.text = name
