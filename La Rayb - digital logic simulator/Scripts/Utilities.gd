extends Node
class_name Utilities

static var instance;

@export var MSBox: MessageBox = null
@export var header: PanelContainer = null
@export var InterfacesDisplayer: PanelContainer = null
@export var boardsNavigator: PanelContainer = null

func _init():
	instance = self

static func trim(string: String) -> String:
	while string.length() > 1 and string[0] == " ":
		string = string.right(string.length() - 1)
	while string.length() and string.right(1) == " ":
		string = string.left(string.length() - 1)
	
	return string

static func abort() -> void:
	OS.kill(OS.get_process_id())

static func abort_for_corruption() -> void:
	var project_file = FileAccess.open(DataManagement.instance.project_path + DataManagement.instance.project_file, FileAccess.READ_WRITE)
	var data: Dictionary = JSON.parse_string(project_file.get_as_text())
	data["status"] = "corrupted"
	project_file.store_string(JSON.stringify(data))
	project_file.close()
	abort()

#ACE stands for anti-corruption extractor
static func ACE(from: Dictionary, what, types: Array):
	if from.has(what):
		var value = from[what]
		for type in types:
			if typeof(value) == type:
				return value
	abort_for_corruption()

func trigger_error_msbox(message: String) -> void:
	MSBox.trigger("Error: ", Color.RED, message)

func trigger_informal_msbox(message: String) -> void:
	#msbox.trigger("\u2139", Color.WHITE, message)
	MSBox.trigger("\u24D8", Color.WHITE, message)

func trigger_warning_msbox(message: String) -> void:
	#msbox.trigger("\u2139", Color.WHITE, message)
	MSBox.trigger("\u24D8", Color.WHITE, message)

func trigger_success_msbox(message: String) -> void:
	#msbox.trigger("\u2705", Color.WHITE, message)
	MSBox.trigger("\u2713", Color.WHITE, message)

func toggle_watch_mode() -> void:
	var value = not header.visible
	header.visible = value
	InterfacesDisplayer.visible = value
	boardsNavigator.visible = value
	if not value:
		ComponentPropertiesDisplayer.instance.hide_component_properties()
	elif BoardsController.instance.selected_board.picked_interactables.size() == 1 and BoardsController.instance.selected_board.picked_interactables[0] is BoardComponent:
		ComponentPropertiesDisplayer.instance.display_component_properties()
