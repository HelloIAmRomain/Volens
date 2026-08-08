shader_type canvas_item;
// SEUIL de sortie — pas un phare [DA-02, carnet décision 76].
//
// L'aplat saturé faisait de la sortie l'élément le plus lumineux de l'écran,
// ce qui inversait la hiérarchie DA-02 : elle dominait la lumière que la nuée
// poursuit et la nuée elle-même, qui est le personnage (DA-01).
//
// Une sortie n'a pas à attirer l'œil : elle a à se laisser reconnaître quand
// on la cherche. On la dessine donc comme une OUVERTURE — un liseré net qu'on
// franchit, un intérieur presque vide, un dégradé qui s'éteint vers le
// dehors. Changement de matière, pas d'intensité.
//
// INSTANCE_CUSTOM = (largeur en cases, hauteur en cases, débord en cases, 0).

uniform float edge_alpha : hint_range(0.0, 1.0) = 0.40;
uniform float inner_alpha : hint_range(0.0, 1.0) = 0.13;
uniform float outer_alpha : hint_range(0.0, 1.0) = 0.10;
// Épaisseur du liseré et profondeur du dégradé intérieur, en CASES : une
// bande pleine largeur et une sortie d'une case ont le même trait.
uniform float edge_cells : hint_range(0.01, 0.4) = 0.07;
uniform float inner_depth : hint_range(0.05, 2.0) = 0.55;

varying vec2 cells;
varying float bleed;

void vertex() {
	cells = max(INSTANCE_CUSTOM.xy, vec2(0.001));
	bleed = max(INSTANCE_CUSTOM.z, 0.001);
}

void fragment() {
	vec2 span = cells + vec2(bleed * 2.0);
	vec2 p = UV * span - vec2(bleed);

	// Distance signée au pourtour de la région, en cases : > 0 dedans.
	vec2 inner = min(p, cells - p);
	float din = min(inner.x, inner.y);
	vec2 outside = max(max(-p, p - cells), vec2(0.0));
	float dout = length(outside);

	// 1. Le liseré : le trait qu'on franchit. Net des deux côtés.
	float signed_d = dout > 0.0 ? -dout : din;
	float line = 1.0 - smoothstep(edge_cells, edge_cells + 0.05, abs(signed_d));

	// 2. L'intérieur : presque vide, à peine plus dense près du bord. C'est
	//    ce creux qui distingue une ouverture d'une dalle.
	float inward = din > 0.0
		? (1.0 - smoothstep(0.0, inner_depth, din)) * 0.65 + 0.35
		: 0.0;

	// 3. Le dehors : extinction douce, sans halo. Une sortie n'irradie pas.
	float outward = dout > 0.0 ? pow(1.0 - clamp(dout / bleed, 0.0, 1.0), 2.0) : 0.0;

	float a = clamp(line * edge_alpha + inward * inner_alpha + outward * outer_alpha, 0.0, 1.0) * COLOR.a;
	if (a < 0.004) {
		discard;
	}
	// Le liseré est le seul endroit clair ; l'intérieur reste dans le ton.
	vec3 rgb = mix(COLOR.rgb * 0.80, mix(COLOR.rgb, vec3(1.0), 0.18), line);
	COLOR = vec4(rgb, a);
}
