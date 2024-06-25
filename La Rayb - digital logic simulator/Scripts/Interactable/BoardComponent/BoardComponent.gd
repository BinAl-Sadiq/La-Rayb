extends Interactable
class_name BoardComponent

@onready var sprite: Sprite2D = $Sprite2D
@onready var h_width: float
@onready var h_height: float

var on_move: Callable = func(): pass

var interface: BoardComponentInterface = null

var children: Array[BoardComponent]
var is_dragged: bool = false

var clone: Callable
var on_changing_visibility: Callable

func _ready():
	super()
	BoardsController.instance.selected_board.board_components.push_back(self)
	interface = BoardComponentsInterfaceDisplayer.instance.create_interface(self)
	
	calculate_half_width()
	calculate_half_height()

func destructor() -> void:
	super.destructor()
	
	var current_parent = get_parent()
	while current_parent is BoardComponent:
		if current_parent is AreaBox:
			current_parent.resize.call_deferred()
		current_parent = current_parent.get_parent()
	
	BoardsController.instance.selected_board.board_components.erase(self)
	if get_parent() is BoardComponent:
		get_parent().children.erase(self)
	interface.call_deferred("free")

func select() -> void:
	var list: Array[BoardComponent] = children.duplicate()
	var current = null
	while list.size():
		current = list.pop_back()
		current.is_dragged = true
		for c in current.children:
			list.append(c)
	
	BoardsController.instance.selected_board.selected_board_components.push_back(self)
	interface.box.add_theme_stylebox_override("panel", BoardComponentsInterfaceDisplayer.instance.selected_component_interface_StyleBox)

func deselect() -> void:
	is_dragged = false
	var list: Array[BoardComponent] = children.duplicate()
	var current = null
	while list.size():
		current = list.pop_back() as BoardComponent
		if not current.is_picked:
			current.is_dragged = false
		for c in current.children:
			list.append(c)
	
	BoardsController.instance.selected_board.selected_board_components.erase(self)
	interface.box.add_theme_stylebox_override("panel", BoardComponentsInterfaceDisplayer.instance.idle_component_interface_StyleBox)

func move_to(point: Vector2) -> void:
	if not is_dragged:
		position = point
	
	on_move.call()
	
	var current_parent = get_parent()
	while current_parent is BoardComponent:
		if current_parent is AreaBox:
			current_parent.resize()
		current_parent = current_parent.get_parent()

func insert_child(child: BoardComponent, drop_offset: int = 1) -> void:
	interface.insert_child(child, drop_offset)

func calculate_half_width() -> void:
	h_width = sprite.texture.get_width() * sprite.scale.x / 2.0

func calculate_half_height() -> void:
	h_height = sprite.texture.get_height() * sprite.scale.y / 2.0
