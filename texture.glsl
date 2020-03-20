#include "math.glsl"
#define BRICK_CONTRAST 0.12
#define BRICK_GRAIN 0.20

vec4 brickTexture(vec2 uv){
    
    vec4 color = vec4(0.78, 0.65, 0.48, 1.0);
    vec4 diff = vec4(vec3(BRICK_CONTRAST), 1.0);
    vec4 dark = color - diff;
    vec4 light = color + diff;
    
    vec2 div = vec2(1.5, 2);
    float edgeWidth = 0.2;
    
    vec2 orinal_uv = uv;
    uv = mod(uv * div, vec2(1.0));
    float shift = mod(floor(orinal_uv.y * div.y), 2.0);
    uv = mod(uv + vec2(0.5 * shift, 0.0), vec2(1.0)) + vec2(0.5);
    vec2 value = abs(uv - vec2(0.5)) - vec2(edgeWidth * 0.5);
    float edge = float(min(value.x, value.y));
    
    float rand = pow(pseudoRandom(uv.xy), 2.0);
    vec4 brick = (edge) * light + (1.0 - edge) * dark;
    return (light * rand + brick * (1.0 - rand)) * BRICK_GRAIN + brick * (1.0 - BRICK_GRAIN);
}

vec4 sampleBrickBiplanar(vec3 pos, vec3 normal, float sharpness) {
    mat2x4 planes = mat2x4(
        brickTexture(pos.zy),
        brickTexture(pos.xy)
    );
    vec2 blend = pow(abs(normal.xz), vec2(sharpness));
    blend /= blend.x + blend.y;
    return planes * blend;
}
