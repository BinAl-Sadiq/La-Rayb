extends Object
class_name Functional_Tree

var function_name# might be of type String or Pair
var root_node: Functional_Node = null

func _init(_function_name, _root_node: Functional_Node):
	function_name = _function_name
	root_node = _root_node

func deep_copy_to_stack() -> Array[Functional_Node]:
	var function_stack: Array[Functional_Node] = []
	var undiscovered_pairs: Array[Array] = [[Functional_Node.new("", null), root_node]]
	var discovered_pairs: Array[Array] = []
	
	while undiscovered_pairs.size() > 0:
		var current = undiscovered_pairs.pop_front() as Array[Functional_Node]
		function_stack.push_back(current[0])
		if current[1].determinant == "^":
			current[0].determinant = "^"
		else:
			current[0].determinant = current[1].determinant
			current[0].value = current[1].value
		discovered_pairs.push_back(current)
		for next in current[1].next_nodes:
			current[0].next_nodes.push_back(Functional_Node.new("", null))
			undiscovered_pairs.push_back([current[0].next_nodes.back(), next])
	
	for p in discovered_pairs:
		if p[0].determinant == "^":
			for pp in discovered_pairs:
				if p[1].value == pp[1]:
					p[0].value = pp[0]
	
	return function_stack
