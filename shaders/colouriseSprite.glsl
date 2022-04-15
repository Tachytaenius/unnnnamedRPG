uniform vec3 spriteColour;
uniform bool colourise;

vec4 effect(vec4 loveColour, sampler2D image, vec2 textureCoords, vec2 windowCoords) {
	vec4 textureColour = Texel(image, textureCoords);
	if (colourise) {
		if (textureColour.a != 1.0 && textureColour.a != 0.0) {
			textureColour.rgb *= spriteColour;
			textureColour.a = 1.0;
		}
	}
	return loveColour * textureColour;
}
