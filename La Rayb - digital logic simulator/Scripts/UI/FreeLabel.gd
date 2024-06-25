extends ColorRect
class_name FreeLabel

@onready var mother_board: Board = BoardsController.instance.selected_board

func _ready():
	BoardsController.instance.selected_board.free_labels.append(self)
	visible = BoardsController.instance.selected_board.labels_visibility

func _notification(what: int):
	if what == NOTIFICATION_PREDELETE:
		mother_board.free_labels.erase(self)

static func invert_labels_visibility() -> void:
	BoardsController.instance.selected_board.labels_visibility = not BoardsController.instance.selected_board.labels_visibility
	for free_label in BoardsController.instance.selected_board.free_labels:
		free_label.visible = BoardsController.instance.selected_board.labels_visibility
