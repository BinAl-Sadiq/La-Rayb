extends ScrollContainer
class_name BoardComponentsInterfaceDisplayer

static var instance: BoardComponentsInterfaceDisplayer = null

@export var Components_MenuButton: MenuButton = null

@export var component_interface_container_PackedScene: PackedScene = null
@export var component_interface_PackedScene: PackedScene = null
@export var switch_icon: CompressedTexture2D = null
@export var clock_icon: CompressedTexture2D = null
@export var LED_icon: CompressedTexture2D = null
@export var IC_icon: CompressedTexture2D = null
@export var area_box_icon: CompressedTexture2D = null
@export var distributor_icon: CompressedTexture2D = null

@export var idle_component_interface_StyleBox: StyleBox = null
@export var selected_component_interface_StyleBox: StyleBox = null
@export var above_component_interface_StyleBox: StyleBox = null
@export var inside_component_interface_StyleBox: StyleBox = null
@export var under_component_interface_StyleBox: StyleBox = null

@export var visible_icon: CompressedTexture2D = null
@export var hidden_icon: CompressedTexture2D = null

@export var board_component_name_LineEdit: LineEdit = null

@export var custom_ICs_Window: Window = null

var mouse_y_clicked_pisition: float = 0.0
var drop_at: BoardComponentInterface = null
var drop_offset: int = 0 # 0 = above, 1 = inside, 2 = under
var holding_timer: float = 0.2
var drag: bool = false

func _enter_tree():
	instance = self
	Components_MenuButton.get_popup().index_pressed.connect(_on_adding_component)
	Components_MenuButton.get_popup().set_item_accelerator(8, KEY_F7)

func _ready():
	var input_handler = InputHandler.new($"../../../../../")
	input_handler.left_mouse_button_just_pressed.connect(interfaces_container_clicked_on)
	input_handler.left_mouse_button_pressed.connect(handle_draged_interfaces)
	input_handler.left_mouse_button_just_released.connect(drop_interfaces)
	input_handler.right_mouse_button_just_pressed.connect(cancel_changing_board_component_name)
	
	board_component_name_LineEdit.focus_exited.connect(func(): cancel_changing_board_component_name())

func _physics_process(delta):
	if drag and holding_timer > 0.0:
		holding_timer = holding_timer - delta

func create_interfaces_container() -> VBoxContainer:
	var c = component_interface_container_PackedScene.instantiate() as VBoxContainer
	add_child(c)
	return c

func _on_adding_component(index) -> void:
	var new_component: BoardComponent = null
	if index == 0:
		new_component = BoardsController.instance.switch_scene.instantiate()
		BoardsController.instance.selected_board.insert(new_component)
		new_component.set_component_name("Switch")
	elif index == 1:
		new_component = BoardsController.instance.LED_scene.instantiate() as Node2D
		BoardsController.instance.selected_board.insert(new_component)
		new_component.set_component_name("LED")
	elif index < 5:
		new_component = BoardsController.instance.ic_scene.instantiate() as IC
		new_component.ic_name = "and" if index == 2 else ("or" if index == 3 else "not")
		BoardsController.instance.selected_board.insert(new_component)
		new_component.set_component_name(new_component.ic_name)
	elif index == 5:
		new_component = BoardsController.instance.areaBox_scene.instantiate() as Node2D
		BoardsController.instance.selected_board.insert(new_component)
		new_component.set_component_name("AreaBox")
	elif index == 6:
		new_component = BoardsController.instance.distributor_scene.instantiate() as Node2D
		BoardsController.instance.selected_board.insert(new_component)
		new_component.set_component_name("Distributor")
	elif index == 7:
		new_component = BoardsController.instance.clock_scene.instantiate() as Node2D
		BoardsController.instance.selected_board.insert(new_component)
		new_component.set_component_name("Clock")
	elif index == 8:
		custom_ICs_Window.popup()
	if new_component:
		new_component.position = BoardsController.instance.selected_board.camera.get_screen_center_position()

func create_interface(board_component: BoardComponent) -> BoardComponentInterface:
	var interface = component_interface_PackedScene.instantiate() as BoardComponentInterface
	interface.board_component = board_component
	BoardsController.instance.selected_board.interfaces_container.add_child(interface)
	if board_component is Clock:
		interface.texture_rect.texture = clock_icon
		interface.label.text = board_component.name
	elif board_component is Switch:
		interface.texture_rect.texture = switch_icon
		interface.label.text = board_component.name
	elif board_component is LED:
		interface.texture_rect.texture = LED_icon
		interface.label.text = board_component.name
	elif board_component is IC:
		interface.texture_rect.texture = IC_icon
		interface.label.text = board_component.ic_name
	elif board_component is AreaBox:
		interface.texture_rect.texture = area_box_icon
		interface.label.text = board_component.name
	elif board_component is Distributor:
		interface.texture_rect.texture = distributor_icon
		interface.label.text = board_component.name
	return interface

func interfaces_container_clicked_on() -> void:
	mouse_y_clicked_pisition = get_global_mouse_position().y
	drag = false
	
	if Input.is_key_pressed(KEY_SHIFT) and BoardsController.instance.selected_board.selected_board_components.size():
		var initial_position: float = BoardsController.instance.selected_board.selected_board_components.back().interface.box.global_position.y
		var final_position: float = 0.0
		for component in BoardsController.instance.selected_board.board_components:
			if not component.interface.collapsed and component.interface.box.get_global_rect().has_point(get_global_mouse_position()):
				final_position = component.interface.box.global_position.y
				component.pick.call()
				drag = true
				break
		var temp: float = initial_position
		initial_position = min(initial_position, final_position)
		final_position = max(temp, final_position)
		for component in BoardsController.instance.selected_board.board_components:
			if not component.interface.collapsed and component.interface.box.global_position.y > initial_position and component.interface.box.global_position.y < final_position:
				component.pick.call()
				drag = true
	else:
		if not Input.is_key_pressed(KEY_CTRL) and BoardsController.instance.selected_board.selected_board_components.size():
			BoardsController.instance.selected_board.unpick_interactables()
		for component in BoardsController.instance.selected_board.board_components:
			if not component.interface.collapsed and component.interface.box.get_global_rect().has_point(get_global_mouse_position()):
				if Input.is_key_pressed(KEY_CTRL) and component.is_picked:
					component.unpick.call(get_global_mouse_position())
					BoardsController.instance.selected_board.picked_interactables.erase(component)
				else:
					component.pick.call()
					drag = true
				break
	if drag:
		holding_timer = 0.2

func selecting_by_arrows(up: bool) -> void:
	if BoardsController.instance.selected_board.selected_board_components.size():
		var last_selected = BoardsController.instance.selected_board.selected_board_components.back()
		var last_pos: float = last_selected.interface.global_position.y
		for component in BoardsController.instance.selected_board.board_components:
			var upper_pos: float = last_pos if up else component.interface.global_position.y
			var lower_pos: float = component.interface.global_position.y if up else last_pos
			if not component.interface.collapsed and upper_pos > lower_pos and upper_pos - lower_pos < 38:
					if not Input.is_key_pressed(KEY_SHIFT):
						BoardsController.instance.selected_board.unpick_interactables()
					component.pick.call()
					break

func handle_draged_interfaces() -> void:
	if not drag or holding_timer > 0.0:
		return
	
	var current_mouse_y = get_global_mouse_position().y
	for c in BoardsController.instance.selected_board.board_components:
		if not c.is_picked and not c.interface.collapsed and c.interface.box.global_position.y < current_mouse_y and c.interface.box.global_position.y + c.interface.box.size.y > current_mouse_y:
			if drop_at and drop_at != c.interface:
				drop_at.box.add_theme_stylebox_override("panel", idle_component_interface_StyleBox)
			
			drop_at = c.interface
			break
	if drop_at and abs(mouse_y_clicked_pisition - current_mouse_y) > drop_at.box.size.y/2.0:
		if current_mouse_y - drop_at.box.global_position.y < drop_at.box.size.y/3.0:
			if drop_offset != 0:
				drop_offset = 0
				drop_at.box.add_theme_stylebox_override("panel", above_component_interface_StyleBox)
		elif current_mouse_y - drop_at.box.global_position.y < drop_at.box.size.y*0.667:
			if drop_offset != 1:
				drop_offset = 1
				drop_at.box.add_theme_stylebox_override("panel", inside_component_interface_StyleBox)
		else:
			if drop_offset != 2:
				drop_offset = 2
				drop_at.box.add_theme_stylebox_override("panel", under_component_interface_StyleBox)

func drop_interfaces() -> void:
	if drop_at != null:
		for e in BoardsController.instance.selected_board.selected_board_components:
			drop_at.insert_child(e, drop_offset)
		
		drop_at.box.add_theme_stylebox_override("panel", idle_component_interface_StyleBox)
		drop_at = null

func change_board_component_name() -> void:
	if BoardsController.instance.selected_board.selected_board_components.size() == 1 and not board_component_name_LineEdit.visible:
		var label = BoardsController.instance.selected_board.selected_board_components[0].interface.label as Label
		board_component_name_LineEdit.visible = true
		board_component_name_LineEdit.grab_focus()
		board_component_name_LineEdit.size = Vector2(min(size.x - label.position.x, label.size.x), label.size.y)
		board_component_name_LineEdit.position = label.global_position
		board_component_name_LineEdit.text = label.text
		board_component_name_LineEdit.select_all()
		label.modulate.a = 0.0
		label.resized.connect(func(): board_component_name_LineEdit.size = label.size)

func cancel_changing_board_component_name():
	if board_component_name_LineEdit.visible:
		board_component_name_LineEdit.visible = false
		var label = BoardsController.instance.selected_board.selected_board_components[0].interface.label as Label
		label.resized.disconnect(label.resized.get_connections()[0]["callable"])
		label.modulate.a = 1.0
		label = null

func submit_board_component_name(text: String):
	BoardsController.instance.selected_board.selected_board_components[0].set_component_name(board_component_name_LineEdit.text)
	cancel_changing_board_component_name()
