extends Control
class_name BoardsController

static var instance: BoardsController = null

@export var board_scene: PackedScene = null
@export var selectionArea_Scene: PackedScene = null
@export var highlighterSquare_scene: PackedScene = null
@export var cable_scene: PackedScene = null
@export var pin_scene: PackedScene = null
@export var port_scene: PackedScene = null
@export var switch_scene: PackedScene = null
@export var clock_scene: PackedScene = null
@export var LED_scene: PackedScene = null
@export var ic_scene: PackedScene = null
@export var areaBox_scene: PackedScene = null
@export var distributor_scene: PackedScene = null
@export var freeLabel_PackedScene: PackedScene = null
@export var compass_PackedScene: PackedScene = null

var selected_board: Board = null

func _init():
	instance = self

func _ready():
	var input_handler = InputHandler.new(self)
	input_handler.left_mouse_button_just_pressed.connect(pick_interactables)
	input_handler.left_mouse_button_pressed.connect(handle_picked_interactables)
	input_handler.left_mouse_button_just_released.connect(unhold_interactables)
	input_handler.right_mouse_button_just_pressed.connect(unpick_or_detach_interactables)

static func add_interactable(interactable: Interactable) -> void:
	#matching the input response with the rendereing order
	var index: int = 0
	while index < instance.selected_board.interactables.size():
		if interactable.z_index <= instance.selected_board.interactables[index].z_index:
			index += 1
		else:
			break
	instance.selected_board.interactables.insert(index, interactable)
	interactable.motherBoard = instance.selected_board

func create_board(board_name: String) -> Board:
	var board = board_scene.instantiate()
	board.name = board_name
	BoardsNavigationer.instance.select_board(board)
	BoardsNavigationer.instance.add_navigaton_button(board)
	add_child(board)
	return board

func delete_selected_components():
	selected_board.delete_selected_components()

func pick_interactables():
	selected_board.pick_from_board()

func unpick_or_detach_interactables():
	var cursor_pos: Vector2 = selected_board.camera.get_global_mouse_position()
	for i in BoardsController.instance.selected_board.interactables:
		if i.is_being_picked.call(cursor_pos):
			if i is Cable:
				i.remove_close_point(cursor_pos)
			else:
				i.detach.call()
			return
	selected_board.unpick_interactables()

func unhold_interactables():
	if selected_board.picked_interactables.size() == 1 and (selected_board.picked_interactables[0] is Joint or selected_board.picked_interactables[0] is Cable):
		selected_board.unpick_interactables()

func handle_picked_interactables():
	selected_board.handle_picked_interactables()

func clone_components(src: Board = selected_board) -> void:
	var to_clone: Array[BoardComponent] = []
	var cables_to_clone: Array[Cable] = []
	var to_visit: Array[BoardComponent] = src.selected_board_components.duplicate()
	var clones: Dictionary = {}
	#determine what to clone
	while to_visit.size():
		var current = to_visit.pop_front() as BoardComponent
		if not to_clone.has(current):
			to_clone.append(current)
		if current is Switch:
			for wire in current.pin.attached_cables:
				if wire.point_B.holder.is_picked or wire.point_B.holder.is_dragged:
					if not cables_to_clone.has(wire):
						cables_to_clone.append(wire)
		elif current is LED:
			if current.pin.attached_cables.size() and (current.pin.attached_cables[0].point_A.holder.is_picked or current.pin.attached_cables[0].point_A.holder.is_dragged):
				if not cables_to_clone.has(current.pin.attached_cables[0]):
					cables_to_clone.append(current.pin.attached_cables[0])
		elif current is IC or current is Distributor:
			for inp in current.inputs:
				if inp.attached_cables.size() and (inp.attached_cables[0].point_A.holder.is_picked or inp.attached_cables[0].point_A.holder.is_dragged):
					if not cables_to_clone.has(inp.attached_cables[0]):
						cables_to_clone.append(inp.attached_cables[0])
			for out in current.outputs:
				for cable in out.attached_cables:
					if cable.point_B.holder.is_picked or cable.point_B.holder.is_dragged:
						if not cables_to_clone.has(cable):
							cables_to_clone.append(cable)
		for child in current.children:
			to_visit.push_back(child)
	if src == selected_board:
		src.unpick_interactables()
	#create detached clones
	while to_clone.size():
		var original = to_clone.pop_back() as BoardComponent
		var new_clone = original.clone.call() as BoardComponent
		new_clone.set_component_name(original.label.text if original is IC else original.name)
		clones[original] = new_clone
	#attach cables
	while cables_to_clone.size():
		var cable = cables_to_clone.pop_back() as Cable
		var cloned_point_A_holder: BoardComponent = clones[cable.point_A.holder]
		var cloned_point_B_holder: BoardComponent = clones[cable.point_B.holder]
		var cloned_point_A: Joint = null
		var cloned_point_B: Joint = null
		if cloned_point_A_holder is Switch:
			cloned_point_A = cloned_point_A_holder.pin
		elif cloned_point_A_holder is IC or cloned_point_A_holder is Distributor:
			cloned_point_A = cloned_point_A_holder.get_output_by_name(cable.point_A.name)
		if cloned_point_B_holder is LED:
			cloned_point_B = cloned_point_B_holder.pin
		elif cloned_point_B_holder is IC or cloned_point_B_holder is Distributor:
			cloned_point_B = cloned_point_B_holder.get_input_by_name(cable.point_B.name)
		cloned_point_A.connect_to(cloned_point_B, true)
		var new_cable = cloned_point_A.attached_cables.back() as Cable
		new_cable.straight_points = cable.straight_points.duplicate()
		new_cable.make_smooth()
	#reparent clones
	for original in clones:
		for child in original.children:
			clones[original].insert_child(clones[child])
	#pick clones
	for clone in clones.values():
		clone.pick.call()
