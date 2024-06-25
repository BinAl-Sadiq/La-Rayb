extends Window

@export var new_project_folder_FileDialog: FileDialog = null
@export var name_LineEdit: LineEdit = null
@export var path_LineEdit: LineEdit = null

func _ready():
	about_to_popup.connect(func(): name_LineEdit.text = ""; path_LineEdit.text = "")
	new_project_folder_FileDialog.dir_selected.connect(func(path): path_LineEdit.text = path)

func _on_create_new_pressed():
	var project_name: String = trim(name_LineEdit.text)
	var project_path: String = path_LineEdit.text + "/" + project_name + ".project"
	if project_name != "" and DirAccess.dir_exists_absolute(path_LineEdit.text):
		for file in DirAccess.get_files_at(path_LineEdit.text + "/"):
			if file.get_extension() == "project":
				return
		
		var project_file: FileAccess = FileAccess.open(project_path, FileAccess.WRITE)
		project_file.store_string(JSON.stringify({"created":Time.get_date_string_from_system() + " " + Time.get_time_string_from_system(),"status":"intact","version":ProjectsList.instance.current_version}))
		project_file.close()
		
		DirAccess.make_dir_absolute(path_LineEdit.text + "/ICs")
		var and_gate_file: FileAccess = FileAccess.open(path_LineEdit.text + "/ICs/and.IC", FileAccess.WRITE)
		var and_gate: Array = [
			[
				{
					"output_color":[0.3098,0.4863,0.8314],#default high output color
					"root":{
						"determinant":"*",#indicating and(*)
						"id":"<Object#58569262427>",
						"next":[
							{
								"determinant":"A",
								"id":"<Object#58602817370>",
								"next":[
									
								],
								"value":false
							},
							{
								"determinant":"B",
								"id":"<Object#58619594587>",
								"next":[
									
								],
								"value":false
							}
						]
						,"value":false
					},
					"tree name":"output"
				}
			],
			["A","B"],1,1,1
		]
		and_gate_file.store_string(JSON.stringify(and_gate))
		and_gate_file.close()
		var or_gate_file: FileAccess = FileAccess.open(path_LineEdit.text + "/ICs/or.IC", FileAccess.WRITE)
		var or_gate: Array = [
			[
				{
					"output_color":[0.3098,0.4863,0.8314],#default high output color
					"root":{
						"determinant":"|",#indicating or
						"id":"<Object#58569262427>",
						"next":[
							{
								"determinant":"A",
								"id":"<Object#58602817370>",
								"next":[
									
								],
								"value":false
							},
							{
								"determinant":"B",
								"id":"<Object#58619594587>",
								"next":[
									
								],
								"value":false
							}
						]
						,"value":false
					},
					"tree name":"output"
				}
			],
			["A","B"],1,1,1
		]
		or_gate_file.store_string(JSON.stringify(or_gate))
		or_gate_file.close()
		var not_gate_file: FileAccess = FileAccess.open(path_LineEdit.text + "/ICs/not.IC", FileAccess.WRITE)
		var not_gate: Array = [
			[
				{
					"output_color":[0.3098,0.4863,0.8314],#default high output color
					"root":{
						"determinant":"!",#indicating not
						"id":"<Object#58569262427>",
						"next":[
							{
								"determinant":"A",
								"id":"<Object#58602817370>",
								"next":[
									
								],
								"value":false
							},
						]
						,"value":false
					},
					"tree name":"output"
				}
			],
			["A"],1,1,1
		]
		not_gate_file.store_string(JSON.stringify(not_gate))
		not_gate_file.close()
		
		DirAccess.make_dir_absolute(path_LineEdit.text + "/Boards")
		var main_board_file: FileAccess = FileAccess.open(path_LineEdit.text + "/Boards/main.board", FileAccess.WRITE)
		var main_board: Dictionary = {
			"board components":{
				
			},
			"camera position":[
				0.0,0.0
			],
			"camera zoom":1.0,
			"connections":[
				
			],
			"name":"main",
			"version":ProjectsList.instance.current_version
		}
		main_board_file.store_string(JSON.stringify(main_board))
		main_board_file.close()
		
		DirAccess.make_dir_absolute(path_LineEdit.text + "/Captured Frames")
	
	ProjectsList.instance.add_project(project_path)
	
	hide()

func _on_browse_pressed():
	new_project_folder_FileDialog.popup()

func trim(string: String) -> String:
	while string.length() > 1 and string[0] == " ":
		string = string.right(string.length() - 1)
	while string.length() and string.right(1) == " ":
		string = string.left(string.length() - 1)
	return string
