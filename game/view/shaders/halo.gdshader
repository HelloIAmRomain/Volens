shader_type canvas_item;
// Halo d'une RÉGION de but, pas d'une case. Le quad couvre la région élargie
// d'un débord ; `INSTANCE_CUSTOM.xy` porte la proportion du noyau dans ce
// quad, ce qui donne un champ de distance à un rectangle arrondi : une bande
// pleine largeur rayonne sur toute sa longueur au lieu de se lire comme N
// points séparés.

uniform float falloff : hint_range(0.5, 6.0) = 2.2;
uniform float body_alpha : hint_range(0.0, 1.0) = 0.42;
uniform float glow_alpha : hint_range(0.0, 1.0) = 0.55;
uniform float pulse_amplitude : hint_range(0.0, 0.5) = 0.10;
uniform float pulse_speed : hint_range(0.0, 4.0) = 0.9;
uniform bool reduced_motion = false;

varying vec2 core;

void vertex() {
	core = INSTANCE_CUSTOM.xy;
}

void fragment() {
	// Distance signée à un rectangle arrondi centré, en coordonnées -1..1.
	vec2 p = abs(UV * 2.0 - 1.0);
	vec2 outside = max(p - core, vec2(0.0));
	float d = length(outside) / max(1.0 - min(core.x, core.y), 0.001);

	float glow = pow(clamp(1.0 - d, 0.0, 1.0), falloff) * glow_alpha;
	// Le noyau est TRANSLUCIDE : la bande est une zone lumineuse traversable,
	// pas une dalle qui écrase la nuée.
	float body = (1.0 - smoothstep(0.0, 0.08, d)) * body_alpha;
	float pulse = reduced_motion ? 1.0 : 1.0 + sin(TIME * pulse_speed) * pulse_amplitude;

	float a = clamp(max(body, glow * pulse), 0.0, 1.0) * COLOR.a;
	if (a < 0.004) {
		discard;
	}
	COLOR = vec4(COLOR.rgb, a);
}
