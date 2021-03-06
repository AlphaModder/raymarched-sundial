#include "math.glsl"
#include "sdf.glsl"
#include "material.glsl"
#include "texture.glsl"

// CAMERA
#define ROT_RADIUS 3.0
#define ROT_SPEED 0.05
#define ROT_DIR 1.0
#define ROT_OFFSET -2.9
#define ROT iTime * ROT_SPEED + ROT_OFFSET

#define CAMERA_POS vec3(ROT_DIR * ROT_RADIUS * sin(ROT), 0, ROT_RADIUS * cos(ROT))
#define CAMERA_FACING vec3(ROT_DIR * -sin(ROT), 0, -cos(ROT))
#define CAMERA_UP vec3(0, 1, 0)
#define FOV_Y 70.0

// ENVIRONMENT: SKY
#define LATITUDE -20.0
#define SUN_OFFSET 0.2
#define SUN_SPEED 0.125
#define SUN_COLOR vec3(6.0, 4.8, 3.0)
#define DAY_SKY_COLOR vec3(0.5, 0.7, 0.9)
#define NIGHT_SKY_COLOR vec3(0.05, 0.08, 0.15)

// ENVIRONMENT: LIGHTING
#define SUNLIGHT light(0.7, 0.7, 0.6, 1.5)
#define SHADOW_SOFTNESS 16.0

// SCENE: OBJECTS
#define GROUND_HEIGHT -1.0
#define OBJ_NONE -1
#define OBJ_DESERT 0
#define OBJ_SUNDIAL 1
#define OBJ_PYRAMID 2

// the main signed distance field for the scene
objdist mainDistance(vec3 position) {
    objdist result = objdist(HUGE, OBJ_NONE);
    
    result = sdfUnion(result, sdfSundial(position, OBJ_SUNDIAL));

    objdist pyramid = sdfPyramid((position - vec3(-16, -1.1, -20)) / 22.0, 1.0, OBJ_PYRAMID);
    pyramid.dist *= 22.0;

    objdist dunes = sdfDesert(position, OBJ_DESERT);
    
    result = sdfUnion(result, pyramid);
    result = sdfUnion(result, dunes);
    return result;
}

// gets the material properties at a point based on object id. can alter the normal
material materialForPoint(vec3 view, vec3 pos, vec3 dPdx, vec3 dPdy, inout vec3 normal, int obj) {
    vec3 color;
    switch(obj) {
        case OBJ_DESERT:
            normal = decodeNormal(sampleTriplanar(iChannel2, pos, dPdx, dPdy, normal, 1.0).xyz, normal);
            return material(sampleTriplanar(iChannel0, pos, dPdx, dPdy, normal, 1.0).rgb, 0.1, 4.0);
        case OBJ_SUNDIAL:
            return material(sampleTriplanar(iChannel1, pos, dPdx, dPdy, normal, 1.0).rgb, 0.6, 128.0);
        case OBJ_PYRAMID:
            color = sampleBrickBiplanar(pos, normal, 1.0).rgb;
            normal = sampleBrickNormal(pos, normal);
            return material(color, 0.05, 2.0);
        default:
            return material(vec3(0.5, 0.0, 0.5), 0.0, 0.0);
    }
}

// the unit vector pointing towards the sun
vec3 sunVec() {
    // uncomment this for a plain rotating sun, for testing
    // return normalize(vec3(cos(iTime), 0.6, sin(iTime))); // rotates in a circle in the xz plane; unrealistic
    
    vec2 circle = vec2(cos(iTime * SUN_SPEED), sin(iTime * SUN_SPEED)) * (1.0 - SUN_OFFSET * SUN_OFFSET);
    vec3 spherePos = vec3(SUN_OFFSET, circle.x, circle.y);
    float a = LATITUDE * TO_RADIANS;
    
    mat3x3 rotate = mat3x3(
        cos(a), sin(a), 0.0,
        -sin(a), cos(a), 0.0,
        0.0, 0.0, 1.0
    );
    return rotate * spherePos;
}
