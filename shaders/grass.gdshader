shader_type spatial;
render_mode cull_disabled;
uniform vec3 color : source_color;
uniform vec3 color2 : source_color;
uniform sampler2D noise;
uniform float noiseScale = 20.0;
//uniform float ambient_strength = 0.1;
uniform float ambient_boost = 0.3; // Higher values make it less affected by darkness

varying vec3 worldPos;

void vertex() {
    // Called for every vertex the material is visible on.
	worldPos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
    // Called for every pixel the material is visible on.
	vec3 noiseLevel = texture(noise, worldPos.xz / noiseScale, UV.y).rgb;
    ALBEDO = mix(color, color2, UV.y) * mix(color, color2, noiseLevel.r);
	//EMISSION = ALBEDO * ambient_strength;
	
	AO = 1.0 - ambient_boost; // Reduces ambient occlusion effect
    ROUGHNESS = 0.7; // Adjust based on how you want specular highlights
	if (!FRONT_FACING){
		NORMAL = -NORMAL;
	}
}