extends BaseWindow
class_name IncludedBoardsWindow

static var instance: IncludedBoardsWindow = null

@onready var buttons_container: VBoxContainer = $"Control/PanelContainer/VBoxContainer/Body MarginContainer/PanelContainer/VBoxContainer/ScrollContainer/MarginContainer/VBoxContainer"
var selected_board: Button = null

func _ready():
	instance = self

func add_board_button(board_name: String) -> void:
	var new_button = Button.new()
	new_button.text = board_name.left(board_name.length()-6)
	new_button.pressed.connect(func(): selected_board = new_button)
	buttons_container.add_child(new_button)

func open_board() -> void:
	if selected_board:
		for board in BoardsController.instance.selected_board.Boards:
			if board.name == selected_board.text:
				Utilities.instance.trigger_error_msbox("This board is opened already!")
				return
		DataManagement.instance.open_board(selected_board.text + ".board")
		_on_close_requested()

func delete_board() -> void:
	if selected_board:
		DataManagement.instance.delete_board(selected_board.text + ".board")
		selected_board.free()
		selected_board = null

func _on_about_to_popup() -> void:
	super()
	
	for button in buttons_container.get_children():
		button.free()
	selected_board = null
	for file in DataManagement.instance.saved_boards:
		if file == "main.board":
			continue
		add_board_button(file)

func _on_window_input(event):
	super(event)
	
	if event is InputEventKey:
		if event.keycode == KEY_ENTER:
			open_board()
