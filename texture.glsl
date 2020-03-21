#include "math.glsl"
#define BRICK_DIV vec2(1.5, 2)
#define BRICK_CONTRAST 0.12
#define BRICK_GRAIN 0.20
#define BRICK_NORM_GRAIN 0.05
#define BRICK_EDGE_WIDTH 0.1
#define BRICK_EDGE_SLOPE 0.2

vec2 brickValue(vec2 uv) {
    vec2 orinal_uv = uv;
    uv = mod(uv * BRICK_DIV, vec2(1.0));
    float shift = mod(floor(orinal_uv.y * BRICK_DIV.y), 2.0);
    uv = mod(uv + vec2(0.5 * shift, 0.0), vec2(1.0)) + vec2(0.5);
    return abs(uv - vec2(0.5));
}

vec4 brickTexture(vec2 uv){
    vec4 color = vec4(0.78, 0.65, 0.48, 1.0);
    vec4 diff = vec4(vec3(BRICK_CONTRAST), 1.0);
    vec4 dark = color - diff;
    vec4 light = color + diff;
    
    vec2 value = brickValue(uv);
    float edge = float(min(value.x, value.y));
    
    float grain = pow(random(uv.xy), 2.0);
    vec4 brick = (edge) * light + (1.0 - edge) * dark;
    return (light * grain + brick * (1.0 - grain)) * BRICK_GRAIN + brick * (1.0 - BRICK_GRAIN);
}

#define OUT_NORM normalize(vec3(0, 0, 1))
#define UP_NORM normalize(vec3(0, BRICK_EDGE_SLOPE, 1))
#define LEFT_NORM normalize(vec3(-BRICK_EDGE_SLOPE, 0, 1))
#define RIGHT_NORM normalize(vec3(BRICK_EDGE_SLOPE, 0, 1))
#define DOWN_NORM normalize(vec3(0, -BRICK_EDGE_SLOPE, 1))

vec3 brickNormal(vec2 uv) {
    vec2 value = brickValue(uv);
    
    bool onEdge = value.x > BRICK_EDGE_WIDTH && value.x < (1.0 - BRICK_EDGE_WIDTH) 
        && value.y > BRICK_EDGE_WIDTH && value.y < (1.0 - BRICK_EDGE_WIDTH);
    bool inBack = value.x < value.y;
    bool inFront = value.x > (1.0 - value.y);
    
    vec3 norm = OUT_NORM * float(onEdge) + ((UP_NORM * float(inFront) + LEFT_NORM * float(!inFront)) * float(inBack) + (RIGHT_NORM * float(inFront) + DOWN_NORM * float(!inFront)) * float(!inBack)) * float(!onEdge);
    
    vec2 grain = BRICK_NORM_GRAIN * vec2(random(value.xy) - 0.5, random(value.yx) - 0.5);
    norm = normalize(norm + vec3(grain, 0.0));
    return norm;
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

vec3 sampleBrickNormal(vec3 pos, vec3 normal) {
    return rotateAround(normal) * (abs(normal.z) > abs(normal.x)? brickNormal(pos.xy): brickNormal(pos.zy));
}

