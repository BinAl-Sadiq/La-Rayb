extends HBoxContainer
class_name BoardsNavigationer

static var instance: BoardsNavigationer = null

@export var selectedBoardNavigatonButton_Normal_StyleBoxFlat: StyleBoxFlat = null
@export var selectedBoardNavigatonButton_Hover_StyleBoxFlat: StyleBoxFlat = null
@export var selectedBoardNavigatonButton_Pressed_StyleBoxFlat: StyleBoxFlat = null
@export var unselectedBoardNavigatonButton_Normal_StyleBoxFlat: StyleBoxFlat = null
@export var unselectedBoardNavigatonButton_Hover_StyleBoxFlat: StyleBoxFlat = null
@export var unselectedBoardNavigatonButton_Pressed_StyleBoxFlat: StyleBoxFlat = null

@export var boardNavigatonButton_PackedScene: PackedScene = null

var boards_butttons: Dictionary = {}

var holding_a_button: bool = false
var holding_initial_pos: float = 0.0
@export var Index_ColorRect: ColorRect = null
var drop_at: Button = null

func _init():
	instance = self

func _process(_delta):
	#determine wheather the user is changing the button's index or not
	if holding_a_button and not Index_ColorRect.visible and abs(get_global_mouse_position().x - holding_initial_pos) > 6.0:
		Index_ColorRect.visible = true
		drop_at = boards_butttons[BoardsController.instance.selected_board]
	#if so, display a color rect on top the desired index
	if Index_ColorRect.visible:
		var cursor_pos: float = get_global_mouse_position().x
		var nearest: float = abs(drop_at.global_position.x - cursor_pos)
		for button in boards_butttons.values():
			var length: float = abs(button.global_position.x - cursor_pos)
			if nearest > length:
				drop_at = button
				nearest = length
		if drop_at.text == "main":
			drop_at = get_child(1)
		Index_ColorRect.position = drop_at.global_position
		Index_ColorRect.size.x = drop_at.size.x

func add_navigaton_button(board: Board) -> void:
	if boards_butttons.has(board):
		Utilities.instance.trigger_error_msbox("This board is opened already!")
		return
	
	var new_button = boardNavigatonButton_PackedScene.instantiate() as Button
	new_button.text = board.name as String if board.name.length() < 11 else board.name.substr(0, 10) + "..."
	if board.name.length() > 10:
		new_button.tooltip_text = board.name
	add_child(new_button)
	boards_butttons[board] = new_button
	new_button.pressed.connect(func(): on_pressing_board_button(board))
	new_button.button_up.connect(func(): on_releasing_board_button(board))

func select_board(board: Board) -> void:
	if BoardsController.instance.selected_board:
		BoardsController.instance.selected_board.hide_board()
	BoardsController.instance.selected_board = board
	board.show_board()
	MainMenuStrip.instance.Board_MenuButton.get_popup().set_item_disabled(4, board.name == "main")

func close_board(board: Board) -> void:
	Board.Boards.erase(board)
	boards_butttons[board].call_deferred("free")
	var index: int = boards_butttons.keys().find(board)
	board.free()
	boards_butttons.erase(board)
	if BoardsController.instance.selected_board == board:
		BoardsController.instance.selected_board = null
		select_board(boards_butttons.keys()[index if index < boards_butttons.keys().size() else index-1])

func on_pressing_board_button(board: Board) -> void:
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		select_board(board)
		if board.name != "main":
			holding_a_button = true
			holding_initial_pos = get_global_mouse_position().x
	elif board.name != "main":#Middle button
		close_board(board)

func on_releasing_board_button(board: Board) -> void:
	holding_a_button = false
	if Index_ColorRect.visible:
		var value = boards_butttons[board]
		move_child(value, drop_at.get_index())
		Index_ColorRect.visible = false
