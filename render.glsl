// RAYMARCHING SETTINGS
#define MARCH_ITERATIONS 307
#define BOUNCES 3
#define MIN_DIST 0.01
#define MAX_DIST 80.0
#define AO_SAMPLES 32

#include "math.glsl"
#include "material.glsl"
#include "scene.glsl"

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
hit raymarch(ray r) {
    float t = MIN_DIST;

    for(int i = 0; i < MARCH_ITERATIONS && t < MAX_DIST; ++i) {
        objdist od = mainDistance(r.orig + r.dir * t);
        if(abs(od.dist) < EPSILON * t) { return hit(t, od.obj); }
        t += od.dist;
    }

    return hit(HUGE, OBJ_NONE);
}

// march a ray through the scene, returning a shadow factor based on whether it hits an obstacle
float shadow(ray r) {
    float res = 1.0;
    float t = MIN_DIST;
    float ph = HUGE;
    
    for(int i=0; i < MARCH_ITERATIONS; i++)
    {
        float h = mainDistance(r.orig + t * r.dir).dist;
        
        // in theory this should be 2.0 * ph. 3.0 * ph makes no mathematical sense whatsoever
        // but with 2.0 there are weird artifacts and 3.0 gets rid of them so... whatever
        float y = h*h / (3.0 * ph); 
        float d = sqrt(h * h - y * y);
        res = min(res, 20.0 * d / max(EPSILON, t - y));
        ph = h;
        t += h;
        if(res < -EPSILON || t > MAX_DIST) break;
    }
    return res;
}

float ao(vec3 pos, vec3 normal, float maxDist, float falloff) {
    float ao = 0.0;
    for(int i = 0; i < AO_SAMPLES; ++i) {
        float dist = maxDist * random(pos.xy + vec2(pos.z, i));
        vec3 sampleOffset = dist * normalize(rotateAround(normal) * (vec3(0, 0, 1) + sampleCosine(pos.yz + vec2(i, pos.x))));
        ao += (dist - max(mainDistance(pos + sampleOffset).dist, 0.0)) / maxDist * falloff;
    }
    return clamp(1.0 - ao / float(AO_SAMPLES), 0.0, 1.0);
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
    ray shadowRay = ray(pos + 0.01 * normal, toSun); // TODO: pos + length(pos) * a * normal?
    float shadowFactor = shadow(shadowRay);
    
    vec3 incoming = SUNLIGHT * shadowFactor;
    
    // return vec3(ao(pos, normal, 1.0, 1.2));
    
    vec3 ambient = AMBIENT * ao(pos, normal, 1.0, 1.2);
    vec3 diffuse = incoming * max(0.0, dot(normal, toSun));
    vec3 specular = mat.specular * incoming * pow(max(0.0, dot(normal, normalize(view + toSun))), mat.alpha);
    
    return (ambient + diffuse + specular) * mat.color;
}

vec3 shadeHit(ray r, vec3 rdx, vec3 rdy, hit h) {
    vec3 toCamera = -r.dir;
    vec3 pos = r.orig + r.dir * h.t;
    vec3 normal = worldNormal(pos);

    vec3 dPdx = h.t * (rdx * dot(r.dir, normal) / dot(rdx, normal) - r.dir);
    vec3 dPdy = h.t * (rdy * dot(r.dir, normal) / dot(rdy, normal) - r.dir);
    
    material mat = materialForPoint(toCamera, pos, dPdx, dPdy, normal, h.obj);
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
    vec3 rdx = rayThrough(pixel + vec2(1, 0)).dir;
    vec3 rdy = rayThrough(pixel + vec2(0, 1)).dir;
    
    hit h = raymarch(r);
    fragColor = vec4(h.obj != -1 ? shadeHit(r, rdx, rdy, h) : shadeBackground(r), 1.0);
}