#include "math.glsl"

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
    vec3 normal = calcNormal(pos);
    
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

