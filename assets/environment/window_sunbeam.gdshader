shader_type spatial;
render_mode blend_add, depth_draw_never, cull_disabled, ambient_light_disabled, fog_disabled, specular_disabled;
uniform vec4 beam_color : source_color = vec4(1.0, 0.84, 0.63, 0.075);
void fragment() {
	float edges = smoothstep(0.0, 0.18, UV.x) * smoothstep(0.0, 0.18, 1.0 - UV.x);
	float ends = smoothstep(0.0, 0.08, UV.y) * smoothstep(0.0, 0.25, 1.0 - UV.y);
	ALBEDO = beam_color.rgb;
	ALPHA = beam_color.a * edges * ends;
}

void light() {
	// Additive black is invisible. Actual mesh shadows remove the shaft here.
	// The beam's render layer restricts it to its own window's sunlight.
	if (LIGHT_IS_DIRECTIONAL) {
		DIFFUSE_LIGHT += LIGHT_COLOR * ATTENUATION * (1.5 / PI);
	}
}
