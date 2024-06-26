extends MarginContainer
class_name ProjectsList

static var instance: ProjectsList = null

const current_version: String = "1.0.1"

@export var container: VBoxContainer = null
@export var project_button: PackedScene = null

func _ready():
	instance = self
	
	if not FileAccess.file_exists("Projects.json"):
		FileAccess.open("Projects.json", FileAccess.WRITE).store_string("[]")
	var projects = JSON.parse_string(FileAccess.open("Projects.json", FileAccess.READ).get_as_text())
	if projects is Array:
		for project in projects:
			create_project_button(project)

func create_project_button(file_path: String) -> bool:
	var file: FileAccess = FileAccess.open(file_path, FileAccess.READ)
	var new_project = project_button.instantiate() as Button
	new_project.pressed.connect(func(): DecisionButtons.instance.select_project(new_project))
	new_project.get_node("MarginContainer").get_node("HBoxContainer").get_node("VBoxContainer").get_node("Project name").text = file_path.get_file().substr(0, file_path.get_file().length() - 8)
	new_project.get_node("MarginContainer").get_node("HBoxContainer").get_node("VBoxContainer").get_node("Project path").text = file_path.replace("/" + file_path.get_file(), "")
	if file:
		var data = JSON.parse_string(file.get_as_text())
		file.close()
		if not data is Dictionary or not data.has("created") or not data.has("status") or not data.has("version"):
			return false
		new_project.tooltip_text = "Created at: " + data["created"]
		new_project.get_node("MarginContainer").get_node("HBoxContainer").get_node("HBoxContainer").get_node("Corrupted Icon").visible = data["status"] != "intact"
		new_project.get_node("MarginContainer").get_node("HBoxContainer").get_node("HBoxContainer").get_node("Unsupported Version Icon").visible = data["version"] != current_version
		new_project.get_node("MarginContainer").get_node("HBoxContainer").get_node("HBoxContainer").get_node("Unsupported Version Icon").tooltip_text = "Unsupported Version: " + data["version"]
	else:
		new_project.get_node("MarginContainer").get_node("HBoxContainer").get_node("HBoxContainer").get_node("File Is Missing").visible = true
	
	container.add_child(new_project)
	return true

func add_project(file_path: String):
	if file_path.get_extension() != "project":
		return
	
	var projects_file: FileAccess = FileAccess.open("Projects.json", FileAccess.READ_WRITE)
	if projects_file:
		var projects = JSON.parse_string(projects_file.get_as_text())
		if projects is Array and not file_path in projects and create_project_button(file_path):
			projects.append(file_path)
			projects_file.store_string(JSON.stringify(projects))
	projects_file.close()
