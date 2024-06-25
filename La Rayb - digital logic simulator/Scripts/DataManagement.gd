extends Control
class_name DataManagement

const current_version: String = "1.0.0"
var project_path: String = ""

static var instance: DataManagement = null

var Functions: Dictionary = {} #{"IC name" : [functional_trees, functional_colors, inputs_names, IC_color]}
var saved_boards: Array[String] = []

func _init() -> void:
	instance = self

func _ready():
	var project: String = ""
	for arg in OS.get_cmdline_args():
		if arg.left(14) == "-project_file=":
			project = arg.right(arg.length() - 14)
	if project != "":
		load_project(project)
	else:
		load_project("Testing Project Folder/Testing Project.project")

func save_IC(IC_name: String) -> void:
	var stored_trees: Array = []
	for idx in Functions[IC_name][0].size():
		var functional_tree = Functions[IC_name][0][idx]
		var functional_color = Functions[IC_name][1][idx]
		@warning_ignore("incompatible_ternary")
		var tree: Dictionary = {"tree name" : [functional_tree.function_name.A, functional_tree.function_name.B] if functional_tree.function_name is Pair else functional_tree.function_name, "root" : {}, "output_color" : [functional_color.r, functional_color.g, functional_color.b] if functional_color else null}
		var to_visit: Array[Pair] = [Pair.new(tree["root"], functional_tree.root_node)]
		while to_visit.size():
			var current: Pair = to_visit.pop_back()
			current.A["id"] = current.B
			current.A["value"] = [current.B.value.A, current.B.value.B] if current.B.value is Pair else current.B.value
			current.A["determinant"] = current.B.determinant
			current.A["next"] = Array()
			for next in current.B.next_nodes:
				current.A["next"].append({})
				to_visit.push_back(Pair.new(current.A["next"].back(), next))
		stored_trees.append(tree)
	var data_file = FileAccess.open(project_path + "ICs/" + IC_name + ".IC", FileAccess.WRITE)
	if data_file:
		data_file.store_string(JSON.stringify([stored_trees, Functions[IC_name][2], Functions[IC_name][3].r, Functions[IC_name][3].g, Functions[IC_name][3].b]))
	else:
		Utilities.abort_for_corruption()

func delete_IC(IC_name: String) -> void:
#	DirAccess.remove_absolute(project_path + "ICs/" + IC_name + ".IC")
	OS.move_to_trash(project_path + "ICs/" + IC_name + ".IC")

func load_project(input_project_path: String) -> void:
	if not FileAccess.file_exists(input_project_path):
		Utilities.abort()
	
	var project_file: String = input_project_path.get_file()
	project_path = input_project_path.left(input_project_path.length() - project_file.length())
	if not (DirAccess.dir_exists_absolute(project_path + "Boards") and FileAccess.file_exists(project_path + "ICs/and.IC") and FileAccess.file_exists(project_path + "ICs/or.IC") and FileAccess.file_exists(project_path + "ICs/not.IC")):
		Utilities.abort_for_corruption()
	else:
		var files = DirAccess.get_files_at(project_path + "Boards/")
		for file in files:
			saved_boards.append(file)
	
	var file = FileAccess.open(project_path + project_file, FileAccess.READ)
	if file:
		var project: Dictionary = JSON.parse_string(file.get_as_text())
		if Utilities.ACE(project, "version", [TYPE_STRING]) == current_version:
			DisplayServer.window_set_title("La Rayb - " + project_file.substr(0, project_file.length() - 8))
			load_ICs()
			BoardsController.instance.selected_board = open_board("main.board")
			if not BoardsController.instance.selected_board:
				Utilities.abort_for_corruption()
		else:#for unsupported versions
			Utilities.abort()
	else:
		Utilities.abort()

func load_IC(file_name: String) -> void:
	var file = FileAccess.open(project_path + "ICs/" + file_name, FileAccess.READ)
	if not file:
		Utilities.abort_for_corruption()
	var IC_data = JSON.parse_string(file.get_as_text())
	var IC_trees: Array = IC_data[0]
	var IC_Functional_trees = []
	var IC_output_colors = []
	var new_nodes: Dictionary = {}
	for IC_tree in IC_trees:
		var val = Utilities.ACE(Utilities.ACE(IC_tree,"root",[TYPE_DICTIONARY]),"value",[TYPE_BOOL,TYPE_STRING,TYPE_ARRAY])
		var to_visit: Array[Pair] = [Pair.new(Utilities.ACE(IC_tree,"root",[TYPE_DICTIONARY]), Functional_Node.new(Utilities.ACE(Utilities.ACE(IC_tree,"root",[TYPE_DICTIONARY]),"determinant",[TYPE_STRING]), Pair.new(val[0] ,val[1]) if val is Array else val))]
		var tree_name = Utilities.ACE(IC_tree,"tree name",[TYPE_STRING, TYPE_ARRAY])
		IC_Functional_trees.append(Functional_Tree.new(tree_name if tree_name is String else Pair.new(tree_name[0], int(tree_name[1])), to_visit[0].B))
		var output_color = Utilities.ACE(IC_tree,"output_color",[TYPE_ARRAY, TYPE_NIL])
		@warning_ignore("incompatible_ternary")
		IC_output_colors.append(Color(output_color[0],output_color[1],output_color[2]) if output_color else null)
		while to_visit.size():
			var current_pair = to_visit.pop_front()
			new_nodes[Utilities.ACE(current_pair.A,"id",[TYPE_STRING])] = current_pair.B
			for child in Utilities.ACE(current_pair.A,"next",[TYPE_ARRAY]):
				var extracted_value = Utilities.ACE(child,"value",[TYPE_BOOL,TYPE_STRING,TYPE_ARRAY])
				var value = Pair.new(extracted_value[0], extracted_value[1]) if extracted_value is Array else extracted_value
				var child_node = Functional_Node.new(Utilities.ACE(child,"determinant",[TYPE_STRING]), value)
				current_pair.B.next_nodes.append(child_node)
				to_visit.push_back(Pair.new(child, child_node))
	for key in new_nodes:
		if new_nodes[key].determinant == "^":
			new_nodes[key].value = new_nodes[new_nodes[key].value]
	var IC_name: String = file_name.left(file_name.length()-3)
	Functions[IC_name] = [IC_Functional_trees, IC_output_colors, IC_data[1], Color(IC_data[2], IC_data[3], IC_data[4])]

func load_ICs() -> void:
	if not DirAccess.dir_exists_absolute(project_path + "ICs"):
		Utilities.abort_for_corruption()
	var files_names = DirAccess.get_files_at(project_path + "ICs/")
	for file_name in files_names:
		load_IC(file_name)

func save_current_board() -> void:
	var data: Dictionary = {
		"version" : current_version,
		"name" : BoardsController.instance.selected_board.name,
		"camera position" : [BoardsController.instance.selected_board.camera.global_position.x, BoardsController.instance.selected_board.camera.global_position.y],
		"camera zoom" : BoardsController.instance.selected_board.camera.zoom.x,
		"board components" : {},
		"connections" : Array()
	}
	for c in BoardsController.instance.selected_board.board_components:
		var json_component: Dictionary = {
			"name" : c.label.text if c is IC else c.name,
			"position" : [c.global_position.x, c.global_position.y],
			"children" : Array()
		}
		for child in c.children:
			json_component["children"].append(child)
		if c is AreaBox:
			json_component["type"] = "AreaBox"
			json_component["attributes"] = {"color" : [c.sprite.modulate.r, c.sprite.modulate.g, c.sprite.modulate.b, c.sprite.modulate.a]}
		elif c is Switch:
			json_component["attributes"] = {
				"output color" : [c.pin.output_color.r, c.pin.output_color.g, c.pin.output_color.b]
			}
			if c is Clock:
				json_component["type"] = "Clock"
				json_component["attributes"]["color"] = [c.sprite.modulate.r, c.sprite.modulate.g, c.sprite.modulate.b]
				json_component["attributes"]["clock_rate"] = c.clock_rate
			else:
				json_component["type"] = "Switch"
		elif c is Distributor or c is IC:
			json_component["attributes"] = {
				"color" : [c.sprite.modulate.r, c.sprite.modulate.g, c.sprite.modulate.b],
				"inputs" : [],
				"outputs" : [],
			}
			for inp in c.inputs:
				var input_dir = {"name" : inp.name}
				if inp is Pin:
					input_dir["type"] = "pin"
				else:
					input_dir["type"] = "port"
					if c is Distributor:
						input_dir["buffer size"] = inp.values_buffer.size()
				json_component["attributes"]["inputs"].append(input_dir)
			for out in c.outputs:
				var output_dir = {"name" : out.name}
				if out is Pin:
					output_dir["type"] = "pin"
					output_dir["output color"] = [out.output_color.r, out.output_color.g, out.output_color.b]
				else:
					output_dir["type"] = "port"
					if c is Distributor:
						output_dir["buffer size"] = out.values_buffer.size()
				json_component["attributes"]["outputs"].append(output_dir)
			if c is Distributor:
				json_component["type"] = "Distributor"
				var named_linkers = {}
				for key in c.linkers:
					if key is Pin:
						var pair = c.linkers[key]
						named_linkers[key.name] = (pair.A.name if pair.A is Pin else [pair.A.name, pair.B]) if pair else null
					else:
						var arr: Array = []
						arr.resize(c.linkers[key].size())
						var index: int = 0
						for pair in c.linkers[key]:
							if pair:
								arr[index] = pair.A.name if pair.A is Pin else [pair.A.name, pair.B]
							else:
								arr[index] = null
							index += 1
						named_linkers[key.name] = arr
				json_component["attributes"]["linkers"] = named_linkers
			else:
				json_component["type"] = "IC"
				json_component["attributes"]["ic_name"] = c.ic_name
		elif c is LED:
			json_component["type"] = "LED"
		
		data["board components"][c] = json_component
	
	for cable in BoardsController.instance.selected_board.cables:
		var points: Array = []
		for point in cable.straight_points:
			points.append([point.x, point.y])
		data["connections"].append({"point_A" : cable.point_A.name, "holder_A" : cable.point_A.holder, "point_B" : cable.point_B.name, "holder_B" : cable.point_B.holder, "points" : points})
	
	if not FileAccess.file_exists(project_path + "Boards/" + BoardsController.instance.selected_board.name + ".board"):
		saved_boards.append(BoardsController.instance.selected_board.name + ".board")
	var data_file = FileAccess.open(project_path + "Boards/" + BoardsController.instance.selected_board.name + ".board", FileAccess.WRITE)
	if data_file:
		data_file.store_string(JSON.stringify(data))
		data_file.close()
		Utilities.instance.trigger_success_msbox("Saved successfully")
	else:
		Utilities.abort_for_corruption()

func open_board(board_name: String) -> Board:
	var temp_name: String = "♠♣♠" + str(randi())
	var board: Board = null
	var data_file = FileAccess.open(project_path + "Boards/" + board_name, FileAccess.READ)
	if not data_file:
		Utilities.abort_for_corruption()
	var data = JSON.parse_string(data_file.get_as_text()) as Dictionary
	data_file.close()
	var new_components: Dictionary = {}
	if current_version == Utilities.ACE(data, "version", [TYPE_STRING]):
		board = BoardsController.instance.create_board(Utilities.ACE(data, "name", [TYPE_STRING]))
		board.camera.global_position = Vector2(Utilities.ACE(data, "camera position", [TYPE_ARRAY])[0], Utilities.ACE(data, "camera position", [TYPE_ARRAY])[1])
		board.camera.zoom = Vector2(Utilities.ACE(data, "camera zoom", [TYPE_FLOAT]), Utilities.ACE(data, "camera zoom", [TYPE_FLOAT]))
		#create components
		for component_key in Utilities.ACE(data, "board components", [TYPE_DICTIONARY]):
			var component_values = Utilities.ACE(Utilities.ACE(data, "board components", [TYPE_DICTIONARY]), component_key, [TYPE_DICTIONARY])
			var component: BoardComponent
			var type = Utilities.ACE(component_values,"type", [TYPE_STRING])
			var attributes = null if type == "LED" else Utilities.ACE(component_values, "attributes", [TYPE_DICTIONARY])
			
			if type == "AreaBox":
				component = BoardsController.instance.areaBox_scene.instantiate() as AreaBox
				BoardsController.instance.selected_board.insert(component)
				var color = Utilities.ACE(attributes, "color", [TYPE_ARRAY])
				component.set_color(Color(color[0], color[1], color[2], color[3]))
				component.set_component_name(temp_name)#temp...
			elif type == "Switch":
				component = BoardsController.instance.switch_scene.instantiate() as Switch
				BoardsController.instance.selected_board.insert(component)
				var out_color = Utilities.ACE(attributes, "output color", [TYPE_ARRAY])
				component.pin.output_color = Color(out_color[0], out_color[1], out_color[2])
				component.set_component_name("inp:" + temp_name)#temp...
			elif type == "Clock":
				component = BoardsController.instance.clock_scene.instantiate() as Clock
				BoardsController.instance.selected_board.insert(component)
				var out_color = Utilities.ACE(attributes, "output color", [TYPE_ARRAY])
				var color = Utilities.ACE(attributes, "color", [TYPE_ARRAY])
				component.pin.output_color = Color(out_color[0], out_color[1], out_color[2])
				component.set_color(Color(color[0], color[1], color[2]))
				component.clock_rate = Utilities.ACE(attributes, "clock_rate", [TYPE_FLOAT])
				component.set_component_name("inp:" + temp_name)#temp...
			elif type == "Distributor":
				component = BoardsController.instance.distributor_scene.instantiate() as Distributor
				BoardsController.instance.selected_board.insert(component)
				var color = Utilities.ACE(attributes, "color", [TYPE_ARRAY])
				component.sprite.modulate = Color(color[0], color[1], color[2])
				component.set_component_name(temp_name)#temp...
			elif type == "IC":
				component = BoardsController.instance.ic_scene.instantiate() as IC
				component.ic_name = Utilities.ACE(attributes, "ic_name", [TYPE_STRING])
				BoardsController.instance.selected_board.insert(component)
				var color = Utilities.ACE(attributes, "color", [TYPE_ARRAY])
				component.set_color(Color(color[0], color[1], color[2]))
				component.set_component_name(temp_name)#temp...
			elif type == "LED":
				component = BoardsController.instance.LED_scene.instantiate() as LED
				BoardsController.instance.selected_board.insert(component)
				component.set_component_name("out:" + temp_name)#temp...
			
			new_components[component_key] = component
		
		#set positions, rename BoardComponents, rename Joints, and set distributor's linkers values
		for component_key in Utilities.ACE(data,"board components",[TYPE_DICTIONARY]):
			var component_values = Utilities.ACE(Utilities.ACE(data,"board components",[TYPE_DICTIONARY]),component_key,[TYPE_DICTIONARY])
			var type = Utilities.ACE(component_values,"type",[TYPE_STRING])
			var attributes = null if type == "LED" else Utilities.ACE(component_values, "attributes",[TYPE_DICTIONARY])
			var component: BoardComponent = new_components[component_key]
			
			component.global_position = Vector2(Utilities.ACE(component_values,"position",[TYPE_ARRAY])[0], Utilities.ACE(component_values,"position",[TYPE_ARRAY])[1])
			component.set_component_name(Utilities.ACE(component_values,"name",[TYPE_STRING]))
			
			if type == "IC":
				#give the inputs/outputs temporary names to prevent names conflict while renaming
				for inp in component.inputs:
					inp.name = "inp:" + temp_name
				for out in component.outputs:
					out.name = "out:" + temp_name
				
				var index: int = 0
				for inp in Utilities.ACE(attributes,"inputs",[TYPE_ARRAY]):
					var inp_name: String = Utilities.ACE(inp,"name",[TYPE_STRING])
					component.set_input_name(index, inp_name)
					index += 1
				index = 0
				for out in Utilities.ACE(attributes,"outputs",[TYPE_ARRAY]):
					component.set_output_name(index, Utilities.ACE(out,"name",[TYPE_STRING]))
					var out_color = Utilities.ACE(out,"output color",[TYPE_ARRAY])
					component.outputs[index].output_color = Color(out_color[0], out_color[1], out_color[2])
					index += 1
			elif type == "Distributor":
				for inp in Utilities.ACE(attributes,"inputs",[TYPE_ARRAY]):
					var new_joint: Joint = component.add_joint(Joint.Gender.female, Utilities.ACE(inp,"type",[TYPE_STRING]) == "pin")
					component.rename_joint(new_joint, Utilities.ACE(inp,"name",[TYPE_STRING]))
					if new_joint is Port:
						new_joint.rescale_buffer(Utilities.ACE(inp,"buffer size",[TYPE_FLOAT]))
				for out in Utilities.ACE(attributes,"outputs",[TYPE_ARRAY]):
					var new_joint: Joint = component.add_joint(Joint.Gender.male, Utilities.ACE(out,"type",[TYPE_STRING]) == "pin")
					if new_joint is Pin:
						var out_color = Utilities.ACE(out,"output color",[TYPE_ARRAY])
						new_joint.output_color = Color(out_color[0], out_color[1], out_color[2])
					else:
						new_joint.rescale_buffer(Utilities.ACE(out,"buffer size",[TYPE_FLOAT]))
					component.rename_joint(new_joint, Utilities.ACE(out,"name",[TYPE_STRING]))
				for out in component.outputs:
					if out is Pin:
						var named_linker = Utilities.ACE(Utilities.ACE(attributes,"linkers",[TYPE_DICTIONARY]),out.name,[TYPE_ARRAY, TYPE_STRING, TYPE_NIL])
						if named_linker:
							var inp = component.get_input_by_name(named_linker if named_linker is String else named_linker[0])
							component.linkers[out] = Pair.new(inp, null if inp is Pin else named_linker[1])
						else:
							component.linkers[out] = null
					else:
						var named_linkers = Utilities.ACE(Utilities.ACE(attributes,"linkers",[TYPE_DICTIONARY]),out.name,[TYPE_ARRAY])
						var index: int = 0
						var arr = []
						arr.resize(named_linkers.size())
						for named_linker in named_linkers:
							if named_linker:
								var inp = component.get_input_by_name(named_linker if named_linker is String else named_linker[0])
								arr[index] = Pair.new(inp, null if inp is Pin else named_linker[1])
							else:
								arr[index] = null
							index += 1
						component.linkers[out] = arr
		
		#add children
		for component_key in Utilities.ACE(data,"board components",[TYPE_DICTIONARY]):
			var component_values = Utilities.ACE(Utilities.ACE(data,"board components",[TYPE_DICTIONARY]),component_key,[TYPE_DICTIONARY])
			var component: BoardComponent = new_components[component_key]
			for child in Utilities.ACE(component_values,"children",[TYPE_ARRAY]):
				component.insert_child(new_components[child])
		
		#set connections
		for connection in Utilities.ACE(data,"connections",[TYPE_ARRAY]):
			var point_B: Joint
			var holder_B: BoardComponent = new_components[Utilities.ACE(connection,"holder_B",[TYPE_STRING])]
			if holder_B is LED:
				point_B = holder_B.pin
			elif holder_B is IC or holder_B is Distributor:
				point_B = holder_B.get_input_by_name(Utilities.ACE(connection,"point_B",[TYPE_STRING]))
			
			var holder_A: BoardComponent = new_components[Utilities.ACE(connection,"holder_A",[TYPE_STRING])]
			if holder_A is Switch:
				holder_A.pin.connect_to(point_B, true)
			elif holder_A is IC or holder_A is Distributor:
				holder_A.get_output_by_name(Utilities.ACE(connection,"point_A",[TYPE_STRING])).connect_to(point_B, true)
			
			var points: PackedVector2Array = []
			for point in Utilities.ACE(connection,"points",[TYPE_ARRAY]):
				points.append(Vector2(point[0], point[1]))
			var cable: Cable = point_B.attached_cables.back()
			cable.straight_points = points
			cable.make_smooth()
	
	return board

func load_board_into_project(source: String) -> void:
	var destination: String = project_path + "Boards/" + source.get_file()
	if not FileAccess.file_exists(destination):
		if FileAccess.file_exists(source):
			DirAccess.copy_absolute(source, destination)
		else:
			Utilities.instance.trigger_error_msbox("The file: " + source + " does not exist!")
	else:
		Utilities.instance.trigger_error_msbox("The file: " + source + " is already included")

func load_IC_into_project(source: String) -> void:
	var destination: String = project_path + "ICs/" + source.get_file()
	if not FileAccess.file_exists(destination):
		if FileAccess.file_exists(source):
			DirAccess.copy_absolute(source, destination)
			load_IC(source.get_file())
		else:
			Utilities.instance.trigger_error_msbox("The file: " + source + " does not exist!")
	else:
		Utilities.instance.trigger_error_msbox("The file: " + source + " is already included")

func delete_board(board_name: String) -> void:
#	DirAccess.remove_absolute(project_path + "Boards/" + board_name)
	OS.move_to_trash(project_path + "Boards/" + board_name)
	saved_boards.erase(board_name)
