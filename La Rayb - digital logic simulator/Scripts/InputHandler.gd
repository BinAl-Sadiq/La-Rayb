extends Object
class_name InputHandler#Used only by BoardController, BoardComponentsInterfaceDisplayer, and ComponentPropertiesDisplayer

static var handlers: Array[InputHandler] = []
var control: Control

signal left_mouse_button_just_pressed
signal left_mouse_button_pressed
signal left_mouse_button_just_released

signal right_mouse_button_just_pressed
signal right_mouse_button_pressed
signal right_mouse_button_just_released

func _init(_control: Control):
	control = _control
	control.focus_entered.connect(
		func():
			for board in Board.Boards:
				board.set_highlight(true);
	)
	control.focus_exited.connect(
		func():
			for board in Board.Boards:
				board.set_highlight(false);
	)
	handlers.append(self)

static func get_focused() -> InputHandler:
	for handler in handlers:
		if handler.control.has_focus():
			return handler
	return null

static func unfocus() -> void:
	var handler = get_focused()
	if handler:
		handler.control.release_focus()
