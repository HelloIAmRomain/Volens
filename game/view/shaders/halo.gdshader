shader_type canvas_item;
// Halo radial des buts et des sources (lumière, sortie) — DT-13 : primitive
// + shader, jamais de texture. Respiration lente, coupable en mode
// « animations réduites » (ENF-21) via reduced_motion.

uniform float falloff : hint_range(0.5, 6.0) = 3.4;
uniform float pulse_amplitude : hint_range(0.0, 0.5) = 0.14;
uniform float pulse_speed : hint_range(0.0, 4.0) = 1.1;
uniform bool reduced_motion = false;

void fragment() {
	float r = length(UV - vec2(0.5)) * 2.0;
	float base = pow(clamp(1.0 - r, 0.0, 1.0), falloff);
	float pulse = reduced_motion ? 1.0 : 1.0 + sin(TIME * pulse_speed) * pulse_amplitude;
	float a = base * pulse * COLOR.a;
	if (a < 0.004) {
		discard;
	}
	COLOR = vec4(COLOR.rgb, clamp(a, 0.0, 1.0));
}
