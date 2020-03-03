#define MARCH_ITERATIONS 128

#define CAMERA_POS vec3(0, 3, 10)
#define CAMERA_FACING vec3(0, 0, -1)
#define CAMERA_UP vec3(0, 1, 0)
#define FOV_Y 70.0

struct ray {
    vec3 orig;
    vec3 dir;
};

struct hit {
    float t;
    int obj;
};

// the distance to an object, along with that object's id
struct objdist {
    float dist;
    int obj;
};

struct material {
    float diffuse;
    float specConeAngle;
};
    
const material MATERIALS[3] = {
    
};
    
objdist union(objdist a, objdist b) {
    return (a.dist < b.dist) ? a : b;
}
    
objdist mainDistance(vec3 position) {
    objdist result;
    
}

hit raymarch(ray r, float maxdist, float mindist) {
    float dist = mindist;
    for(int i = 0; i < MARCH_ITERATIONS && dist < maxDist; ++i) {
        objdist od = mainDistance(r.orig + r.dir * dist);
        if(abs(od.dist) < EPISILON * dist) {
            return hit(dist, od.obj);
        }
        dist += od.dist;
    }
    return hit(-1.0, -1);
}

// calculate the worldspace ray through a pixel in screenspace
ray rayThrough(vec2 pixel) {
    float pixelScale = tan(FOV_Y * TO_RADIANS * 0.5);
    mat3x3 cameraTransform = mat3x3(cross(CAMERA_UP, CAMERA_FACING), CAMERA_UP, CAMERA_FACING);
    vec2 normCoord = pixelScale * (2.0 * fragCoord - iResolution.xy) / iResolution.y; 
    return ray(CAMERA_POS, normalize(cameraTransform * vec3(normCoord, 1.0)));
}

// find the normal at a hit position, see http://iquilezles.org/www/articles/normalsSDF/normalsSDF.htm
vec3 calcNormal(vec3 pos) 
{
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

// get the direction of the sun at the current time
vec3 sunVec() {
    return normalize(vec3(cos(iTime), 0.6, sin(iTime)));
}

// shade rays that never hit an object
vec3 shadeBackground(ray r) {
    
}

// shade a ray that hit an object in the scene
vec3 shade(hit h, ray r, ray rdx, ray rdy) {
    vec3 pos = r.orig + r.dir * hit.t;
    vec3 normal = calcNormal(pos);
    
    material mat = MATERIALS[h.obj];
    vec3 reflected = random() < mat.diffuse ? 
        rotateAround(normal) * sampleCosine() : 
        rotateAround(reflect(r.dir, normal)) * sampleCone(mat.specConeAngle);
    
    
}

void mainImage( out vec4 fragColor, in vec2 pixel)
{
    ray r = rayThrough(pixel);
    ray rdx = rayThrough(pixel + vec2(1, 0));
    ray rdy = rayThrough(pixel + vec2(0, 1));
   
    hit h = raymarch(r);
    fragColor = h.obj != -1 ? shade(h, r, rdx, rdy) : shadeBackground(r);
}
