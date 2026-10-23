shader_type canvas_item;
// Palette « Cendre Grise » sur le décor seul (Sol, Chemins, Batiments, Deco) ; lumière 2D conservée (pas de light()).
// Valeurs finales (source : mockup v2b « décor seul ») : desaturation 0,70, darken 0,20 (HSV s x 0,30, v x 0,80),
// tint (1,156 ; 1,345 ; 1,596) ajusté par moindres carrés sur la levée bleutée v2b des tuiles retenues,
// fog_color (0,55 ; 0,58 ; 0,68), fog_strength 0,75, radius_px 200, fog_edge_px 8.

uniform float desaturation = 0.70;
uniform float darken = 0.20;
uniform vec3 tint = vec3(1.156, 1.345, 1.596);
uniform vec3 fog_color = vec3(0.55, 0.58, 0.68);
uniform float fog_strength = 0.75;
uniform float radius_px = 200.0; // (ATRE_RADIUS_TILES[0] + 0,5) x 16
uniform float fog_edge_px = 8.0;

varying vec2 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	vec4 c = texture(TEXTURE, UV) * COLOR;
	float l = dot(c.rgb, vec3(0.2126, 0.7152, 0.0722));
	vec3 g = mix(c.rgb, l * tint, desaturation) * (1.0 - darken);
	float brume = smoothstep(radius_px - fog_edge_px, radius_px + fog_edge_px, length(world_pos));
	COLOR = vec4(mix(g, l * fog_color, brume * fog_strength), c.a);
}
