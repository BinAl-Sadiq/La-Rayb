extends BaseWindow
class_name CreateNewBoardWindow

@export var new_window_name_LineEdit: LineEdit = null

func create_new_board() -> void:
	var board_name: String = Utilities.trim(new_window_name_LineEdit.text)

	if board_name == "":
		Utilities.instance.trigger_error_msbox("Invalid name!")
		return
	
	for board in BoardsController.instance.selected_board.Boards:
		if board.name == board_name:
			Utilities.instance.trigger_error_msbox("There is an opened baord with this name!")
			return
	for board_file_name in DataManagement.instance.saved_boards:
		if board_file_name.left(board_file_name.length()-6) == board_name:
			Utilities.instance.trigger_error_msbox("There is a saved board with this name!")
			return
	
	BoardsController.instance.create_board(board_name)
	
	_on_close_requested()

func _on_about_to_popup():
	super()
	
	new_window_name_LineEdit.grab_focus()
	new_window_name_LineEdit.text = ""

func _on_window_input(event):
	super(event)
	
	if event is InputEventKey:
		if event.keycode == KEY_ENTER:
			create_new_board()
