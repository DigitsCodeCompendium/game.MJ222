shader_type spatial;
render_mode unshaded;

uniform vec4 dark_lava : source_color = vec4(0.48, 0.09, 0.025, 1.0);
uniform vec4 hot_lava : source_color = vec4(1.0, 0.52, 0.10, 1.0);

void fragment() {
	vec2 p = UV * 42.0;
	float flow = sin(p.x * 1.4 + sin(p.y * 1.9) + TIME * 0.22)
		* cos(p.y * 1.5 + sin(p.x) - TIME * 0.16);
	float heat = smoothstep(-0.25, 0.65, flow);
	ALBEDO = mix(dark_lava.rgb, hot_lava.rgb, heat);
}
