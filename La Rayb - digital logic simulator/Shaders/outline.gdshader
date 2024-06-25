shader_type canvas_item;

uniform vec4 body_color: source_color = vec4(0.0, 0.0,0.0,1.0);
uniform vec4 line_color: source_color = vec4(1.0, 1.0,1.0,1.0);
uniform vec2 scale = vec2(1.0, 1.0);
uniform float thickness: hint_range(0.0, 0.5) = 0.01;

void fragment()
{
	float left = thickness / scale.x;
	float right = 1.0 - thickness / scale.x;
	float down = thickness / scale.y;
	float up = 1.0 - thickness / scale.y;
	if (UV.x < left || UV.x > right || UV.y < down || UV.y > up)
		COLOR = line_color;
	else
		COLOR = body_color;
}