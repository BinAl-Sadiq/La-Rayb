extends PanelContainer
class_name ComponentPropertiesDisplayer

static var instance: ComponentPropertiesDisplayer = null

@export var Inputs_Names_VBoxContainer: VBoxContainer = null
@export var Outputs_Names_VBoxContainer: VBoxContainer = null
@export var Component_Color_VBoxContainer: VBoxContainer = null
@export var Component_ColorPickerButton: ColorPickerButton = null
@export var Output_Color_VBoxContainer: VBoxContainer = null
@export var Output_ColorPickerButton: ColorPickerButton = null
@export var output_OptionButton: OptionButton = null
@export var Distributor_VBoxContainer: VBoxContainer = null
@export var Distributor_IO_VBoxContainer: VBoxContainer = null
@export var Input_pin_PanelContainer_scene: PackedScene = null
@export var Input_port_PanelContainer_scene: PackedScene = null
@export var Output_pin_PanelContainer_scene: PackedScene = null
@export var Output_port_PanelContainer_scene: PackedScene = null
@export var Clock_Rate_VBoxContainer: VBoxContainer = null
@export var Clock_Rate_Label: Label = null
@export var Clock_Rate_HSlider: HSlider = null

var displayed_component: BoardComponent = null
var input_linker_OptionButtons: Array[OptionButton] = []

func _ready():
	instance = self
	var _input_handler = InputHandler.new(self)
	Component_ColorPickerButton.popup_closed.connect(func(): grab_focus())
	Output_ColorPickerButton.popup_closed.connect(func(): grab_focus())

func _process(_delta):
	if BoardsController.instance.selected_board.picked_interactables.size() == 1 and BoardsController.instance.selected_board.picked_interactables[0] is BoardComponent:
		if BoardsController.instance.selected_board.picked_interactables[0] != displayed_component and Utilities.instance.header.visible:#not on watch mode:
			display_component_properties()
	else:
		hide_component_properties()

func display_component_properties() -> void:
		hide_component_properties()

		displayed_component = BoardsController.instance.selected_board.picked_interactables[0]
		if displayed_component is IC:
			visible = true
			Inputs_Names_VBoxContainer.visible = true
			Outputs_Names_VBoxContainer.visible = true
			Component_Color_VBoxContainer.visible = true
			Component_ColorPickerButton.color = displayed_component.sprite.modulate
			Output_Color_VBoxContainer.visible = true
			output_OptionButton.visible = true
			
			for joint in displayed_component.outputs:
				if joint is Pin:
					output_OptionButton.add_item(joint.name)
			output_OptionButton.select(0)
			_on_output_option_button_item_selected(0)
			
			Inputs_Names_VBoxContainer.get_child(1).text_submitted.connect(func(new_text: String): displayed_component.set_input_name(0, new_text))
			Inputs_Names_VBoxContainer.get_child(1).text = displayed_component.inputs[0].name
			var counter: int = 1
			while counter < displayed_component.inputs.size():
				var input = Inputs_Names_VBoxContainer.get_child(1).duplicate() as LineEdit
				Inputs_Names_VBoxContainer.add_child(input)
				input.text_submitted.connect(func(new_text: String): displayed_component.set_input_name(counter, new_text))
				input.text = displayed_component.inputs[counter].name
				counter += 1
			Outputs_Names_VBoxContainer.get_child(1).text_submitted.connect(func(new_text: String): displayed_component.set_output_name(0, new_text))
			Outputs_Names_VBoxContainer.get_child(1).text = displayed_component.outputs[0].name
			counter = 1
			while counter < displayed_component.outputs.size():
				var output = Outputs_Names_VBoxContainer.get_child(1).duplicate() as LineEdit
				Outputs_Names_VBoxContainer.add_child(output)
				output.text_submitted.connect(func(new_text: String): displayed_component.set_output_name(counter, new_text))
				output.text = displayed_component.outputs[counter].name
				counter += 1
		elif displayed_component is Switch:
			visible = true
			Output_Color_VBoxContainer.visible = true
			Output_ColorPickerButton.color = displayed_component.pin.output_color
			
			if displayed_component is Clock:
				Clock_Rate_VBoxContainer.visible = true
				Clock_Rate_Label.text = "Clock Rate: " + str(displayed_component.clock_rate) + "sec"
				Clock_Rate_HSlider.value = displayed_component.clock_rate
				Component_Color_VBoxContainer.visible = true
				Component_ColorPickerButton.color = displayed_component.sprite.modulate
		elif displayed_component is AreaBox:
			visible = true
			Component_Color_VBoxContainer.visible = true
			Component_ColorPickerButton.color = displayed_component.sprite.modulate
		elif displayed_component is Distributor:
			visible = true
			for out in displayed_component.outputs:
				if out is Pin:
					Output_Color_VBoxContainer.visible = true
					break
			output_OptionButton.visible = true
			Distributor_VBoxContainer.visible = true
			Component_Color_VBoxContainer.visible = true
			Component_ColorPickerButton.color = displayed_component.sprite.modulate
			for joint in displayed_component.outputs:
				if joint is Pin:
					output_OptionButton.add_item(joint.name)
			if output_OptionButton.item_count:
				output_OptionButton.select(0)
				_on_output_option_button_item_selected(0)
			for inp in displayed_component.inputs:
				if inp is Pin:
					create_Input_pin_PanelContainer(inp)
				else:
					create_Input_port_PanelContainer(inp)
			for out in displayed_component.outputs:
				if out is Pin:
					create_Output_pin_PanelContainer(out)
				else:
					create_Output_port_PanelContainer(out)

func hide_component_properties() -> void:
	displayed_component = null
	visible = false
	Inputs_Names_VBoxContainer.visible = false
	Outputs_Names_VBoxContainer.visible = false
	Component_Color_VBoxContainer.visible = false
	Output_Color_VBoxContainer.visible = false
	output_OptionButton.visible = false
	output_OptionButton.clear()
	Distributor_VBoxContainer.visible = false
	Clock_Rate_VBoxContainer.visible = false
	
	input_linker_OptionButtons.clear()
	
	if Inputs_Names_VBoxContainer.get_child(1).text_submitted.get_connections().size() > 0:
		Inputs_Names_VBoxContainer.get_child(1).text_submitted.disconnect(Inputs_Names_VBoxContainer.get_child(1).text_submitted.get_connections()[0]["callable"])
		Outputs_Names_VBoxContainer.get_child(1).text_submitted.disconnect(Outputs_Names_VBoxContainer.get_child(1).text_submitted.get_connections()[0]["callable"])

	var index: int = 2
	var input_children = Inputs_Names_VBoxContainer.get_children()
	while index < input_children.size():
		input_children[index].free()
		index += 1
	index = 2
	var output_children = Outputs_Names_VBoxContainer.get_children()
	while index < output_children.size():
		output_children[index].free()
		index += 1
		
	for child in Distributor_IO_VBoxContainer.get_children():
		child.free()

func _on_output_option_button_item_selected(index) -> void:
	if displayed_component is IC:
		Output_ColorPickerButton.color = displayed_component.get_output_by_name(output_OptionButton.get_item_text(index)).output_color
	else:#elif displayed_component is Distributor:
		for joint in displayed_component.outputs:
			if joint.name == output_OptionButton.get_item_text(index):
				Output_ColorPickerButton.color = joint.output_color
				return

func _on_Component_ColorPickerButton(color) -> void:
	if displayed_component is IC or displayed_component is Clock or displayed_component is AreaBox:
		displayed_component.set_color(color)
	else:
		displayed_component.sprite.modulate = color

func _on_Output_ColorPickerButton(color) -> void:
	if displayed_component is Switch:
		displayed_component.pin.set_output_color(color)
	else:#elif displayed_component is Distributor or displayed_component is IC:
		displayed_component.get_output_by_name(output_OptionButton.get_item_text(output_OptionButton.selected)).set_output_color(color)

func _on_Clock_Rate_value_changed(new_value: float) -> void:
	displayed_component.clock_rate = new_value
	displayed_component.toggle_timer = new_value
	Clock_Rate_Label.text = "Clock Rate: " + str(new_value) + "sec"

func add_input_pin_to_distributor() -> void:
	var new_joint = displayed_component.add_joint(Joint.Gender.female, true)
	create_Input_pin_PanelContainer(new_joint)

func create_Input_pin_PanelContainer(joint: Pin) -> void:
	var IPPC = Input_pin_PanelContainer_scene.instantiate() as PanelContainer
	Distributor_IO_VBoxContainer.add_child(IPPC)
	IPPC.get_node("VBoxContainer/Label").gui_input.connect(func(event: InputEvent): if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT: IPPC.get_node("VBoxContainer/VBoxContainer").visible = not IPPC.get_node("VBoxContainer/VBoxContainer").visible)
	IPPC.get_node("VBoxContainer/Label").text = joint.name
	IPPC.get_node("VBoxContainer/VBoxContainer/HBoxContainer/LineEdit").text = joint.name
	IPPC.get_node("VBoxContainer/VBoxContainer/HBoxContainer/LineEdit").text_submitted.connect(func(new_text: String): on_renaming_joint(displayed_component, joint, new_text); IPPC.get_node("VBoxContainer/Label").text = joint.name)
	IPPC.get_node("VBoxContainer/VBoxContainer/Remove Button").pressed.connect(func(): IPPC.queue_free(); on_removing_joint(displayed_component, joint))

func add_input_port_to_distributor() -> void:
	var new_joint = displayed_component.add_joint(Joint.Gender.female, false) as Port
	new_joint.values_buffer[0] = false
	create_Input_port_PanelContainer(new_joint)

func create_Input_port_PanelContainer(joint: Port):
	var IPPC = Input_port_PanelContainer_scene.instantiate() as PanelContainer
	Distributor_IO_VBoxContainer.add_child(IPPC)
	IPPC.get_node("VBoxContainer/Label").gui_input.connect(func(event: InputEvent): if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT: IPPC.get_node("VBoxContainer/VBoxContainer").visible = not IPPC.get_node("VBoxContainer/VBoxContainer").visible)
	IPPC.get_node("VBoxContainer/Label").text = joint.name
	IPPC.get_node("VBoxContainer/VBoxContainer/HBoxContainer/LineEdit").text = joint.name
	IPPC.get_node("VBoxContainer/VBoxContainer/HBoxContainer/LineEdit").text_submitted.connect(func(new_text: String): on_renaming_joint(displayed_component, joint, new_text); IPPC.get_node("VBoxContainer/Label").text = joint.name)
	if joint.attached_cables.size():
		IPPC.get_node("VBoxContainer/VBoxContainer/size HBoxContainer").free()
	else:
		IPPC.get_node("VBoxContainer/VBoxContainer/size HBoxContainer/SpinBox").value = joint.values_buffer.size()
		IPPC.get_node("VBoxContainer/VBoxContainer/size HBoxContainer/SpinBox").value_changed.connect(func(value): joint.rescale_buffer(value))
	IPPC.get_node("VBoxContainer/VBoxContainer/Remove Button").pressed.connect(func(): IPPC.queue_free(); on_removing_joint(displayed_component, joint))

func add_output_pin_to_distributor() -> void:
	var new_joint = displayed_component.add_joint(Joint.Gender.male, true)
	create_Output_pin_PanelContainer(new_joint)
	output_OptionButton.add_item(new_joint.name)
	if not Output_Color_VBoxContainer.visible:
		Output_Color_VBoxContainer.visible = true
		_on_output_option_button_item_selected(0)
		output_OptionButton.select(0)

func create_Output_pin_PanelContainer(joint: Pin):
	var OPPC = Output_pin_PanelContainer_scene.instantiate() as PanelContainer
	Distributor_IO_VBoxContainer.add_child(OPPC)
	OPPC.get_node("VBoxContainer/Label").gui_input.connect(func(event: InputEvent): if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT: OPPC.get_node("VBoxContainer/VBoxContainer").visible = not OPPC.get_node("VBoxContainer/VBoxContainer").visible)
	OPPC.get_node("VBoxContainer/Label").text = joint.name
	OPPC.get_node("VBoxContainer/VBoxContainer/HBoxContainer/LineEdit").text = joint.name
	OPPC.get_node("VBoxContainer/VBoxContainer/HBoxContainer/LineEdit").text_submitted.connect(func(new_text: String): on_renaming_joint(displayed_component, joint, new_text); OPPC.get_node("VBoxContainer/Label").text = joint.name)
	OPPC.get_node("VBoxContainer/VBoxContainer/Remove Button").pressed.connect(
		func():
			for index in output_OptionButton.get_popup().item_count:
				if joint.name == output_OptionButton.get_item_text(index):
					output_OptionButton.remove_item(index)
					break
			if not output_OptionButton.get_popup().item_count:
				Output_Color_VBoxContainer.visible = false
			elif output_OptionButton.selected == -1:
				output_OptionButton.select(0)
				_on_output_option_button_item_selected(0)
			OPPC.queue_free()
			on_removing_joint(displayed_component, joint)
	)
	var ob = OPPC.get_node("VBoxContainer/VBoxContainer/VBoxContainer/Input HBoxContainer/OptionButton") as OptionButton
	ob.tree_exited.connect(func(): input_linker_OptionButtons.erase(ob))
	input_linker_OptionButtons.append(ob)
	var index: int = -1
	var current: int = 0
	fill_input_popup(displayed_component, ob.get_popup())
	if displayed_component.linkers[joint]:
		while current < ob.get_popup().item_count:
			var pair = displayed_component.linkers[joint]
			if ob.get_popup().get_item_text(current) == (pair.A.name + str(pair.B)) if pair.A is Port else pair.A.name:
				index = current
				break
			current += 1
		ob.select(index)
	ob.pressed.connect(func(): fill_input_popup(displayed_component, ob.get_popup()))
	ob.get_popup().index_pressed.connect(func(index): displayed_component.link(joint, ob.get_popup().get_item_text(index)))

func add_output_port_to_distributor() -> void:
	var new_joint = displayed_component.add_joint(Joint.Gender.male, false)
	new_joint.values_buffer[0] = false
	create_Output_port_PanelContainer(new_joint)

func create_Output_port_PanelContainer(joint: Port):
	var OPPC = Output_port_PanelContainer_scene.instantiate() as PanelContainer
	Distributor_IO_VBoxContainer.add_child(OPPC)
	OPPC.get_node("VBoxContainer/Label").gui_input.connect(func(event: InputEvent): if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT: OPPC.get_node("VBoxContainer/VBoxContainer").visible = not OPPC.get_node("VBoxContainer/VBoxContainer").visible)
	OPPC.get_node("VBoxContainer/Label").text = joint.name
	OPPC.get_node("VBoxContainer/VBoxContainer/HBoxContainer/LineEdit").text = joint.name
	OPPC.get_node("VBoxContainer/VBoxContainer/HBoxContainer/LineEdit").text_submitted.connect(func(new_text: String): on_renaming_joint(displayed_component, joint, new_text); OPPC.get_node("VBoxContainer/Label").text = joint.name)
	OPPC.get_node("VBoxContainer/VBoxContainer/Inputs Count HBoxContainer/SpinBox").value = joint.values_buffer.size()
	change_input_spots(displayed_component, joint.values_buffer.size(), OPPC.get_node("VBoxContainer/VBoxContainer/VBoxContainer"), joint)
	OPPC.get_node("VBoxContainer/VBoxContainer/Inputs Count HBoxContainer/SpinBox").value_changed.connect(func(value): joint.rescale_buffer(value); change_input_spots(displayed_component, value, OPPC.get_node("VBoxContainer/VBoxContainer/VBoxContainer"), joint))
	if joint.attached_cables.size():
		OPPC.get_node("VBoxContainer/VBoxContainer/Inputs Count HBoxContainer").free()
	OPPC.get_node("VBoxContainer/VBoxContainer/Remove Button").pressed.connect(func(): OPPC.queue_free(); on_removing_joint(displayed_component, joint))
	var ob = OPPC.get_node("VBoxContainer/VBoxContainer/VBoxContainer/Input HBoxContainer/OptionButton") as OptionButton
	ob.tree_exited.connect(func(): input_linker_OptionButtons.erase(ob))
	input_linker_OptionButtons.append(ob)
	fill_input_popup(displayed_component, ob.get_popup())
	var index: int = -1
	var current: int = 0
	if displayed_component.linkers[joint].size():
		var pair: Pair = displayed_component.linkers[joint][0]
		if pair:
			while current < ob.get_popup().item_count:
				if (pair.A.name + str(pair.B) if pair.A is Port else pair.A.name) == ob.get_popup().get_item_text(current):
					index = current
					break
				current += 1
			ob.select(index)
	ob.pressed.connect(func(): fill_input_popup(displayed_component, ob.get_popup()))
	ob.get_popup().index_pressed.connect(func(index): displayed_component.link(joint, ob.get_popup().get_item_text(index)))

func change_input_spots(distributor, value, OPPC: VBoxContainer, joint: Joint) -> void:
	while OPPC.get_children().size() > value:
		OPPC.get_child(OPPC.get_children().size()-1).free()
	var num: int = OPPC.get_children().size()
	while OPPC.get_children().size() < value:
		var new_node = OPPC.get_child(OPPC.get_children().size()-1).duplicate()
		OPPC.add_child(new_node)
		var ob = new_node.get_node("OptionButton")
		ob.tree_exited.connect(func(): input_linker_OptionButtons.erase(ob))
		input_linker_OptionButtons.append(ob)
		fill_input_popup(distributor, ob.get_popup())
		var index: int = -1
		if distributor.linkers[joint].size() > num:
			var pair = distributor.linkers[joint][num]
			if pair:
				var current: int = 0
				while current < ob.get_popup().item_count:
					if (pair.A.name + str(pair.B) if pair.A is Port else pair.A.name) == ob.get_popup().get_item_text(current):
						index = current
						break
					current += 1
		ob.select(index)
		ob.pressed.connect(func(): fill_input_popup(distributor, ob.get_popup()))
		ob.get_popup().index_pressed.connect(func(index): distributor.link(joint, ob.get_popup().get_item_text(index), num))
		new_node.get_node("Label").text = "input " + str(num) + ": "
		num += 1

func fill_input_popup(distributor: Distributor, popup: PopupMenu) -> void:
	popup.clear()
	for input in distributor.inputs:
		if input is Pin:
			popup.add_item(input.name)
		elif input is Port:
			var counter: int = 0
			while counter < input.values_buffer.size():
				popup.add_item(input.name + str(counter))
				counter += 1

func on_renaming_joint(distributor: Distributor, joint: Joint, new_text: String) -> void:
	var old_name: String = joint.name
	if distributor.rename_joint(joint, new_text) and joint.gender == Joint.Gender.female:
		if old_name.contains("$"):
			for ob in input_linker_OptionButtons:
				var text = ob.get_item_text(ob.selected)
				if text.left(text.find("$", 1)+1) == old_name:
					ob.set_item_text(ob.selected, joint.name + text.get_slice("$", 2))
		else:
			for ob in input_linker_OptionButtons:
				if ob.get_item_text(ob.selected) == old_name:
					ob.set_item_text(ob.selected, joint.name)

func on_removing_joint(distributor, joint: Joint) -> void:
	if joint.name.contains("$"):
		for ob in input_linker_OptionButtons:
			if ob.selected == -1:
				continue
			var text = ob.get_item_text(ob.selected)
			if text.left(text.find("$", 1)+1) == joint.name:
				ob.select(-1)
	else:
		for ob in input_linker_OptionButtons:
			if ob.selected == -1:
				continue
			if ob.get_item_text(ob.selected) == joint.name:
				ob.select(-1)
	distributor.remove_joint(joint)
