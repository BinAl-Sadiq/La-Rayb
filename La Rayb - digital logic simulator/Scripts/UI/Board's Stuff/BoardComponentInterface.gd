extends VBoxContainer
class_name BoardComponentInterface

var board_component: BoardComponent = null
@export var children_container: VBoxContainer = null
@export var box: PanelContainer = null
@onready var label: Label = $HBoxContainer/PanelContainer/HBoxContainer/Label
@onready var texture_rect: TextureRect = $HBoxContainer/PanelContainer/HBoxContainer/TextureRect
@onready var visibilityIcon: TextureRect = $"HBoxContainer/Visibility Button/TextureRect"
@onready var collapseButton: Button = $"HBoxContainer/Collapse Button"
var visibility: bool = true
var unvisible_ancestors: int = 0 #0 if all the ancestors are visible
var collapsed: bool = false

func insert_child(child: BoardComponent, drop_offset: int) -> void:
	var old_parent = child.get_parent()
	var not_visited: Array[BoardComponent] = [child]
	while not_visited.size():
		var current: BoardComponent = not_visited.pop_front()
		if current == board_component:
			return
		for c in current.children:
			not_visited.append(c)
	
	if drop_offset == 1:# 0 = above, 1 = inside, 2 = under
		if old_parent is BoardComponent:
			old_parent.children.erase(child)
			
		board_component.children.append(child)
		child.reparent(board_component)
		child.interface.reparent(children_container)
		child.interface.on_reparenting(self)
		child.interface.collapsed = collapsed and children_container.visible
	else:
		if old_parent is BoardComponent:
			old_parent.children.erase(child)
		
		if child.interface.get_parent() != get_parent():
			child.reparent(board_component.get_parent())
			child.interface.reparent(get_parent())
			child.interface.on_reparenting(get_parent().get_parent().get_parent() if get_parent().get_parent().get_parent() is BoardComponentInterface else null)
			child.interface.collapsed = false
		
		if child.get_parent() is BoardComponent:
			child.get_parent().children.append(child)
		
		var move_to: int = get_index()
		if drop_offset == 2 and move_to < child.interface.get_index():
			move_to = move_to + 1
		elif drop_offset == 0 and move_to > child.interface.get_index():
			move_to = move_to - 1
		get_parent().move_child(child.interface, move_to)
	
	var current = old_parent
	while current is BoardComponent:
		if current is AreaBox:
			current.resize()
		current = current.get_parent()
	current = board_component
	while current:
		if current is AreaBox:
			current.resize()
		current = current.get_parent()

func _on_collapse() -> void:
	if children_container.visible:
		children_container.visible = false
		collapseButton.get_node("TextureRect").rotation = -PI/2.0
	else:
		children_container.visible = true
		collapseButton.get_node("TextureRect").rotation = 0.0
		
	var to_visit: Array[BoardComponent] = board_component.children.duplicate()
	var coll = not children_container.visible
	while to_visit.size():
		var current = to_visit.pop_front() as BoardComponent
		current.interface.collapsed = coll
		for child in current.children:
			to_visit.append(child)

func on_reparenting(new_parent: BoardComponentInterface) -> void:
	var difference: int = unvisible_ancestors
	unvisible_ancestors = (new_parent.unvisible_ancestors + (0 if new_parent.visibility else 1)) if new_parent else 0
	difference = unvisible_ancestors - difference + (1 if visibility else -1)
	var to_visit: Array[BoardComponent] = board_component.children.duplicate()
	while to_visit.size():
		var current = to_visit.pop_front() as BoardComponent
		current.interface.unvisible_ancestors += difference
		for child in current.children:
			to_visit.append(child)
	board_component.on_changing_visibility.call(self)

func _toggle_visibility():
	visibility = not visibility
	board_component.visible = visibility
	if visibility:
		visibilityIcon.texture = BoardComponentsInterfaceDisplayer.instance.visible_icon
	else:
		visibilityIcon.texture = BoardComponentsInterfaceDisplayer.instance.hidden_icon
	
	board_component.on_changing_visibility.call(self)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and event.double_click:
		if label.get_global_rect().has_point(get_global_mouse_position()):
			BoardComponentsInterfaceDisplayer.instance.change_board_component_name()
		elif texture_rect.get_global_rect().has_point(get_global_mouse_position()):
			BoardsController.instance.selected_board.camera.focus_on(board_component)

func _on_children_container_child_order_changed():
	collapseButton.visible = board_component.children.size()
