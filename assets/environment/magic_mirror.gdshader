shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;
uniform vec4 tint : source_color = vec4(0.55, 0.8, 0.9, 1.0);
void fragment() {
	vec2 p = UV - vec2(0.5);
	float radius = length(p);
	vec2 frame_point = vec2(p.x * 2.6, UV.y * 3.45 + 0.55);
	float edge = frame_point.y > 2.7 ? 1.3 - length(vec2(frame_point.x, frame_point.y - 2.7)) : min(1.3 - abs(frame_point.x), frame_point.y - 0.55);
	if (edge < 0.0) { discard; }
	float angle = atan(p.y, p.x);
	float rim = 1.0 - smoothstep(0.003, 0.009, abs(edge - 0.08));
	float runes = pow(max(cos((UV.y * 8.0 + UV.x * 6.0) * 6.283185), 0.0), 12.0) * (1.0 - smoothstep(0.008, 0.022, abs(edge - 0.19)));
	float wisps = pow(0.5 + 0.5 * sin(angle * 2.0 + radius * 14.0 - TIME * 0.45), 4.0);
	wisps *= (1.0 - smoothstep(0.24, 0.43, radius)) * smoothstep(0.0, 0.08, radius);
	float shimmer = rim * 0.25 + runes * 0.3 + wisps * 0.35;
	ALBEDO = tint.rgb;
	ALPHA = clamp(shimmer * 0.5, 0.0, 0.75);
}
