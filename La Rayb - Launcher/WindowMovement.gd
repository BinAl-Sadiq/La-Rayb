extends Control

var drag_initial_pos: Vector2 = Vector2.ZERO
var is_being_dragged: bool = false

@onready var win: Window = get_window()

func _on_gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			drag_initial_pos = win.get_mouse_position()
			is_being_dragged = true
		else:
			is_being_dragged = false

func _process(_delta):
	if is_being_dragged:
		win.position = win.position + Vector2i(win.get_mouse_position() - drag_initial_pos)
