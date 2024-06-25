extends Node2D
class_name Interactable

var is_being_picked: Callable
var pick: Callable
var unpick: Callable
var detach: Callable

var is_picked: bool = false

var motherBoard: Board = null

@onready var free_label: FreeLabel = null
var reoffset_label: Callable

func _ready():
	BoardsController.add_interactable(self)

func destructor() -> void:
	motherBoard.interactables.erase(self)
	motherBoard.picked_interactables.erase(self)

func create_label():
	free_label = BoardsController.instance.freeLabel_PackedScene.instantiate()
	add_child(free_label)
	renamed.connect(on_renamed)
	on_renamed()

func on_renamed():
	free_label.get_node("Label").text = name
	free_label.size = free_label.get_node("Label").get_theme_font("font").get_string_size(name, 0, -1, 12)
	
	reoffset_label.call()
