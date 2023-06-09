shader_type canvas_item;

uniform bool is_poisoned = false;
uniform bool is_chilled = false;
uniform bool is_stunned = false;

// uniform vec4 base : hint_color;
uniform vec3 poison = vec3(0.0, 1.0, 0.0);
uniform vec3 chill = vec3(0.0, 0.0, 1.0);
uniform vec3 stun = vec3(0.1, 0.1, 0.1);

void fragment() {
	COLOR = texture(TEXTURE, UV);
	
	if (is_poisoned) {
		COLOR.rgb = mix(COLOR.rgb, poison, 0.25);
	}
	
	if (is_chilled) { 
		COLOR.rgb = mix(COLOR.rgb, chill, 0.25);
	}
	
	if (is_stunned) { 
		COLOR.rgb = mix(COLOR.rgb, stun, 0.5);	
	}
} 