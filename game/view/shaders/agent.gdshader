shader_type canvas_item;
// Agent de la nuée : disque lumineux procédural, aucune texture (DT-13).
// La couleur arrive par instance de MultiMesh (use_colors) dans COLOR.

uniform float core_radius : hint_range(0.0, 1.0) = 0.42;
uniform float glow_strength : hint_range(0.0, 2.0) = 0.55;

void fragment() {
	float r = length(UV - vec2(0.5)) * 2.0;
	// smoothstep croissant puis inversé : avec edge0 > edge1 le résultat est
	// indéfini en GLSL (il « marche » sur beaucoup de pilotes, pas sur tous).
	float core = 1.0 - smoothstep(core_radius - 0.10, core_radius + 0.18, r);
	float glow = pow(clamp(1.0 - r, 0.0, 1.0), 2.5) * glow_strength;
	float a = clamp(core + glow, 0.0, 1.0) * COLOR.a;
	if (a < 0.004) {
		discard;
	}
	COLOR = vec4(COLOR.rgb, a);
}
