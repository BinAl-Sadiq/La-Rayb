extends BaseWindow

@export var IC_name: LineEdit = null
@export var IC_Color: ColorPickerButton = null
@export var custom_ICs_Window: Custom_ICs_Window = null

func save_board_as_an_IC() -> void:
	var ic_name: String = Utilities.trim(IC_name.text)
	
	if ic_name == "":
		Utilities.instance.trigger_error_msbox("Invalid Name!")
	elif DataManagement.instance.Functions.get(ic_name):
		Utilities.instance.trigger_error_msbox("Used Name!")
	else:
		var functionals = create_functional_trees()
		if functionals:
			DataManagement.instance.Functions[ic_name] = [functionals[0], functionals[1], functionals[2], IC_Color.color]
			DataManagement.instance.save_IC(ic_name)
		
		_on_close_requested()

func create_functional_trees():
	var functional_trees: Array[Functional_Tree] = []
	var functional_colors: Array = []
	var inputs_names: Array[String] = []
	
	for led in BoardsController.instance.selected_board.LEDs:
		if led.pin.attached_cables.size():
			var visited_joints: Array[Pair] = []
			var created_nodes: Array[Functional_Node] = []
			var root_node: Functional_Node = Functional_Node.new("", null) #just allocating memory
			if function_tree_builder(root_node, Pair.new(led.pin.attached_cables[0].point_A, null), visited_joints, created_nodes, inputs_names):
				if led.name.contains("$"):
					var pair = Pair.new(led.name.left(led.name.find("$", 1)+1), int(led.name.get_slice("$", 2)))
					functional_trees.push_back(Functional_Tree.new(pair, root_node))
					functional_colors.push_back(null)
				else:
					functional_trees.push_back(Functional_Tree.new(led.name, root_node))
					functional_colors.push_back(led.pin.attached_cables[0].point_A.output_color)
				
				var stack: Array[Functional_Node] = [root_node]
				while stack.size() > 0:
					var current = stack.pop_front() as Functional_Node
					for next in current.next_nodes:
						stack.push_back(next)
		else:
			Utilities.instance.trigger_error_msbox("LEDs Have To Be Totally Connected!")
			return null
	return [functional_trees, functional_colors, inputs_names]

#The "current_joint" and the Joints in the "visited_joints" Array must have "Gender" value of "Gender.male"
func function_tree_builder(current_node: Functional_Node, current_joint: Pair, visited_joints: Array[Pair], created_nodes: Array[Functional_Node], inputs_names: Array[String]) -> bool:
	#check if the "current_pin" has been visited before.
	#If so, return a "Function_Node" that holds a reference to the "Function_Node" that created for this "current_pin".
	var visited_index: int = 0
	for visited_joint in visited_joints:
		if visited_joint.A == current_joint.A:
			if visited_joint.A is Pin or (visited_joint.B == current_joint.B):
				current_node.determinant = "^"
				current_node.value = created_nodes[visited_index]
				return true
		visited_index += 1
	
	visited_joints.push_back(current_joint)
	created_nodes.push_back(current_node)
	
	if current_joint.A.holder is IO_Component:
		if current_joint.A.holder.name.contains("$"):
			current_node.determinant = current_joint.A.holder.name.left(current_joint.A.holder.name.find("$", 1)+1)
			current_node.value = Pair.new(int(current_joint.A.holder.name.get_slice("$", 2)), current_joint.A.high)
			if not inputs_names.has(current_node.determinant):
				inputs_names.append(current_node.determinant)
		else:
			current_node.determinant = current_joint.A.holder.name
			current_node.value = current_joint.A.high
			if not inputs_names.has(current_node.determinant):
				inputs_names.append(current_node.determinant)
	elif current_joint.A.holder is IC:
		#get the corresponding "Functional_Tree" for the "current_pin"
		var desired_tree: Functional_Tree = null
		var functions_trees = DataManagement.instance.Functions[current_joint.A.holder.ic_name][0]
		for tree in functions_trees:
			if tree.function_name is Pair:
				if current_joint.A is Port and tree.function_name.A + str(tree.function_name.B) == current_joint.A.holder.original_names[current_joint.A] + str(current_joint.B):
					desired_tree = tree
					break
			else:
				if tree.function_name == current_joint.A.holder.original_names[current_joint.A]:
					desired_tree = tree
					break
		
		var undiscovered_pairs: Array[Pair] = [Pair.new(current_node, desired_tree.root_node)]
		var discovered_pairs: Array[Pair] = []
		while undiscovered_pairs.size() > 0:
			var pair = undiscovered_pairs.pop_front()
			if pair.B.determinant == "*" or pair.B.determinant == "|" or pair.B.determinant == "!":
				pair.A.determinant = pair.B.determinant
				pair.A.value = pair.B.value
			elif pair.B.determinant == "^":
				pair.A.determinant = "^"
			else:
				var desired_input = current_joint.A.holder.get_input_by_name(pair.B.determinant) if pair.B.value is Pair else current_joint.A.holder.get_input_by_name(pair.B.determinant)
				if not desired_input.attached_cables.size():
					Utilities.instance.trigger_error_msbox("Bad Connection Detected!")
					return false
				if not function_tree_builder(pair.A, Pair.new(desired_input.attached_cables[0].point_A, pair.B.value.A if pair.B.value is Pair else null), visited_joints, created_nodes, inputs_names):
					return false
			
			for next in pair.B.next_nodes:
				pair.A.next_nodes.push_back(Functional_Node.new("", null)) #just allocating memory
				undiscovered_pairs.push_back(Pair.new(pair.A.next_nodes.back(), next))
			
			discovered_pairs.push_back(pair)
			
		for p in discovered_pairs:
			if p.B.determinant == "^" and p.A.value == null:
				for pp in discovered_pairs:
					if pp.B == p.B.value:
						p.A.value = pp.A
						break
	elif current_joint.A.holder is Distributor:
		var input_pair: Pair = current_joint.A.holder.linkers[current_joint.A] if current_joint.A is Pin else current_joint.A.holder.linkers[current_joint.A][current_joint.B]
		if not input_pair:
			Utilities.instance.trigger_error_msbox("There Are Joints In The Distributor: " + "\"" + current_joint.A.holder.name + "\" That Are Not Linked!")
			return false
		if not input_pair.A.attached_cables.size():
			Utilities.instance.trigger_error_msbox("The Input Pin: " + input_pair.A.name + " In Distributor: " + "\"" + current_joint.A.holder.name + "\" Is Disconnected!")
			return false
		return function_tree_builder(current_node, Pair.new(input_pair.A.attached_cables[0].point_A, null if input_pair.A is Pin else input_pair.B), visited_joints, created_nodes, inputs_names)
	
	return true

func _on_about_to_popup():
	super()
	
	IC_name.grab_focus()
	IC_name.text = ""
	IC_Color.color = Color.WHITE

func _on_window_input(event):
	super(event)
	
	if event is InputEventKey:
		if event.keycode == KEY_ENTER:
			save_board_as_an_IC()
