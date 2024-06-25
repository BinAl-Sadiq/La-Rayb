extends Node
class_name InputManager

static var instance: InputManager = null

@onready var cursor_initial_pos: Vector2 = Vector2.ZERO
var cursor_displacement: Vector2 = Vector2.ZERO

func _enter_tree():
	instance = self

func _physics_process(_delta):
	cursor_displacement = BoardsController.instance.selected_board.camera.get_local_mouse_position() - cursor_initial_pos
	cursor_initial_pos = BoardsController.instance.selected_board.camera.get_local_mouse_position()
	
	var focused_handler: InputHandler = InputHandler.get_focused()
	if focused_handler:
		if Input.is_action_just_pressed("mouse_left"):
			focused_handler.left_mouse_button_just_pressed.emit()
		elif Input.is_action_pressed("mouse_left"):
			focused_handler.left_mouse_button_pressed.emit()
		elif Input.is_action_just_released("mouse_left"):
			focused_handler.left_mouse_button_just_released.emit()
		elif Input.is_action_just_pressed("mouse_right"):
			focused_handler.right_mouse_button_just_pressed.emit()
		elif Input.is_action_pressed("mouse_right"):
			focused_handler.right_mouse_button_pressed.emit()
		elif Input.is_action_just_released("mouse_right"):
			focused_handler.right_mouse_button_just_released.emit()
		elif Input.is_action_just_pressed("Up"):
			BoardComponentsInterfaceDisplayer.instance.selecting_by_arrows(true)
		elif Input.is_action_just_pressed("Down"):
			BoardComponentsInterfaceDisplayer.instance.selecting_by_arrows(false)
		elif Input.is_action_just_released("rename_key"):
			BoardComponentsInterfaceDisplayer.instance.change_board_component_name()
		elif Input.is_action_just_pressed("delete"):
			BoardsController.instance.delete_selected_components()
		elif Input.is_action_just_pressed("Clone To..."):
			if BoardsController.instance.selected_board.selected_board_components.size():
				CloneWindow.instance.popup()
		elif Input.is_action_just_pressed("Clone"):
			BoardsController.instance.clone_components()
		elif Input.is_action_just_pressed("invert_labels_visibility"):
			FreeLabel.invert_labels_visibility()
		if BoardsController.instance.get_rect().has_point(BoardsController.instance.get_local_mouse_position()):
			if Input.is_action_just_pressed("zoom in"):
				BoardsController.instance.selected_board.camera.camera_zoom(1)
			elif Input.is_action_just_pressed("zoom out"):
				BoardsController.instance.selected_board.camera.camera_zoom(-1)
	if Input.is_action_just_pressed("Toggle Full Screen"):
		DisplayServer.window_set_mode(3 if DisplayServer.window_get_mode() != 3 else 0)
	elif Input.is_action_just_pressed("toggle watch mode"):
		Utilities.instance.toggle_watch_mode()
	elif Input.is_action_just_pressed("Capture Frame"):
		MainMenuStrip.instance._on_capture_frame_button_pressed()
