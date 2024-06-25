extends Control
class_name Board

static var Boards: Array[Board] = []

var interactables: Array[Interactable] = []
var picked_interactables: Array[Interactable] = []

var board_components: Array[BoardComponent] = []
var selected_board_components: Array[BoardComponent] = []

var free_labels: Array[FreeLabel] = []
var labels_visibility: bool = false
var IO_Components: Array[IO_Component] = []
var LEDs: Array[LED] = []
var pins: Array[Pin] = []
var ports: Array[Port] = []
var cables: Array[Cable] = []

@onready var interfaces_container: VBoxContainer = BoardComponentsInterfaceDisplayer.instance.create_interfaces_container()
@onready var subViewport: SubViewport = $SubViewportContainer/SubViewport
@onready var container: Node2D = $SubViewportContainer/SubViewport/Board
@onready var camera: CameraController = $SubViewportContainer/SubViewport/Camera2D
@onready var coolGridEffect_material: ShaderMaterial = $"SubViewportContainer/SubViewport/ParallaxBackground/Cool Grid Effect".material

func _ready():
	Boards.append(self)
	visible = false
	show_board()
	resized.connect(rescale_board)
	rescale_board()

func _exit_tree():
	Boards.erase(self)
	interfaces_container.free()

func show_board() -> void:
	if not visible:
		BoardsController.instance.grab_focus()
		visible = true
		interfaces_container.visible = true
		(BoardsNavigationer.instance.boards_butttons[self] as Button).add_theme_stylebox_override("normal", BoardsNavigationer.instance.selectedBoardNavigatonButton_Normal_StyleBoxFlat)
		(BoardsNavigationer.instance.boards_butttons[self] as Button).add_theme_stylebox_override("hover", BoardsNavigationer.instance.selectedBoardNavigatonButton_Hover_StyleBoxFlat)
		(BoardsNavigationer.instance.boards_butttons[self] as Button).add_theme_stylebox_override("pressed", BoardsNavigationer.instance.selectedBoardNavigatonButton_Pressed_StyleBoxFlat)
		
		MainMenuStrip.instance.can_convert_board_into_IC(BoardsController.instance.selected_board.LEDs.size())

func hide_board() -> void:
	if visible:
		visible = false
		interfaces_container.visible = false
		(BoardsNavigationer.instance.boards_butttons[self] as Button).add_theme_stylebox_override("normal", BoardsNavigationer.instance.unselectedBoardNavigatonButton_Normal_StyleBoxFlat)
		(BoardsNavigationer.instance.boards_butttons[self] as Button).add_theme_stylebox_override("hover", BoardsNavigationer.instance.unselectedBoardNavigatonButton_Hover_StyleBoxFlat)
		(BoardsNavigationer.instance.boards_butttons[self] as Button).add_theme_stylebox_override("pressed", BoardsNavigationer.instance.unselectedBoardNavigatonButton_Pressed_StyleBoxFlat)

func insert(child) -> void:
	container.add_child(child)

func pick_from_board() -> void:
	var cursor_pos: Vector2 = camera.get_global_mouse_position()
	
	if not Input.is_key_pressed(KEY_SHIFT):#can pick multiple things only when pressing SHIFT
		unpick_interactables()
	
	for interactable in interactables:
		if interactable.is_being_picked.call(cursor_pos):#check if the cursor is on the interactable
			if interactable is Joint or interactable is Cable:#these are only picked alone
				unpick_interactables()
			if interactable.is_picked and Input.is_key_pressed(KEY_SHIFT):#toggle picking
				interactable.unpick.call(cursor_pos)
				picked_interactables.erase(interactable)
			else:
				interactable.pick.call()
			break
	
	if not Input.is_key_pressed(KEY_SHIFT) and not picked_interactables.size():
		insert(BoardsController.instance.selectionArea_Scene.instantiate())

func handle_picked_interactables() -> void:
	for interactable in picked_interactables:
		if interactable is Joint:
			interactable.attached_cables.back().move_point(interactable.attached_cables.back().points_count()-1 if interactable.gender == Joint.Gender.female else 0, camera.get_global_mouse_position())
		elif interactable is BoardComponent:
			interactable.move_to(interactable.position + InputManager.instance.cursor_displacement)
		elif interactable is Cable:
			interactable.move_point(interactable.selected_point_index, camera.get_global_mouse_position())

func unpick_interactables() -> void:
	var cursor_pos: Vector2 = camera.get_global_mouse_position()
	
	for interactable in picked_interactables:
		interactable.unpick.call(cursor_pos)
	selected_board_components.clear()
	picked_interactables.clear()

func delete_selected_components() -> void:
	for c in selected_board_components:
		var to_visit: Array[BoardComponent] = [c]
		while to_visit.size():
			var current = to_visit.pop_back()
			current.detach.call_deferred()
			current.destructor()
			for child in current.children:
				to_visit.append(child)
		c.call_deferred("free")
	
	unpick_interactables()

func rescale_board():
	subViewport.size = size
	camera.grid.material.set_shader_parameter("scale", camera.grid.size / camera.grid.texture.get_size())

func set_highlight(value: bool) -> void:
	coolGridEffect_material.set_shader_parameter("highlight", value)
