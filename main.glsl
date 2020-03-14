#define MARCH_ITERATIONS 256
#define BOUNCES 3
#define MIN_DIST 0.01
#define MAX_DIST 100.0

/// BEGIN math.glsl
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

vec3 decodeNormal(vec3 fromTex) {
    return (2.0 * fromTex.xzy - 1.0) * vec3(-1, 1, 1);
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
/// END math.glsl
/// BEGIN material.glsl
struct material {
    vec3 color; // the diffuse color of the object
    float diffuse; // how much of the incoming light undergoes diffuse reflection
    float specular; // how much of the incoming light undergoes specular reflection
    float alpha; // the specular exponent of the material
};
/// END material.glsl
/// BEGIN scene.glsl
/// #include "math.glsl"
/// BEGIN sdf.glsl
// the distance to an object, along with that object's id
struct objdist {
    float dist;
    int obj;
};

// basic SDF operations
objdist sdfUnion(objdist a, objdist b) { if(a.dist < b.dist) { return a; } else { return b; } }
objdist sdfIntersection(objdist a, objdist b) { if(a.dist > b.dist) { return a; } else { return b; } }
objdist sdfDifference(objdist a, objdist b) { return sdfIntersection(a, objdist(-b.dist, b.obj)); }

// SDF primitives
objdist sdfSphere(vec3 pos, vec3 center, float radius, int obj) { 
    return objdist(length(pos - center) - radius, obj); 
}	

objdist sdfCylinder(vec3 pos, vec3 center, float radius, float height, int obj) {
    vec3 tPos = pos - center;
    return objdist(max(length(tPos.xz) - radius, abs(tPos.y) - 0.5 * height), obj);
}

// sundial
objdist sdfSundial(vec3 pos, int obj) {
    objdist result;
    result = objdist(max(abs(pos.z) - 0.1, max(pos.x + pos.y, -pos.x)), obj); // gnomon bounds
    result = sdfDifference(result, sdfCylinder(pos.xzy, vec3(-0.5, -1.1, 0).xzy, 1.0, 0.4, obj)); // cylinder cut
    result = sdfUnion(result, sdfCylinder(pos, vec3(0, -1, 0), 1.0, 0.1, obj)); // dial
    return result;
}
/// END sdf.glsl
/// #include "material.glsl"

// CAMERA
#define CAMERA_POS vec3(0, 0, 3)
#define CAMERA_FACING vec3(0, 0, -1)
#define CAMERA_UP vec3(0, 1, 0)
#define FOV_Y 70.0

// ENVIRONMENT: SKY
#define LATITUDE -20.0
#define SUN_OFFSET 0.2
#define SUN_COLOR vec3(2.0, 1.6, 1.0)
#define SKY_COLOR vec3(0.5, 0.7, 0.9)

// ENVIRONMENT: LIGHTING
#define SUNLIGHT light(0.7, 0.7, 0.6, 1.5)
#define AMBIENT light(0.5, 0.7, 0.9, 0.2)
#define SHADOW_SOFTNESS 16.0

// SCENE: OBJECTS
#define GROUND_HEIGHT -1.0
#define OBJ_NONE -1
#define OBJ_GROUND 0
#define OBJ_SUNDIAL 1

// the main signed distance field for the scene
objdist mainDistance(vec3 position) {
    objdist result = objdist(HUGE, OBJ_NONE);
    result = sdfUnion(result, sdfSundial(position, OBJ_SUNDIAL));
    return result;
}

// gets the material properties at a point based on object id. can alter the normal
material materialForPoint(vec3 view, vec3 pos, inout vec3 normal, int obj) {
    switch(obj) {
        case OBJ_GROUND:
            normal = decodeNormal(sampleTriplanar(iChannel2, pos, normal, 1.0).xyz);
            return material(sampleTriplanar(iChannel0, pos, normal, 1.0).rgb, 0.9, 0.1, 4.0);
        case OBJ_SUNDIAL:
            return material(sampleTriplanar(iChannel1, pos, normal, 1.0).rgb, 0.4, 0.6, 128.0);
        default:
            return material(vec3(0.5, 0.0, 0.5), 1.0, 0.0, 0.0);
    }
}

// the unit vector pointing towards the sun
vec3 sunVec() {
    return normalize(vec3(cos(iTime), 0.6, sin(iTime))); // rotates in a circle in the xz plane; unrealistic
    
    /*
    vec2 circle = vec2(cos(iTime), sin(iTime)) * (1.0 - SUN_OFFSET * SUN_OFFSET);
    vec3 spherePos = vec3(SUN_OFFSET, circle.x, circle.y);
    float a = LATITUDE * TO_RADIANS;
    
    mat3x3 rotate = mat3x3(
        cos(a), sin(a), 0.0,
        -sin(a), cos(a), 0.0,
        0.0, 0.0, 1.0
    );
    return rotate * spherePos;
    */
}
/// END scene.glsl

struct ray {
    vec3 orig;
    vec3 dir;
};

// a ray-object intersection, containing the distance along the ray and the id of the hit object
struct hit {
    float t;
    int obj;
};

// march a ray through the scene, returning whatever it hits
hit raymarch(ray r, float minT, float maxT) {
    float t = minT;
    float groundT = (GROUND_HEIGHT - r.orig.y) / r.dir.y;
    if(groundT > 0.0 && groundT < maxT) maxT = groundT;
    
    for(int i = 0; i < MARCH_ITERATIONS && t < maxT; ++i) {
        objdist od = mainDistance(r.orig + r.dir * t);
        if(abs(od.dist) < EPSILON * t) { return hit(t, od.obj); }
        t += od.dist;
    }
    
    if(groundT > 0.0) { 
        return hit(groundT, OBJ_GROUND);
    } else {
        return hit(HUGE, OBJ_NONE);
    }
}

// march a ray through the scene, returning a shadow factor based on whether it hits an obstacle
float shadow(ray r, float minT, float maxT) {
    float groundT = (GROUND_HEIGHT - r.orig.y) / r.dir.y;
    if(groundT > 0.0) return 1.0; // TODO: Is the case where we graze the ground important enough to handle
    
    float shadowFactor = 1.0;
    float t = minT;
    objdist od = objdist(HUGE, -1);
    for(int i = 0; i < MARCH_ITERATIONS && t < maxT && abs(od.dist) > EPSILON * t; ++i) {
        od = mainDistance(r.orig + r.dir * t);
        shadowFactor = min(shadowFactor, 0.5 + 0.5 * od.dist / (t / SHADOW_SOFTNESS));
        t += od.dist;
    }
    
    return smoothstep(0.0, 1.0, shadowFactor);
}

// find the normal at a hit position, see http://iquilezles.org/www/articles/normalsSDF/normalsSDF.htm
vec3 worldNormal(vec3 pos) {
    /*
    float h = EPSILON; // todo: adapt to distance?
    const vec2 k = vec2(1,-1);
    return normalize( k.xyy*f( p + k.xyy*h ) + 
                      k.yyx*f( p + k.yyx*h ) + 
                      k.yxy*f( p + k.yxy*h ) + 
                      k.xxx*f( p + k.xxx*h ) );
    */
    
    // we have to do this to prevent inlining of mainDistance. But what the fuck is 0.5773?
    vec3 normal = vec3(0.0);
    for(int i = ZERO; i < 4; ++i) {
        vec3 e = 0.5773*(2.0*vec3((((i+3)>>1)&1),((i>>1)&1),(i&1))-1.0);
        normal += e * mainDistance(pos + e * EPSILON).dist;
    }
    
    return normalize(normal);
}

vec3 directLighting(material mat, vec3 view, vec3 pos, vec3 normal) {
    vec3 toSun = sunVec();
    ray shadowRay = ray(pos + 0.001 * normal, toSun);
    float shadowFactor = shadow(shadowRay, MIN_DIST, MAX_DIST);
    return
        mat.diffuse * AMBIENT +
        mat.diffuse * mat.color * SUNLIGHT * shadowFactor * max(0.0, dot(normal, toSun)) +
        mat.specular * SUNLIGHT * shadowFactor * pow(max(0.0, dot(normal, normalize(view + toSun))), mat.alpha);
}

vec3 shadeHit(ray r, hit h) {
    vec3 toCamera = -r.dir;
    vec3 pos = r.orig + r.dir * h.t;
    vec3 normal = h.obj == OBJ_GROUND ? vec3(0, 1, 0) : worldNormal(pos); // ground is raytraced not marched, special case
    
    material mat = materialForPoint(toCamera, pos, normal, h.obj);
    return directLighting(mat, toCamera, pos, normal);
}

// shade rays that never hit an object
vec3 shadeBackground(ray r) {
    float sunness = max(0.0, dot(r.dir, sunVec()));
    float sunFactor = pow(sunness, 256.0) + 0.2 * pow(sunness, 4.0);
    return vec3(SKY_COLOR + SUN_COLOR * sunFactor);
}

// calculate the worldspace ray through a pixel in screenspace
ray rayThrough(vec2 pixel) {
    float pixelScale = tan(FOV_Y * TO_RADIANS * 0.5);
    mat3x3 cameraTransform = mat3x3(cross(CAMERA_UP, CAMERA_FACING), CAMERA_UP, CAMERA_FACING);
    vec2 normCoord = pixelScale * (2.0 * pixel - iResolution.xy) / iResolution.y; 
    return ray(CAMERA_POS, normalize(cameraTransform * vec3(normCoord, 1.0)));
}

void mainImage(out vec4 fragColor, in vec2 pixel) {
    ray r = rayThrough(pixel);
    ray rdx = rayThrough(pixel + vec2(1, 0));
    ray rdy = rayThrough(pixel + vec2(0, 1));
    
    hit h = raymarch(r, MIN_DIST, MAX_DIST);
    fragColor = vec4(h.obj != -1 ? shadeHit(r, h) : shadeBackground(r), 1.0);
}

