extends BoardComponent
class_name IC

var ic_name: String = ""
@onready var label: Label = $Label

var inputs: Array[Joint] = []
var outputs: Array[Joint] = []
var original_names: Dictionary = {}

var functions_names: Array = []
var functional_stacks: Array[Array] = []
var new_status: bool = true

func _ready():
	is_being_picked = func(point: Vector2):
		return point.x > global_position.x - h_width and point.x < global_position.x + h_width and point.y > global_position.y - h_height and point.y < global_position.y + h_height
	
	pick = func():
		if not is_picked:
			is_picked = true
			BoardsController.instance.selected_board.picked_interactables.push_back(self)
			var h = BoardsController.instance.highlighterSquare_scene.instantiate() as Sprite2D
			add_child(h)
			h.scale = Vector2(sprite.texture.get_width() / h.texture.get_width(), sprite.texture.get_height() / h.texture.get_height())  * sprite.scale
			select()
	
	unpick = func(_point: Vector2):
		if is_picked:
			is_picked = false
			$"highlighter".free()
			deselect()
	
	detach = func():
		for inp in inputs:
			inp.detach.call()
		for out in outputs:
			out.detach.call()
	
	on_move = func():
		for inp in inputs:
			inp.grab_cables()
		for out in outputs:
			out.grab_cables()
		
		for c in children:
			c.on_move.call()
	
	#create functions stacks and names
	var functions_trees = DataManagement.instance.Functions[ic_name][0]
	var tree_index: int = 0
	while tree_index < functions_trees.size():
		functions_names.push_back(functions_trees[tree_index].function_name)
		functional_stacks.push_back(functions_trees[tree_index].deep_copy_to_stack())
		tree_index += 1
	
	super()
	
	set_color(DataManagement.instance.Functions[ic_name][3])
	
	attach_joints()
	
	clone = func():
		var new_IC = BoardsController.instance.ic_scene.instantiate() as IC
		new_IC.ic_name = ic_name
		BoardsController.instance.selected_board.insert(new_IC)
		new_IC.set_color(sprite.modulate)
		new_IC.move_to(global_position)
		var index: int = 0
		for inp in inputs:
			new_IC.set_input_name(index, inp.name)
			index += 1
		index = 0
		for out in outputs:
			new_IC.set_output_name(index, out.name)
			if out is Pin:
				new_IC.get_output_by_name(out.name).set_output_color(out.output_color)
		return new_IC
	
	on_changing_visibility = func(ancestor: BoardComponentInterface):
		if ancestor != interface:
			interface.unvisible_ancestors += -1 if ancestor.visibility else 1
		
		interface.visibilityIcon.modulate = Color.WHITE if not interface.unvisible_ancestors else Color.DIM_GRAY
		
		for inp in inputs:
			if inp.attached_cables.size():
				inp.attached_cables[0].visible = not interface.unvisible_ancestors and visible and not inp.attached_cables[0].point_A.holder.interface.unvisible_ancestors and inp.attached_cables[0].point_A.holder.visible
		for out in outputs:
			for cable in out.attached_cables:
				cable.visible = not interface.unvisible_ancestors and visible and not cable.point_B.holder.interface.unvisible_ancestors and cable.point_B.holder.visible
		
		for child in children:
			child.on_changing_visibility.call(ancestor)

func destructor() -> void:
	super.destructor()
	
	for inp in inputs:
		inp.destructor()
	for out in outputs:
		out.destructor()

func _process(_delta):
	trees_burner()

func attach_joints():
	var new_joint: Joint = null
	for inp_name in DataManagement.instance.Functions[ic_name][2]:
		if inp_name.contains("$"):
			new_joint = BoardsController.instance.port_scene.instantiate() as Port
			add_child(new_joint)
			new_joint.name = inp_name
			new_joint.gender = Joint.Gender.female
			new_joint.holder = self
			inputs.append(new_joint)
		else:
			new_joint = BoardsController.instance.pin_scene.instantiate() as Pin
			add_child(new_joint)
			new_joint.name = inp_name
			new_joint.gender = Joint.Gender.female
			new_joint.holder = self
			inputs.append(new_joint)
		new_joint.reoffset_label = func():
			new_joint.free_label.position.x = - new_joint.radius - new_joint.free_label.size.x
			new_joint.free_label.position.y = - new_joint.free_label.size.y/2
		new_joint.create_label()
		new_joint.value_changed = func(p): p.holder.new_status = true
		original_names[new_joint] = new_joint.name
	for idx in DataManagement.instance.Functions[ic_name][0].size():
		var functional_tree = DataManagement.instance.Functions[ic_name][0][idx]
		var functional_color = DataManagement.instance.Functions[ic_name][1][idx]
		var stack: Array[Functional_Node] = [functional_tree.root_node]
		while stack.size():
			var node = stack.pop_front() as Functional_Node
			for next in node.next_nodes:
				stack.push_back(next)
			new_joint = get_input_by_name(node.determinant)
			if node.determinant.contains("$"):
				if new_joint.values_buffer.size() <= node.value.A:
					new_joint.rescale_buffer(node.value.A+1)
				new_joint.values_buffer[node.value.A] = node.value.B
		
		if functional_tree.function_name is Pair:
			new_joint = get_output_by_name(functional_tree.function_name.A)
			if not new_joint:
				new_joint = BoardsController.instance.port_scene.instantiate() as Port
				add_child(new_joint)
				new_joint.name = functional_tree.function_name.A
				new_joint.gender = Joint.Gender.male
				new_joint.holder = self
				outputs.append(new_joint)
				new_joint.value_changed = func(port: Port):
					port.send_values()
			if new_joint.values_buffer.size() <= functional_tree.function_name.B:
				new_joint.rescale_buffer(functional_tree.function_name.B+1)
			new_joint.values_buffer[functional_tree.function_name.B] = functional_tree.root_node.value.B if functional_tree.root_node.value is Pair else functional_tree.root_node.value
		else:
			new_joint = BoardsController.instance.pin_scene.instantiate() as Pin
			add_child(new_joint)
			new_joint.name = functional_tree.function_name
			new_joint.gender = Joint.Gender.male
			new_joint.holder = self
			outputs.append(new_joint)
			new_joint.set_high.call_deferred(functional_tree.root_node.value)
			new_joint.output_color = functional_color
			new_joint.value_changed = func(pin: Pin):
				pin.sprite.modulate = pin.output_color if pin.high else Color(0.1451, 0.1451, 0.1451, 1)#idle color
				for attached_wire in pin.attached_cables:
					attached_wire.modulate = pin.sprite.modulate
					if attached_wire.point_B:
						attached_wire.point_B.sprite.modulate = pin.sprite.modulate
						attached_wire.point_B.set_high(pin.high)
		new_joint.reoffset_label = func():
			new_joint.free_label.position.x = new_joint.radius
			new_joint.free_label.position.y = - new_joint.free_label.size.y/2
		new_joint.create_label()
		original_names[new_joint] = new_joint.name

func set_color(color: Color) -> void:
	sprite.modulate = color
	label.add_theme_color_override("font_color", Color.WHITE if color.get_luminance() < 0.5 else Color.BLACK)

func rescale_ic() -> void:
	var maximum_io_width: float = 0.0
	var inputs_height: float = 0.0
	for inp in inputs:
		maximum_io_width = max(maximum_io_width, inp.radius*2)
		inputs_height += inp.radius*2
	var outputs_height: float = 0.0
	var visited: Array = []
	for fn in functions_names:
		var out_name = fn.A if fn is Pair else fn
		if visited.has(out_name):
			continue
		visited.append(out_name)
		var out = get_output_by_name(out_name)
		maximum_io_width = max(maximum_io_width, out.radius*2)
		outputs_height += out.radius*2
	sprite.scale.y = max(inputs_height, outputs_height) / sprite.texture.get_height()# + 0.1
	sprite.scale.x = (label.get_theme_font("font").get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 25).x + maximum_io_width) / sprite.texture.get_width()
	calculate_half_width()
	calculate_half_height()

func reoffset_joints() -> void:
	var ic_width: float = h_width * 2.0
	var ic_height: float = h_height * 2.0
	var inputs_y_offset: float = ic_height / -2.0
	var outputs_y_offset: float = ic_height / -2.0
	var inputs_height = 0.0
	var outputs_height = 0.0
	var additional_offset: float = 0.0
	for inp in inputs:
		inputs_height += inp.radius*2
	for out in outputs:
		outputs_height += out.radius*2
	for inp in inputs:
		inp.position.x = ic_width/-2
		additional_offset = inp.radius
		inp.position.y = inputs_y_offset + additional_offset
		inputs_y_offset = inp.position.y + additional_offset
	for out in outputs:
		out.position.x = ic_width/2
		additional_offset = out.radius
		out.position.y = outputs_y_offset + additional_offset
		outputs_y_offset = out.position.y + additional_offset
	if inputs_height < outputs_height:
		for inp in inputs:
			inp.position.y += (outputs_height - inputs_height) * 0.5
	else:
		for out in outputs:
			out.position.y += (inputs_height - outputs_height) * 0.5

func set_component_name(new_name: String) -> void:
	if new_name.contains("$"):
		Utilities.instance.trigger_error_msbox("IC cannot contain $ in its name!")
	else:
		label.text = new_name
		interface.label.text = new_name
		
	rescale_ic()
	reoffset_joints()

func set_input_name(index: int, new_name: String):
	for input in inputs:
		if input.name == new_name:
			if inputs[index] != input:
				Utilities.instance.trigger_error_msbox("This name is already used by another input!")
			return
	
	if new_name == "*" or new_name == "|" or new_name == "!" or new_name == "^" or (inputs[index].name.contains("$") and (new_name.left(0) != "$" or new_name.right(0) != "$" or new_name.count("$") > 2)) or (not inputs[index].name.contains("$") and new_name.contains("$")):
		Utilities.instance.trigger_error_msbox("Invalid name!")
		return
	
	for stack in functional_stacks:
		for node in stack:
			if node.determinant == inputs[index].name:
				node.determinant = new_name
	
	inputs[index].name = new_name

func set_output_name(index: int, new_name: String):
	if outputs[index].name.contains("$"):
		if new_name.left(0) != "$" or new_name.right(0) != "$" or new_name.count("$") > 2:
			Utilities.instance.trigger_error_msbox("Invalid name!")
			return
		functions_names[index].A = new_name
	else:
		if new_name.contains("$"):
			Utilities.instance.trigger_error_msbox("Invalid name!")
			return
		functions_names[index] = new_name
	
	outputs[index].name = new_name

func get_input_by_name(inp_name) -> Joint:
	for joint in inputs:
		if joint.name == inp_name:
			return joint
	return null

func get_output_by_name(out_name) -> Joint:
	for joint in outputs:
		if joint.name == out_name:
			return joint
	return null

func trees_burner() -> void:
	if new_status:
		new_status = false
		var function_index: int = 0
		for stack in functional_stacks:
			var index: int = stack.size()-1
			while index >= 0:
				var current = stack[index] as Functional_Node
				
				if current.determinant == "*":
					current.value = current.next_nodes[0].get_value() and current.next_nodes[1].get_value()
				elif current.determinant == "|":
					current.value = current.next_nodes[0].get_value() or current.next_nodes[1].get_value()
				elif current.determinant == "!":
					current.value = not current.next_nodes[0].get_value()
				elif current.determinant == "^":
					pass
				elif current.value is Pair:
					current.value.B = get_input_by_name(current.determinant).values_buffer[current.value.A]
				else:
					current.value = get_input_by_name(current.determinant).high
				index += -1
			
			var output_name = functions_names[function_index]
			var func_value = functional_stacks[function_index][0].value
			if output_name is Pair:
				get_output_by_name(output_name.A).set_value(output_name.B, func_value if func_value is bool else func_value.B)
			else:
				get_output_by_name(output_name).set_high(func_value if func_value is bool else func_value.B)
			function_index += 1
