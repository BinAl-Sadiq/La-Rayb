extends BaseWindow
class_name Custom_ICs_Window

@export var custom_ICs_HFlowContainer: HFlowContainer = null

var selected_custom_ic_name: String = ""

static var instance: Custom_ICs_Window = null

func _init():
	instance = self

func _create_custom_IC_button(ic_name) -> void:
	var newICButton = Button.new()
	newICButton.text = ic_name
	newICButton.pressed.connect(func(): selected_custom_ic_name = newICButton.text)
	custom_ICs_HFlowContainer.add_child(newICButton)

func add_custom_IC() -> void:
	if selected_custom_ic_name != "":
		var newIC = BoardsController.instance.ic_scene.instantiate() as IC
		newIC.ic_name = selected_custom_ic_name
		BoardsController.instance.selected_board.insert(newIC)
		newIC.position = BoardsController.instance.selected_board.camera.get_screen_center_position()
		newIC.set_component_name(newIC.ic_name)

func delete_custom_IC() -> void:
	if selected_custom_ic_name != "":
		DataManagement.instance.Functions.erase(selected_custom_ic_name)
		var children = custom_ICs_HFlowContainer.get_children() as Array[Button]
		for child in children:
			if child.text == selected_custom_ic_name:
				child.free()
				DataManagement.instance.delete_IC(selected_custom_ic_name)
				break
		selected_custom_ic_name = ""

func _on_about_to_popup():
	super()
	
	var children = custom_ICs_HFlowContainer.get_children() as Array[Button]
	for child in children:
		child.free()
	selected_custom_ic_name = ""
	for IC_name in DataManagement.instance.Functions:
		if IC_name != "and" and IC_name != "or" and IC_name != "not":
			_create_custom_IC_button(IC_name)
