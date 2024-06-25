extends PanelContainer

@onready var win: Window = get_window()

func _on_header_gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.double_click:
		_on_maximize_pressed()

func _on_close_main_window_pressed():
	get_tree().quit()

func _on_close_new_project_window_pressed():
	win.hide()

func _on_maximize_pressed():
	if win.mode == Window.MODE_FULLSCREEN:
		win.mode = Window.MODE_WINDOWED
	else:
		win.mode = Window.MODE_FULLSCREEN

func _on_minimize_pressed():
	win.mode = Window.MODE_MINIMIZED
