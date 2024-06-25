extends BaseWindow
class_name CloneWindow

static var instance: CloneWindow = null

@export var clone_button: Button = null
@export var boards_OptionButton: OptionButton = null

func _ready():
	instance = self

func _on_about_to_popup() -> void:
	super()
	
	clone_button.disabled = true
	boards_OptionButton.clear()
	for board in Board.Boards:
		if board == BoardsController.instance.selected_board:
			continue
		boards_OptionButton.add_item(board.name)
	boards_OptionButton.grab_focus()
	boards_OptionButton.select(-1)

func _on_option_button_item_selected(_index):
	clone_button.disabled = false

func clone() -> void:
	var src: Board = BoardsController.instance.selected_board
	for board in Board.Boards:
		if board.name == boards_OptionButton.get_item_text(boards_OptionButton.selected):
			BoardsNavigationer.instance.select_board(board)
			break
	
	BoardsController.instance.clone_components(src)
	
	_on_close_requested()
