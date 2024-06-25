extends Control
class_name MainMenuStrip

@export var Board_MenuButton: MenuButton = null
@export var ICs_MenuButton: MenuButton = null

@export var create_new_IC_Window: Window = null
@export var create_new_Board_Window: Window = null

@export var file_dialog: FileDialog = null

static var instance: MainMenuStrip = null

func _init():
	instance = self

func _ready():
	Board_MenuButton.get_popup().index_pressed.connect(_on_board_menu_item_selected)
	@warning_ignore("int_as_enum_without_cast", "int_as_enum_without_match")
	Board_MenuButton.get_popup().set_item_accelerator(0, KEY_MASK_CTRL | KEY_N)
	@warning_ignore("int_as_enum_without_cast", "int_as_enum_without_match")
	Board_MenuButton.get_popup().set_item_accelerator(1, KEY_MASK_CTRL | KEY_I)
	@warning_ignore("int_as_enum_without_cast", "int_as_enum_without_match")
	Board_MenuButton.get_popup().set_item_accelerator(3, KEY_MASK_CTRL | KEY_S)
	ICs_MenuButton.get_popup().index_pressed.connect(_on_ICs_menu_item_selected)
	ICs_MenuButton.get_popup().set_item_accelerator(1, KEY_F9)

func _on_board_menu_item_selected(index) -> void:
	if index == 0:
		create_new_Board_Window.popup()
	elif index == 1:
		IncludedBoardsWindow.instance.popup()
	elif index == 2:
		file_dialog.clear_filters()
		file_dialog.add_filter("*.board")
		if file_dialog.file_selected.is_connected(DataManagement.instance.load_IC_into_project):
			file_dialog.file_selected.disconnect(DataManagement.instance.load_IC_into_project)
		if not file_dialog.file_selected.is_connected(DataManagement.instance.load_board_into_project):
			file_dialog.file_selected.connect(DataManagement.instance.load_board_into_project)
		file_dialog.popup()
	elif index == 3:
		DataManagement.instance.save_current_board()
	elif index == 4:
		BoardsNavigationer.instance.close_board(BoardsController.instance.selected_board)

func _on_ICs_menu_item_selected(index) -> void:
	if index == 0:
		file_dialog.clear_filters()
		file_dialog.add_filter("*.IC")
		if not file_dialog.file_selected.is_connected(DataManagement.instance.load_IC_into_project):
			file_dialog.file_selected.connect(DataManagement.instance.load_IC_into_project)
		if file_dialog.file_selected.is_connected(DataManagement.instance.load_board_into_project):
			file_dialog.file_selected.disconnect(DataManagement.instance.load_board_into_project)
		file_dialog.popup()
	elif index == 1:
		create_new_IC_Window.popup()
	elif index == 2:
		IOOrderWindow.instance.popup()

func can_convert_board_into_IC(value: bool) -> void:
	ICs_MenuButton.get_popup().set_item_disabled(1, not value)

func _on_capture_frame_button_pressed():
	var frame_name = Time.get_datetime_string_from_system().replace(":", "-") + " @ " + str(Time.get_ticks_usec()) + ".png"
	if not DirAccess.dir_exists_absolute(DataManagement.instance.project_path + "Captured Frames/"):
		DirAccess.make_dir_absolute(DataManagement.instance.project_path + "Captured Frames/")
	get_viewport().get_texture().get_image().save_png(DataManagement.instance.project_path + "Captured Frames/" + frame_name)
	Utilities.instance.trigger_informal_msbox("The frame: " + frame_name + " is saved")
