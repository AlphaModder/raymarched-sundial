#define PI 3.1415926535
#define SQRT_2 1.41421356237
#define TO_RADIANS (PI/180.0)
#define HUGE 1000000.0
#define EPSILON 0.0001
#define ZERO min(iFrame,0)

// TODO: Use an LCG or something
float random() {
    return 4.0; // chosen by fair dice roll.
                // guaranteed to be random.
}

// pads a 2x2 matrix with zeroes to make it 3x3.
mat3x3 pad(mat2x2 mat) {
    return mat3x3(
        mat[0][0], mat[1][0], 0.0,
        mat[0][1], mat[1][1], 0.0,
        0.0, 0.0, 0.0
    );
}

float norm2(vec3 vec) {
    return dot(vec, vec);
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

vec3 decodeNormal(vec3 fromTex, vec3 surfaceNormal) {
    vec3 tangentSpace = (2.0 * fromTex - 1.0) * vec3(-1, 1, 1);
    return rotateAround(surfaceNormal) * tangentSpace;
}

// sample from a cosine distribution in the upper unit hemisphere using Malley's method
vec3 sampleCosine() {
    float angle = random() * 2.0 * PI;
    float rand = random();
    return vec3(rand * cos(angle), rand * sin(angle), sqrt(1.0 - rand * rand));
}

// sample unit vectors from a cone of the given angle
vec3 sampleCone(float coneAngle) {
    float angle = random() * 2.0 * PI;
    vec2 disk = random() * vec2(cos(angle), sin(angle)) * tan(coneAngle);
    return normalize(vec3(disk, 1.0));
}

// TODO: proper texture derivatives
vec4 sampleTriplanar(sampler2D map, vec3 pos, vec3 normal, float sharpness) {
    mat3x4 planes = mat3x4(
        texture(map, pos.yz),
        texture(map, pos.xz),
        texture(map, pos.xy)
    );
    
    vec3 blend = pow(abs(normal), vec3(sharpness));
    blend /= blend.x + blend.y + blend.z;
    return planes * blend;
}

vec3 light(float r, float g, float b, float intensity) {
    return 3.0 * intensity * vec3(r, g, b) / (r + g + b);
}

vec3 toCylindrical(vec3 euclidean) {
    float p = length(euclidean.xz);
    float a = atan(euclidean.z, euclidean.x) /* + PI */;
    return vec3(p, a, euclidean.y);
}

vec3 fromCylindrical(vec3 cylindrical) {
    // cylindrical.y -= PI;
    return vec3(cylindrical.x * cos(cylindrical.y), cylindrical.z, cylindrical.x * sin(cylindrical.y));
}

