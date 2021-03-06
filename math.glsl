#define PI 3.1415926535
#define SQRT_2 1.41421356237
#define TO_RADIANS (PI/180.0)
#define HUGE 1000000.0
#define EPSILON 0.0001

// Pseudorandom number generator:
// Source: https://stackoverflow.com/questions/4200224/random-noise-functions-for-glsl
float random(vec2 seed) {
    return fract(sin(dot(seed.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

// pads a 2x2 matrix with zeroes to make it 3x3.
mat3x3 pad(mat2x2 mat) {
    return mat3x3(
        mat[0][0], mat[1][0], 0.0,
        mat[0][1], mat[1][1], 0.0,
        0.0, 0.0, 0.0
    );
}

// gives a rotation matrix transforming +Z onto normal
// see https://math.stackexchange.com/questions/61547/rotation-of-a-vector-distribution-to-align-with-a-normal-vector
mat3x3 rotateAround(vec3 normal) {
    vec2 v = vec2(normal.y, -normal.x);
    return pad(outerProduct(v, v) / (1.0 + normal.z)) + mat3x3(
        normal.z, 0.0, -normal.x,
        0.0, normal.z, -normal.y,
        normal.x, normal.y, normal.z
    );
}

// decodes a normal from a normal map into worldspace
vec3 decodeNormal(vec3 fromTex, vec3 surfaceNormal) {
    vec3 tangentSpace = (2.0 * fromTex - 1.0) * vec3(-1, 1, 1);
    return rotateAround(surfaceNormal) * tangentSpace;
}

// sample from a cosine distribution in the upper unit hemisphere using Malley's method
vec3 sampleCosine(vec2 seed) {
    float angle = random(seed) * 2.0 * PI;
    float rand = random(seed + 1.0);
    return vec3(rand * cos(angle), rand * sin(angle), sqrt(1.0 - rand * rand));
}

// sample unit vectors from a cone of the given angle
vec3 sampleCone(float coneAngle, vec2 seed) {
    float angle = random(seed) * 2.0 * PI;
    vec2 disk = random(seed + 1.0) * vec2(cos(angle), sin(angle)) * tan(coneAngle);
    return normalize(vec3(disk, 1.0));
}

// used for triplanar mapping, effectively projects a texture onto an object from
// each of the axes and blends between them.
vec4 sampleTriplanar(sampler2D map, vec3 pos, vec3 dPdx, vec3 dPdy, vec3 normal, float sharpness) {
    mat3x4 planes = mat3x4(
        textureGrad(map, pos.yz, dPdx.yz, dPdy.yz),
        textureGrad(map, pos.zx, dPdx.zx, dPdy.zx),
        textureGrad(map, pos.xy, dPdx.xy, dPdy.xy)
    );
    
    vec3 blend = pow(abs(normal), vec3(sharpness));
    blend /= blend.x + blend.y + blend.z;
    return planes * blend;
}

// utility for controlling the intensity of a light
vec3 light(float r, float g, float b, float intensity) {
    return 3.0 * intensity * vec3(r, g, b) / (r + g + b);
}

// utility for controlling the intensity of a light
vec3 light(vec3 color, float intensity) {
    return light(color.r, color.g, color.b, intensity);
}

// euclidean to cylindrical coordinates
vec3 toCylindrical(vec3 euclidean) {
    float p = length(euclidean.xz);
    float a = atan(euclidean.z, euclidean.x) /* + PI */;
    return vec3(p, a, euclidean.y);
}

// cylindrical to euclidean coordinates
vec3 fromCylindrical(vec3 cylindrical) {
    // cylindrical.y -= PI;
    return vec3(cylindrical.x * cos(cylindrical.y), cylindrical.z, cylindrical.x * sin(cylindrical.y));
}

