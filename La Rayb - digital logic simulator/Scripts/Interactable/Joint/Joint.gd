extends Interactable
class_name Joint

@onready var sprite: Sprite2D = $Sprite2D
@onready var radius: float = sprite.texture.get_width() * sprite.scale.x * 0.5

enum Gender{male, female} # male for output, female for input

var gender: Gender
var holder: BoardComponent = null
var attached_cables: Array[Cable] = []

var value_changed: Callable

func _ready():
	super()
	
	detach = func():
		if not is_picked:
			for cable in attached_cables:
				if cable.point_B == self:
					cable.point_A.attached_cables.erase(cable)
				else:
					cable.point_B.attached_cables.clear()
				cable.free()
			attached_cables.clear()

func grab_cables() -> void:
	if gender == Gender.female:
		if attached_cables.size():
			attached_cables[0].move_point(attached_cables[0].points_count()-1, global_position)
	else:
		for cable in attached_cables:
			var displacement: Vector2 = global_position - cable.straight_points[0]
			cable.move_point(0, global_position)
			if cable.point_B.holder.is_picked or cable.point_B.holder.is_dragged:
				var index: int = 1
				while index < cable.points_count()-1:
					cable.straight_points[index] += displacement
					index += 1
