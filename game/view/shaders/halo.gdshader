shader_type canvas_item;
// Halo d'une RÉGION de but secondaire — ressource, dépôt. La lumière et la
// sortie ont désormais leur propre traitement (`light`, `exit`) : ce shader
// sert le reste du vocabulaire, et reste volontairement DISCRET pour ne pas
// reprendre le dessus dans la hiérarchie DA-02.
//
// INSTANCE_CUSTOM = (largeur en cases, hauteur en cases, débord en cases, 0).

uniform float falloff : hint_range(0.5, 6.0) = 2.2;
uniform float body_alpha : hint_range(0.0, 1.0) = 0.30;
uniform float glow_alpha : hint_range(0.0, 1.0) = 0.34;
uniform float pulse_hz : hint_range(0.0, 2.0) = 0.5;
uniform float pulse_amplitude : hint_range(0.0, 0.5) = 0.08;
uniform bool reduced_motion = false;

varying vec2 cells;
varying float bleed;

void vertex() {
	cells = max(INSTANCE_CUSTOM.xy, vec2(0.001));
	bleed = max(INSTANCE_CUSTOM.z, 0.001);
}

void fragment() {
	vec2 span = cells + vec2(bleed * 2.0);
	vec2 p = UV * span - vec2(bleed);

	vec2 outside = max(max(-p, p - cells), vec2(0.0));
	float d = length(outside);
	float glow = pow(1.0 - clamp(d / bleed, 0.0, 1.0), falloff) * glow_alpha;

	vec2 inner = min(p, cells - p);
	float body = smoothstep(0.0, 0.12, min(inner.x, inner.y)) * body_alpha;

	float pulse = reduced_motion ? 1.0 : 1.0 + sin(TIME * 6.28318 * pulse_hz) * pulse_amplitude;

	float a = clamp(max(body, glow * pulse), 0.0, 1.0) * COLOR.a;
	if (a < 0.004) {
		discard;
	}
	COLOR = vec4(COLOR.rgb, a);
}
