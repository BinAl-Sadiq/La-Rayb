extends Switch
class_name Clock

@onready var minute_hand: Sprite2D = $"Sprites Holder/Minute Hand Sprite2D"
@onready var hour_hand: Sprite2D = $"Sprites Holder/Hour Hand Sprite2D"
@onready var outlines: Sprite2D = $"Sprites Holder/Outlines Sprite2D"
@onready var spritesHolder: Node2D = $"Sprites Holder"

var clock_rate: float = 0.1
var scaler: float = 0.0

func _init():
	is_being_picked = func(point: Vector2):
		return point.x > global_position.x - h_width and point.x < global_position.x + h_width and point.y > global_position.y - h_height and point.y < global_position.y + h_height

	clone = func():
		var new_Clock = BoardsController.instance.clock_scene.instantiate() as Clock
		new_Clock.clock_rate = clock_rate
		BoardsController.instance.selected_board.insert(new_Clock)
		new_Clock.pin.output_color = pin.output_color
		new_Clock.set_color(sprite.modulate)
		new_Clock.move_to(global_position)
		return new_Clock

func _ready():
	sprite = $"Sprites Holder/Sprite2D"
	
	super()
	
	pin.visible = false

func _process(delta):
	minute_hand.rotation += delta * 0.6
	hour_hand.rotation += delta * 0.01
	scaler += delta
	spritesHolder.scale = Vector2.ONE * 0.85 + Vector2.ONE * abs(sin(scaler)) * 0.15
	
	if toggle_timer > 0:
		toggle_timer -= delta
	else:
		toggle_timer = clock_rate
		toggle()

func set_color(color: Color) -> void:
	sprite.modulate = color
	if color.get_luminance() < 0.5:
		minute_hand.modulate = Color.WHITE
		hour_hand.modulate = Color.WHITE
		outlines.modulate = Color.WHITE
	else:
		minute_hand.modulate = Color(0.145, 0.145, 0.145)
		hour_hand.modulate = Color(0.145, 0.145, 0.145)
		outlines.modulate = Color(0.145, 0.145, 0.145)
