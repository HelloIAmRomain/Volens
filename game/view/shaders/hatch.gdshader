shader_type canvas_item;
// Case de danger : couleur ET hachures (ENF-20/22, DCT §6.3) — l'information
// n'est jamais portée par le seul canal couleur. Les hachures défilent
// lentement quand le danger est actif, sont figées quand il dort.

uniform float hatch_density : hint_range(2.0, 24.0) = 7.0;
uniform float hatch_width : hint_range(0.05, 0.9) = 0.42;
uniform float scroll_speed : hint_range(0.0, 2.0) = 0.35;
uniform bool reduced_motion = false;

void fragment() {
	float scroll = reduced_motion ? 0.0 : TIME * scroll_speed;
	// Diagonale : hachures à 45°, lisibles même en petite taille.
	float band = fract((UV.x + UV.y) * hatch_density - scroll);
	// Inversion explicite : smoothstep à bornes décroissantes est indéfini.
	float line = 1.0 - smoothstep(hatch_width - 0.10, hatch_width + 0.10, abs(band - 0.5) * 2.0);

	// Bordure marquée : la case reste délimitée sans grille par-dessus.
	vec2 edge = min(UV, vec2(1.0) - UV);
	float border = 1.0 - smoothstep(0.0, 0.06, min(edge.x, edge.y));

	float a = clamp(0.30 + line * 0.55 + border * 0.35, 0.0, 1.0) * COLOR.a;
	COLOR = vec4(COLOR.rgb, a);
}
