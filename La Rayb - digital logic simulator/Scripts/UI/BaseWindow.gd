extends Window
class_name BaseWindow

var drag_initial_pos: Vector2 = Vector2.ZERO
var is_being_dragged: bool = false

func _on_about_to_popup():
	InputHandler.unfocus()

func _on_window_input(event):
	if event is InputEventKey and event.keycode == KEY_ESCAPE:
		_on_close_requested()

func _on_header_gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			drag_initial_pos = get_mouse_position()
			is_being_dragged = true
		else:
			is_being_dragged = false

func _process(_delta):
	if is_being_dragged:
		position = position + Vector2i(get_mouse_position() - drag_initial_pos)

func _on_close_requested():
	hide()
