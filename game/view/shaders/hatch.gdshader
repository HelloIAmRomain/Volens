shader_type canvas_item;
// Région de danger : couleur ET hachures (ENF-20/22), sur toute la région
// d'un seul tenant. `INSTANCE_CUSTOM.xy` porte la taille de la région en
// CASES, ce qui garde la densité des hachures constante quelle que soit
// l'étendue — et surtout continue, sans couture case par case.
//
// Registre calme (DS-03 appliqué au visuel) : c'est un obstacle, pas une
// alarme. Remplissage sourd, hachures fines, contour net sur le seul
// pourtour de la région.

uniform float hatch_per_cell : hint_range(0.5, 6.0) = 1.6;
uniform float hatch_width : hint_range(0.05, 0.9) = 0.34;
uniform float scroll_speed : hint_range(0.0, 2.0) = 0.0;
uniform bool reduced_motion = false;

varying vec2 cells;

void vertex() {
	cells = max(INSTANCE_CUSTOM.xy, vec2(1.0));
}

void fragment() {
	vec2 in_cells = UV * cells;
	float scroll = (reduced_motion || scroll_speed <= 0.0) ? 0.0 : TIME * scroll_speed;

	// Diagonale à 45°, période liée à la CASE et non au quad : continue d'un
	// bout à l'autre de la région.
	float band = fract((in_cells.x + in_cells.y) * hatch_per_cell - scroll);
	float line = 1.0 - smoothstep(hatch_width - 0.12, hatch_width + 0.12,
		abs(band - 0.5) * 2.0);

	// Contour sur le pourtour de la RÉGION, épaisseur constante en cases.
	vec2 edge = min(in_cells, cells - in_cells);
	float border = 1.0 - smoothstep(0.0, 0.10, min(edge.x, edge.y));

	// Le danger doit passer AVANT la nuée au test du plissement (DA-02) :
	// il est petit — souvent une case — donc sa densité doit compenser sa
	// surface. Registre calme, mais pas effacé.
	float a = clamp(0.34 + line * 0.34 + border * 0.72, 0.0, 1.0) * COLOR.a;
	COLOR = vec4(COLOR.rgb, a);
}
