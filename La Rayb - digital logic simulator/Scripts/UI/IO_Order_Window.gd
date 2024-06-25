extends BaseWindow
class_name IOOrderWindow

static var instance: IOOrderWindow = null

@export var IO_Name_Displayer_PackedScene: PackedScene = null

@export var IC_OptionButton: OptionButton = null
@export var inputs_VBoxContainer: VBoxContainer = null
@export var outputs_VBoxContainer: VBoxContainer = null

func _ready():
	instance = self

func _on_about_to_popup() -> void:
	super()
	
	IC_OptionButton.clear()
	IC_OptionButton.select(-1)
	for ic_name in DataManagement.instance.Functions:
		if ic_name == "and" or ic_name == "or" or ic_name == "not":
			continue
		IC_OptionButton.get_popup().add_item(ic_name)
	
	free_containers()

func free_containers() -> void:
	while inputs_VBoxContainer.get_children().size():
		inputs_VBoxContainer.get_child(0).free()
	while outputs_VBoxContainer.get_children().size():
		outputs_VBoxContainer.get_child(0).free()

func refill_containers(index) -> void:
	free_containers()
	
	var functionals = DataManagement.instance.Functions[IC_OptionButton.get_item_text(index)]
	for inp_name in functionals[2]:
		var input = IO_Name_Displayer_PackedScene.instantiate()
		input.get_node("Label").text = inp_name
		inputs_VBoxContainer.add_child(input)
		input.get_node("VBoxContainer/Up Button").gui_input.connect(func(event: InputEvent): if event is InputEventMouseButton and (event as InputEventMouseButton).pressed and event.button_index == MOUSE_BUTTON_LEFT: move_IONameDisplayer(input, true, -1))
		input.get_node("VBoxContainer/Down Button").gui_input.connect(func(event: InputEvent): if event is InputEventMouseButton and (event as InputEventMouseButton).pressed and event.button_index == MOUSE_BUTTON_LEFT: move_IONameDisplayer(input, true, 1))
	var added_names: Array = []
	for tree in functionals[0]:
		var output_name = tree.function_name.A if tree.function_name is Pair else tree.function_name
		if added_names.has(output_name):
			continue
		var output = IO_Name_Displayer_PackedScene.instantiate()
		output.get_node("Label").text = output_name
		added_names.append(output_name)
		output.get_node("VBoxContainer/Up Button").gui_input.connect(func(event: InputEvent): if event is InputEventMouseButton and (event as InputEventMouseButton).pressed and event.button_index == MOUSE_BUTTON_LEFT: move_IONameDisplayer(output, false, -1))
		output.get_node("VBoxContainer/Down Button").gui_input.connect(func(event: InputEvent): if event is InputEventMouseButton and (event as InputEventMouseButton).pressed and event.button_index == MOUSE_BUTTON_LEFT: move_IONameDisplayer(output, false, 1))
		outputs_VBoxContainer.add_child(output)

func move_IONameDisplayer(IONameDisplayer, is_input: bool, dir: int) -> void:
	(inputs_VBoxContainer if is_input else outputs_VBoxContainer).move_child(IONameDisplayer, IONameDisplayer.get_index()+dir)

func apply_order() -> void:
	var f = DataManagement.instance.Functions[IC_OptionButton.get_item_text(IC_OptionButton.selected)]
	for new_idx in f[2].size():
		var old_idx: int = new_idx + 1
		while old_idx < f[2].size():
			if inputs_VBoxContainer.get_child(new_idx).get_node("Label").text == f[2][old_idx]:
				var inp_name = f[2][old_idx]
				f[2].remove_at(old_idx)
				f[2].insert(new_idx, inp_name)
				break
			old_idx += 1
	var repeated_count: int = 0
	var visited_ports: Array = []
	for ordered_idx in outputs_VBoxContainer.get_children().size():
		var ordered_name = outputs_VBoxContainer.get_child(ordered_idx).get_node("Label").text
		for unordered_idx in f[0].size():
			var unordered_name = f[0][unordered_idx].function_name
			if ordered_name == (unordered_name.A if unordered_name is Pair else unordered_name):
				if unordered_name is Pair:
					if visited_ports.has(unordered_name.A):
						repeated_count += 1
					else:
						visited_ports.append(unordered_name.A)
				var out_name = f[0][unordered_idx]
				var out_color = f[1][unordered_idx]
				f[0].remove_at(unordered_idx)
				f[0].insert(ordered_idx + repeated_count, out_name)
				f[1].remove_at(unordered_idx)
				f[1].insert(ordered_idx + repeated_count, out_color)
	
	DataManagement.instance.save_IC(IC_OptionButton.get_item_text(IC_OptionButton.selected))
	
	_on_close_requested()
