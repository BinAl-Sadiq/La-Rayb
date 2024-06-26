extends PanelContainer
class_name MessageBox

const life_threshold: float = 0.75
var life_timer: float =  0.0
var intro_timer: float =  0.0
@onready var message_label: Label = $"MarginContainer/HBoxContainer/Message Label"
@onready var title_label: Label = $"MarginContainer/HBoxContainer/Title Label"

func trigger(title_value: String, title_color: Color, message: String):
	modulate.a = 0.0
	life_timer =  5.0
	intro_timer = 0.125
	title_label.modulate = title_color
	title_label.text = title_value
	message_label.text = message
	var message_size: Vector2 = message_label.get_theme_font("font").get_string_size(message, HORIZONTAL_ALIGNMENT_LEFT, -1, message_label.get_theme_font_size("font_size"))
	var title_size: Vector2 = title_label.get_theme_font("font").get_string_size(title_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, title_label.get_theme_font_size("font_size"))
	size.x = int(message_size.x + title_size.x) + 10#margins
	size.y = int(title_size.y) + 10#margins
	anchors_preset = PRESET_CENTER
	visible = true

func _process(delta):
	if intro_timer > 0:
		intro_timer -= delta
		modulate.a = 1 - (intro_timer / 0.125)
	elif life_timer > 0:
		life_timer -= delta
		if life_timer < life_threshold:
			modulate.a = life_timer / life_threshold
	elif visible:
		visible = false
