#define PI 3.1415926535
#define TO_RADIANS (PI/180.0)
#define HUGE 1000000.0
#define EPSILON 0.0001
#define ZERO min(iFrame,0)

float random() {
    // TODO: Implement
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
