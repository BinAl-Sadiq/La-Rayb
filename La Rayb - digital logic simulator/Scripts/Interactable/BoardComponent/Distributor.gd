extends BoardComponent
class_name Distributor

var inputs: Array[Joint] = []
var outputs: Array[Joint] = []
var inputs_lines: Array[Line2D] = []
var outputs_lines: Array[Line2D] = []
var linkers: Dictionary = {}

@onready var linker_x_offset: float = $Sprite2D.texture.get_width() * $Sprite2D.scale.x * (0.5 + 0.4)
const linker_y_offset: float = 30.0 + 5.0 #30.0 is the width of the port.

func _init():
	create_label.call_deferred()
	
	is_being_picked = func(point: Vector2):
		return global_position.x + h_width > point.x and global_position.x - h_width < point.x and global_position.y + h_height > point.y and global_position.y - h_height < point.y
	
	pick = func():
		if not is_picked:
			is_picked = true
			var h = BoardsController.instance.highlighterSquare_scene.instantiate() as Sprite2D
			add_child(h)
			h.scale = Vector2(h_width, h_height) * 2.0 / h.texture.get_size()
			BoardsController.instance.selected_board.picked_interactables.push_back(self)
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
	
	reoffset_label = func():
		free_label.position.x = -free_label.size.x/2
		free_label.position.y = h_width + 4
	
	clone = func():
		var new_Distributor = BoardsController.instance.distributor_scene.instantiate() as Distributor
		BoardsController.instance.selected_board.insert(new_Distributor)
		new_Distributor.sprite.modulate = sprite.modulate
		for input in inputs:
			var new_input: Joint = new_Distributor.add_joint(input.gender, input is Pin)
			new_Distributor.rename_joint(new_input, input.name)
			if new_input is Port:
				new_input.rescale_buffer(input.values_buffer.size())
		for output in outputs:
			var new_output: Joint = new_Distributor.add_joint(output.gender, output is Pin)
			new_Distributor.rename_joint(new_output, output.name)
			if new_output is Pin:
				new_output.output_color = output.output_color
			else:
				new_output.rescale_buffer(output.values_buffer.size())
		for key in linkers:
			var output: Joint = new_Distributor.get_output_by_name(key.name)
			var linker = linkers[key]
			if linker is Pair:
				new_Distributor.linkers[output] = Pair.new(new_Distributor.get_input_by_name(linker.A.name), linker.B)
			elif linker is Array:#linker is Array[Pair or null]
				var index: int = 0
				var arr = []
				arr.resize(linker.size())
				while index < linker.size():
					arr[index] = Pair.new(new_Distributor.get_input_by_name(linker[index].A.name), linker[index].B) if linker[index] else null
					index += 1
				new_Distributor.linkers[output] = arr
			else:#linker is null
				new_Distributor.linkers[output] = null
		new_Distributor.move_to(global_position)
		return new_Distributor
	
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

func _process(delta):
	sprite.rotation += 0.75 * delta

func add_joint(gender: Joint.Gender, is_pin: bool) -> Joint:
	var joint = (BoardsController.instance.pin_scene if is_pin else BoardsController.instance.port_scene).instantiate() as Joint
	add_child(joint)
	joint.holder = self
	var new_line = Line2D.new()
	new_line.modulate = Color(0.1451, 0.1451, 0.1451, 1)
	$"Lines Holder".add_child(new_line)
	joint.gender = gender
	if gender == Joint.Gender.male:
		if joint is Pin:
			joint.name = "Output " + str(outputs.size())
			linkers[joint] = null
			joint.value_changed = func(pin: Pin):
				pin.sprite.modulate = pin.output_color if pin.high else Color(0.1451, 0.1451, 0.1451, 1)#idle color
				for attached_wire in pin.attached_cables:
					attached_wire.modulate = pin.sprite.modulate
					attached_wire.point_B.sprite.modulate = pin.sprite.modulate
					attached_wire.point_B.set_high(pin.high)
		else:
			joint.name = "$Output " + str(outputs.size()) + "$"
			linkers[joint] = [null]
			joint.value_changed  = func(port: Port):
				port.send_values()
		outputs.append(joint)
		outputs_lines.append(new_line)
		joint.reoffset_label = func():
			joint.free_label.position.x = joint.radius
			joint.free_label.position.y = -joint.free_label.size.y/2
	else:
		if joint is Pin:
			joint.name = "Input " + str(inputs.size())
		else:
			joint.name = "$Input " + str(inputs.size()) + "$"
		inputs.append(joint)
		inputs_lines.append(new_line)
		joint.value_changed = func(p): got_new_input_value(p)
		joint.reoffset_label = func():
			joint.free_label.position.x = -joint.radius - joint.free_label.size.x
			joint.free_label.position.y = -joint.free_label.size.y/2
	joint.create_label()
	
	reset_lines()
	return joint

func remove_joint(joint: Joint) -> void:
	if joint.gender == Joint.Gender.male:
		var idx: int = outputs.find(joint)
		outputs_lines[idx].free()
		outputs_lines.remove_at(idx)
		outputs.remove_at(idx)
		linkers.erase(joint)
	else:
		var idx: int = inputs.find(joint)
		inputs_lines[idx].free()
		inputs_lines.remove_at(idx)
		inputs.remove_at(idx)
		for key in outputs:
			if key is Pin:
				if linkers[key] and linkers[key].A.name == joint.name:
					linkers[key] = null
			else:
				for val in linkers[key]:
					if val and val.A.name == joint.name:
						linkers[key][linkers[key].find(val)] = null
	joint.detach.call()
	joint.destructor()
	joint.free()
	reset_lines()

func reset_lines() -> void:
	var inputs_starting_point: float = -linker_y_offset * (inputs.size() - 1) * 0.5
	var oututs_starting_point: float = -linker_y_offset * (outputs.size() - 1) * 0.5
	var counter: int = 0
	var curve: Curve2D = Curve2D.new()
	while counter < inputs.size():
		curve.clear_points()
		inputs[counter].position.x = -linker_x_offset
		inputs[counter].position.y = inputs_starting_point + linker_y_offset * counter
		curve.add_point(Vector2.ZERO)
		curve.add_point(Vector2(-h_width, inputs[counter].position.y))
		curve.add_point(Vector2(-linker_x_offset, inputs[counter].position.y))
		var dir = curve.get_point_position(0).direction_to(curve.get_point_position(2))*10
		curve.set_point_in(1, -dir)
		curve.set_point_out(1, dir)
		var baked_points = curve.get_baked_points()
		inputs_lines[counter].clear_points()
		for p in baked_points:
			inputs_lines[counter].add_point(p)
		counter += 1
	counter = 0
	while counter < outputs.size():
		curve.clear_points()
		outputs[counter].position.x = linker_x_offset
		outputs[counter].position.y = oututs_starting_point + linker_y_offset * counter
		curve.add_point(Vector2.ZERO)
		curve.add_point(Vector2(h_width, outputs[counter].position.y))
		curve.add_point(Vector2(linker_x_offset, outputs[counter].position.y))
		var dir = curve.get_point_position(0).direction_to(curve.get_point_position(2))*10
		curve.set_point_in(1, -dir)
		curve.set_point_out(1, dir)
		var baked_points = curve.get_baked_points()
		outputs_lines[counter].clear_points()
		for p in baked_points:
			outputs_lines[counter].add_point(p)
		counter += 1
	on_move.call()# to grab attached cables

func link(output: Joint, input_name: String, at: int = 0) -> void:
	var raw_name: String = input_name.left(input_name.find("$", 1)+1) if input_name.contains("$") else input_name
	var pair: Pair
	for inp in inputs:
		if raw_name == inp.name:
			if inp is Pin:
				pair = Pair.new(inp, null)
			else:
				pair = Pair.new(inp, int(input_name.get_slice("$", 2)))
			break
	if output is Pin:
		linkers[output] = pair
	else:
		linkers[output][at] = pair
	
	got_new_input_value(pair.A)

func got_new_input_value(input: Joint) -> void:
	for output in outputs:
		if output is Pin:
			var pair: Pair = linkers[output]
			if pair and pair.A.name == input.name:
				if input is Pin:
					output.set_high(input.high)
				else:
					output.set_high(input.values_buffer[pair.B])
		else:
			var links: Array = linkers[output]
			for index in links.size():
				if links[index] and links[index].A.name == input.name:
					if input is Pin:
						output.set_value(index, input.high)
					else:
						output.set_value(index, input.values_buffer[links[index].B])

func rename_joint(joint: Joint, new_name: String) -> bool:
	if new_name == joint.name:
		return false
	elif not new_name.length():
		Utilities.instance.trigger_error_msbox("The name cannot be empty!")
		return false
	elif joint is Pin and new_name.contains("$"):
		Utilities.instance.trigger_error_msbox("Pin cannot contain $ in its name!")
		return false
	elif joint is Port and (new_name.left(1) != "$" or new_name.right(1) != "$" or new_name.count("$") != 2):
		Utilities.instance.trigger_error_msbox("The name must be like the following format: $new name$")
		return false
	for inp in inputs:
		if new_name == inp.name:
			Utilities.instance.trigger_error_msbox("This distributor has another joint with this name!")
			return false
	for out in outputs:
		if new_name == out.name:
			Utilities.instance.trigger_error_msbox("This distributor has another joint with this name!")
			return false
	joint.name = new_name
	return true

func set_component_name(new_name: String) -> void:
	if new_name.contains("$"):
		Utilities.instance.trigger_error_msbox("Distributor cannot contain $ in its name!")
	else:
		name = new_name
		interface.label.text = name

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
