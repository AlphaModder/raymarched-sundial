#include "math.glsl"

vec4 sandTexture(vec2 uv) {
    vec4 alpha = vec4(1.00, 0.94, 0.88, 1.0);
    vec4 beta = vec4(0.80, 0.70, 0.60, 1.0);
    float r = pow(pseudoRandom(uv.xy), 5.0);
 	return alpha * (1.0 - r) + beta * (r);   
}

vec4 sampleSandTriplanar(vec3 pos, vec3 normal, float sharpness) {
    mat3x4 planes = mat3x4(
        sandTexture(pos.yz),
        sandTexture(pos.xz),
        sandTexture(pos.xy)
    );
    vec3 blend = pow(abs(normal), vec3(sharpness));
    blend /= blend.x + blend.y + blend.z;
    return planes * blend;
}

vec4 brickTexture(vec2 uv){
    
    vec4 light = vec4(1.00, 0.93, 0.80, 1.0);
    vec4 dark = vec4(0.50, 0.40, 0.25, 1.0);
    
    vec2 div = vec2(2, 3);
    float edgeWidth = 0.2;
    
    vec2 orinal_uv = uv;
    uv = mod(uv * div, vec2(1.0));
    float shift = mod(floor(orinal_uv.y * div.y), 2.0);
    uv = mod(uv + vec2(0.5 * shift, 0.0), vec2(1.0)) + vec2(0.5);
    vec2 value = abs(uv - vec2(0.5)) - vec2(edgeWidth * 0.5);
    float edge = float(min(value.x, value.y));
    
    return (edge) * light + (1.0 - edge) * dark;
}

vec4 sampleBrickTriplanar(vec3 pos, vec3 normal, float sharpness) {
    mat3x4 planes = mat3x4(
        brickTexture(pos.yz),
        brickTexture(pos.xz),
        brickTexture(pos.xy)
    );
    vec3 blend = pow(abs(normal), vec3(sharpness));
    blend /= blend.x + blend.y + blend.z;
    return planes * blend;
}
