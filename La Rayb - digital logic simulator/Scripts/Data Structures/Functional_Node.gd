extends Object
class_name Functional_Node

var determinant: String = ""
var value
var next_nodes: Array[Functional_Node] = []

func _init(_determinant: String, _value):
	determinant = _determinant
	value = _value

func get_value() -> bool:
	return value.get_value() if determinant == "^" else (value.B if value is Pair else value)
