extends Sprite2D
class_name SelectionArea

@onready var initial_mouse_position: Vector2 = get_global_mouse_position()

func _process(_delta):
	var difference: Vector2 = get_global_mouse_position() - initial_mouse_position
	scale = difference / 50.0#50.0 is the width/height of the texture
	global_position = initial_mouse_position + 25 * scale
	(material as ShaderMaterial).set_shader_parameter("scale", scale.abs())
	
	if Input.is_action_just_released("mouse_left"):
		release()

func release() -> void:
	for component in BoardsController.instance.selected_board.board_components:
		if not component is AreaBox and collides_with(component):
			component.pick.call()
	call_deferred("free")

#AABB collision detector
func collides_with(other: BoardComponent) -> bool:
	var borders = scale.abs() * 25.0
	var self_left: float = global_position.x - borders.x
	var self_right: float = global_position.x + borders.x
	var self_top: float = global_position.y - borders.y
	var self_bottom: float = global_position.y + borders.y
	
	var other_left: float = other.global_position.x - other.h_width
	var other_right: float = other.global_position.x + other.h_width
	var other_top: float = other.global_position.y - other.h_height
	var other_bottom: float = other.global_position.y + other.h_height
	
	var other_V_edge_is_in: bool = self_left < other_left and self_right > other_left or self_left < other_right and self_right > other_right
	var other_H_edge_is_in: bool = self_top < other_top and self_bottom > other_top or self_top < other_bottom and self_bottom > other_bottom
	
	var self_V_edges_are_in: bool = other_left < self_left and other_left < self_right and other_right > self_left
	var self_H_edges_are_in: bool = other_top < self_top and other_top < self_bottom and other_bottom > self_bottom
	
	return other_V_edge_is_in and other_H_edge_is_in or self_V_edges_are_in and other_H_edge_is_in or self_H_edges_are_in and other_V_edge_is_in
