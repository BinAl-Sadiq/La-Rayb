extends Camera2D
class_name CameraController

@onready var grid: TextureRect = $"../ParallaxBackground/Cool Grid Effect"
var grid_offset = Vector2.ZERO
@onready var board: Board = $"../../../"

var movement_speed: float = 1000.0
var movement_dir: Vector2 = Vector2.ZERO
var movement_timer: float = 0.0
var latest_x_dir: String = ""
var latest_y_dir: String = ""

var zooming_speed: float = 2.5
var zoom_dir: float = 0.0
var zoom_timer: float = 0.0

var prevMousePos: Vector2 = Vector2.ZERO
var dragging: bool = false

func _ready():
	if board.name != "main":
		grid.material = grid.material.duplicate()
		grid.material.set_shader_parameter("UV_offset", grid_offset)

func _physics_process(delta):
	if Input.is_action_just_pressed("Middle Mouse Button") and BoardsController.instance.get_rect().has_point(BoardsController.instance.get_local_mouse_position()):
		dragging = true
		BoardsController.instance.set_default_cursor_shape(Control.CURSOR_DRAG)
		prevMousePos = get_local_mouse_position()
	elif Input.is_action_just_released("Middle Mouse Button"):
		dragging = false
		BoardsController.instance.set_default_cursor_shape(Control.CURSOR_ARROW)
	if dragging:
		drag()
	else:
		camera_movement(delta)
		
		if zoom_timer > 0.0:
			zoom_timer = zoom_timer - delta
			var _offset = get_global_mouse_position()
			var zoom_acceleration: float = 1.0 if zoom_timer > 0.15 else zoom_timer / 0.15
			zoom = Vector2.ONE * clamp(zoom.x + zoom_dir * zooming_speed * zoom_acceleration * delta, 0.25, 2.0)
			_offset = _offset - get_global_mouse_position()
			position += _offset
			
		if movement_timer > 0.0:
			movement_timer = movement_timer - delta
			var zoom_acceleration: float = 1.0 if movement_timer > 0.13 else movement_timer / 0.13
			var displacement = movement_dir * movement_speed * delta * zoom_acceleration * (0.70710678 if movement_dir.x != 0.0 and movement_dir.y != 0.0 else 1.0)
			position += displacement
			grid_offset += displacement
			grid.material.set_shader_parameter("UV_offset", grid_offset)

func camera_movement(_delta) -> void:
	if not InputHandler.get_focused() or BoardsController.instance.selected_board != board or Input.is_key_pressed(KEY_CTRL):
		return
	
	if Input.is_action_just_pressed("move camera up"):
		latest_y_dir = "W"
	elif Input.is_action_just_released("move camera up"):
		latest_y_dir = "W" if not movement_dir.y else "S"
	if Input.is_action_just_pressed("move camera down"):
		latest_y_dir = "S"
	elif Input.is_action_just_released("move camera down"):
		latest_y_dir = "S" if not movement_dir.y else "W"
	if Input.is_action_just_pressed("move camera right"):
		latest_x_dir = "D"
	elif Input.is_action_just_released("move camera right"):
		latest_x_dir = "D" if not movement_dir.x else "A"
	if Input.is_action_just_pressed("move camera left"):
		latest_x_dir = "A"
	elif Input.is_action_just_released("move camera left"):
		latest_x_dir = "A" if not movement_dir.x else "D"
	
	var new_dir = Vector2.ZERO
	
	if Input.is_key_pressed(KEY_W) and latest_y_dir != "S":
		new_dir.y = -1.0
	elif Input.is_key_pressed(KEY_S):
		new_dir.y = 1.0
	if Input.is_key_pressed(KEY_D) and latest_x_dir != "A":
		new_dir.x = 1.0
	elif Input.is_key_pressed(KEY_A):
		new_dir.x = -1.0
	
	if new_dir != Vector2.ZERO:
		movement_dir = new_dir
		movement_timer = 0.17

func camera_zoom(dir: float) -> void:
	zoom_dir = dir
	zoom_timer = 0.2

func focus_on(target: BoardComponent) -> void:
	global_position = target.global_position - get_viewport().size * 0.5 / zoom

func drag() -> void:
	var currentMousePoss: Vector2 = get_local_mouse_position()
	position += prevMousePos - currentMousePoss
	prevMousePos = currentMousePoss
