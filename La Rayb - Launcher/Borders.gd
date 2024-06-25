extends Control

var resize_direction: String = ""
var resize: bool = false

@onready var win: Window = get_window()
@export var min_size: Vector2 = Vector2i(600, 400)

func _ready():
	win.min_size = min_size

func _process(_delta):
	if resize:
		match resize_direction:
			"Top":
				var diff: float = win.size.y
				win.size.y -= win.get_mouse_position().y
				diff -= win.size.y
				win.position.y += diff
			"Bottom":
				win.size.y = win.get_mouse_position().y
			"Right":
				win.size.x = win.get_mouse_position().x
			"Left":
				var diff: float = win.size.x
				win.size.x -= win.get_mouse_position().x
				diff -= win.size.x
				win.position.x += diff
			"Top-Right":
				var diff: float = win.size.y
				win.size.y -= win.get_mouse_position().y
				diff -= win.size.y
				win.position.y += diff
				win.size.x = win.get_mouse_position().x
			"Top-Left":
				var diff: Vector2i = win.size
				win.size -= Vector2i(win.get_mouse_position())
				diff -= win.size
				win.position += diff
			"Bottom-Right":
				win.size = win.get_mouse_position()
			"Bottom-Left":
				var diff: float = win.size.x
				win.size.x -= win.get_mouse_position().x
				diff -= win.size.x
				win.position.x += diff
				win.size.y = win.get_mouse_position().y
		
		resize = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)

func _on_border_gui_input(event, border):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			resize_direction = border
			resize = true
