extends Node2D
class_name Compass

var destination: AreaBox = null

static func create(area: AreaBox) -> Compass:
	var new_compass = BoardsController.instance.compass_PackedScene.instantiate()
	new_compass.destination = area
	area.motherBoard.add_child(new_compass)
	
	return new_compass

func _process(_delta):
	steer()

func steer() -> void:
	var dest_pos: Vector2 = destination.sprite.global_position - destination.motherBoard.camera.global_position
	var right_bottom: Vector2 = destination.motherBoard.camera.get_viewport_rect().size / destination.motherBoard.camera.zoom
	
	if dest_pos.x + destination.h_width > 0 and dest_pos.y + destination.h_height > 0 and dest_pos.x - destination.h_width < right_bottom.x and dest_pos.y - destination.h_height < right_bottom.y:
		visible = false
	else:
		visible = true
	
		#set x position
		if dest_pos.x > right_bottom.x:
			global_position.x = BoardsController.instance.global_position.x + BoardsController.instance.get_rect().size.x
		elif dest_pos.x < 0:
			global_position.x = BoardsController.instance.global_position.x
		else:
			global_position.x = BoardsController.instance.global_position.x + BoardsController.instance.get_rect().size.x * dest_pos.x / right_bottom.x

		#set y position
		if dest_pos.y > right_bottom.y:
			global_position.y = BoardsController.instance.global_position.y + BoardsController.instance.get_rect().size.y
		elif dest_pos.y < 0:
			global_position.y = BoardsController.instance.global_position.y
		else:
			global_position.y = BoardsController.instance.global_position.y + BoardsController.instance.get_rect().size.y * dest_pos.y / right_bottom.y

		#set rotation
		rotation = (dest_pos - right_bottom / 2).angle() + PI * 0.5
