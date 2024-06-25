extends MarginContainer
class_name DecisionButtons

static var instance: DecisionButtons = null

@export var Add_Project_FileDialog: FileDialog = null
@export var remove_button: Button = null
@export var run_button: Button = null
@export var new_project_window: Window = null

var selected_project_button: Button = null

func _ready():
	instance = self
	
	get_viewport().transparent_bg = true
	
	Add_Project_FileDialog.file_selected.connect(ProjectsList.instance.add_project)

func _on_new_pressed():
	new_project_window.popup()

func _on_add_pressed():
	Add_Project_FileDialog.popup()

func _on_remove_pressed():
	if FileAccess.file_exists("Projects.json"):
		var projects_file: FileAccess = FileAccess.open("Projects.json", FileAccess.READ)
		if projects_file:
			var projects = JSON.parse_string(projects_file.get_as_text())
			projects_file.close()
			var project_name: String = selected_project_button.get_node("MarginContainer").get_node("HBoxContainer").get_node("VBoxContainer").get_node("Project name").text
			var project_path: String = selected_project_button.get_node("MarginContainer").get_node("HBoxContainer").get_node("VBoxContainer").get_node("Project path").text
			projects_file = FileAccess.open("Projects.json", FileAccess.WRITE)
			if projects_file and projects is Array and (project_path + "/" + project_name + ".project") in projects:
				projects.erase(project_path + "/" + project_name + ".project")
				projects_file.store_string(JSON.stringify(projects))
		projects_file.close()
	
	selected_project_button.free()
	remove_button.disabled = true
	run_button.disabled = true

func _on_run_pressed():
	var project_file: String = selected_project_button.get_node("MarginContainer").get_node("HBoxContainer").get_node("VBoxContainer").get_node("Project path").text
	project_file += "/" + selected_project_button.get_node("MarginContainer").get_node("HBoxContainer").get_node("VBoxContainer").get_node("Project name").text + ".project"
	OS.create_process("./La Rayb - digitla logic simulator.exe", ["-project_file=" + project_file])
	get_tree().quit()

func select_project(project_button: Button):
	selected_project_button = project_button
	remove_button.disabled = false
	var con = project_button.get_node("MarginContainer").get_node("HBoxContainer").get_node("HBoxContainer")
	run_button.disabled = con.get_node("Corrupted Icon").visible or con.get_node("Unsupported Version Icon").visible
