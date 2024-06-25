shader_type canvas_item;

uniform vec2 UV_offset;
uniform float threshold: hint_range(0.f, 1.f) = 0.1f;
uniform vec2 scale = vec2(2.01612903f, 1.03225806f);
uniform vec3 dye: source_color = vec3(1.f);
uniform bool highlight = false;
uniform float normal_opacity: hint_range(0.0, 1.0, 0.01) = 1.f;
uniform float highlight_opacity: hint_range(0.0, 1.0, 0.01) = 1.f;
uniform float distortion_factor: hint_range(0.0, 1.0) = 1.f;
uniform float distortion_edge: hint_range(0.0, 1.0) = 0.3f;
uniform float zoom: hint_range(0.0, 1.0) = 1.f;

void fragment() 
{
	//COLOR = texture(TEXTURE, UV + UV_offset * 0.0004f - normalize(UV - vec2(0.5) * scale) * distortion_factor) * dye;
	float len = smoothstep(distortion_edge, 1.f, length(UV / scale - vec2(0.5)));
	COLOR = texture(TEXTURE, UV * zoom + UV_offset * 0.0002f + normalize(UV - vec2(0.5) * scale) * distortion_factor * len) * vec4(dye, highlight ? highlight_opacity : normal_opacity);
	if (COLOR.a != 0.0)
		if (UV.x < threshold)
			COLOR.a *= UV.x / threshold;
		else if (UV.x / scale.x > 1.f - threshold)
			COLOR.a *= (1.f - UV.x / scale.x) / threshold;
		if (UV.y < threshold)
			COLOR.a *= UV.y / threshold;
		else if (UV.y / scale.y > 1.f - threshold)
			COLOR.a *= (1.f - UV.y / scale.y) / threshold;
}
