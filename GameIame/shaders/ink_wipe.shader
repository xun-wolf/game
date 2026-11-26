shader_type canvas_item;

// 墨迹擦除/显影：一套 Shader 复用于开场显影与场景转场。
// progress 0 = 完全透明，1 = 完全覆盖；边缘由噪声形成不规则墨迹。
uniform vec4 ink_color : hint_color = vec4(0.08, 0.06, 0.04, 1.0);
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float softness = 0.16;
uniform vec2 noise_scale = vec2(7.0, 7.0);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void fragment() {
	vec2 uv = UV * noise_scale;
	float n = 0.65 * vnoise(uv) + 0.35 * vnoise(uv * 2.3);
	// 把 progress 映射到 [-softness, 1 + softness]，保证 0/1 时完全透明/覆盖
	float p = progress * (1.0 + 2.0 * softness) - softness;
	float a = clamp((p - n + softness) / (2.0 * softness), 0.0, 1.0);
	COLOR = vec4(ink_color.rgb, ink_color.a * a);
}
