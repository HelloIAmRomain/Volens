shader_type canvas_item;
// SOURCE de lumière — pas une case remplie [DA-01/02, carnet décision 75].
//
// L'erreur corrigée ici : rendre la lumière translucide pour qu'elle n'écrase
// pas le plateau l'avait rendue INERTE — un bloc kaki, donc un obstacle, alors
// que c'est précisément ce que R01 poursuit. Une source ne se dessine pas
// comme une surface : elle a un noyau clair, une décroissance qui déborde sur
// les cases voisines, et elle respire.
//
// La hiérarchie DA-02 tient par la LUMINOSITÉ PAR UNITÉ DE SURFACE, pas par
// l'étendue : le noyau est le point le plus lumineux de l'écran, sur la plus
// petite surface. C'est ce qui le rend attirant sans qu'il domine.
//
// INSTANCE_CUSTOM = (largeur en cases, hauteur en cases, débord en cases, 0).

uniform float falloff : hint_range(0.5, 6.0) = 2.4;
uniform float core_alpha : hint_range(0.0, 1.0) = 0.96;
uniform float glow_alpha : hint_range(0.0, 1.0) = 0.62;
// Respiration lente : ~0,5 Hz, à la limite basse du perceptible. Une source
// qui bat vite devient une alarme — le registre calme vaut aussi pour le but.
uniform float pulse_hz : hint_range(0.0, 2.0) = 0.5;
uniform float pulse_amplitude : hint_range(0.0, 0.5) = 0.14;
uniform bool reduced_motion = false;

varying vec2 cells;
varying float bleed;

void vertex() {
	cells = max(INSTANCE_CUSTOM.xy, vec2(0.001));
	bleed = max(INSTANCE_CUSTOM.z, 0.001);
}

void fragment() {
	vec2 span = cells + vec2(bleed * 2.0);
	vec2 p = UV * span - vec2(bleed);          // coordonnées en CASES, origine région

	// Distance au rectangle de la région, en cases : nulle à l'intérieur,
	// croissante au-dehors. Une région large rayonne donc sur toute sa
	// longueur au lieu de se lire comme N points.
	vec2 outside = max(max(-p, p - cells), vec2(0.0));
	float d = length(outside);

	float t = clamp(d / bleed, 0.0, 1.0);
	float glow = pow(1.0 - t, falloff);

	// Noyau : resserré à l'intérieur de la région, et surexposé vers le blanc.
	// C'est cette surexposition qui fait lire « source » plutôt que « case ».
	vec2 inner = min(p, cells - p);
	float din = min(inner.x, inner.y);         // distance au bord, en cases
	float core = smoothstep(0.0, 0.34, din);

	float pulse = reduced_motion ? 1.0 : 1.0 + sin(TIME * 6.28318 * pulse_hz) * pulse_amplitude;

	float a = clamp(core * core_alpha + glow * glow_alpha * pulse, 0.0, 1.0) * COLOR.a;
	if (a < 0.004) {
		discard;
	}
	// Le cœur tire vers le blanc : une source ne montre sa teinte que sur ses
	// bords, comme une lampe réelle.
	vec3 rgb = mix(COLOR.rgb, vec3(1.0), core * 0.55);
	COLOR = vec4(rgb, a);
}
