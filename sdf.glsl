// the distance to an object, along with that object's id
struct objdist {
    float dist;
    int obj;
};

// basic SDF operations
objdist sdfUnion(objdist a, objdist b) { if(a.dist < b.dist) { return a; } else { return b; } }
objdist sdfIntersection(objdist a, objdist b) { if(a.dist > b.dist) { return a; } else { return b; } }
objdist sdfDifference(objdist a, objdist b) { return sdfIntersection(a, objdist(-b.dist, b.obj)); }
objdist sdfRound(objdist a, float r) { return objdist(a.dist - r, a.obj); }
objdist sdfSmoothUnion(objdist a, objdist b, float k) {
    float h = clamp(0.5 + 0.5*(b.dist-a.dist)/k, 0.0, 1.0);
    float d = mix(b.dist, a.dist, h) - k*h*(1.0-h);
    return objdist(d, a.obj);
}

// SDF primitives
objdist sdfSphere(vec3 pos, float radius, int obj) { 
    return objdist(length(pos) - radius, obj); 
}	

objdist sdfPlane(vec3 pos, int obj) {
    return objdist(pos.y, obj);
}

objdist sdfCylinder(vec3 pos, float height, float radius, int obj)
{
    vec2 d = abs(vec2(length(pos.xz), pos.y)) - vec2(height, radius);
    return objdist(min(max(d.x, d.y), 0.0) + length(max(d, 0.0)), obj);
}

objdist sdfPyramid(vec3 pos, float height, int obj) {
    float m2 = height * height + 0.25;
    pos.xz = abs(pos.xz);
    pos.xz = (pos.z > pos.x) ? pos.zx : pos.xz;
    pos.xz -= 0.5;

    vec3 q = vec3( pos.z, height * pos.y - 0.5 * pos.x, height * pos.x + 0.5 * pos.y);

    float s = max(-q.x, 0.0);
    float t = clamp((q.y - 0.5 * pos.z) / (m2 + 0.25), 0.0, 1.0 );

    float a = m2 * (q.x + s) * (q.x + s) + q.y * q.y;
    float b = m2 * (q.x + 0.5 * t) * (q.x + 0.5 * t) + (q.y - m2 * t) * (q.y - m2 * t);

    float d2 = min(q.y, -q.x * m2 - q.y * 0.5) > 0.0 ? 0.0 : min(a, b);

    return objdist(sqrt((d2 + q.z * q.z) / m2) * sign(max(q.z, -pos.y)), obj);
}

objdist sdfCone(vec3 pos, float slope, int obj) {
    return objdist(sqrt(pow(pos.x * slope, 2.0) + pow(pos.z * slope, 2.0)) + pos.y, obj);
}

objdist sdfRoundCone(vec3 pos, float slope, int obj) {
    objdist cone = sdfCone(pos, slope, obj);
    objdist halfSpace = objdist(pos.y + 0.02, obj);
    objdist sphere = sdfSphere(pos + vec3(0, 0.02, 0), 0.012, obj);
    return sdfUnion(sdfIntersection(halfSpace, cone), sphere);
}

objdist sdfBox(vec3 pos, vec3 size, int obj)
{
  vec3 q = abs(pos) - size;
  return objdist(length(max(q, 0.0)) + min(max(q.x,max(q.y, q.z)), 0.0), obj);
}

objdist sdfDunes(vec3 pos, int obj) {
    objdist result = sdfRoundCone(pos - vec3(0, 0.3, 0), 0.5, obj);
    result = sdfSmoothUnion(result, sdfRoundCone(pos - vec3(-.7, 0.4, -.6), 0.5, obj), 0.15);
    result = sdfSmoothUnion(result, sdfRoundCone(pos - vec3(-1.5, 0.3, -.6), 0.5, obj), 0.15);
    result = sdfSmoothUnion(result, sdfRoundCone(pos - vec3(-3.2, 0.2, -.6), 0.5, obj), 0.15);
    result = sdfSmoothUnion(result, sdfRoundCone(pos - vec3(-3.7, 0.3, 0.1), 0.5, obj), 0.15);
    result = sdfSmoothUnion(result, sdfRoundCone(pos - vec3(-3.3, 0.4, 1.4), 0.5, obj), 0.15);
    result = sdfSmoothUnion(result, sdfRoundCone(pos - vec3(-1.5, 0.5, 2.8), 0.5, obj), 0.15);
    result = sdfSmoothUnion(result, sdfRoundCone(pos - vec3(0.8, 0.2, 0.6), 0.5, obj), 0.15);
    return sdfRound(result, 0.05);
}

// everything made of sand
objdist sdfDesert(vec3 pos, int obj) {
    objdist result = sdfPlane(pos - vec3(0, -1, 0), obj);
    
    objdist dunes = sdfDunes((pos - vec3(30, -1.1, -30)) / 28.0, obj);
    dunes.dist *= 28.0;
    
    objdist sundialSand = sdfCylinder(pos - vec3(0, -1, 0), 1.0, 0.03, obj);
    // objdist pyramidSand = sdfBox(pos - vec3(-16, -1.1, -30), vec3(10.5, 0.3, 10.5);
    
    result = sdfSmoothUnion(result, dunes, 4.0);
    float a = toCylindrical(pos).y + PI;
    float sandySmooth = 0.2 + 0.06 * (sin(18.0 * a  - 4.1) + sin((10.0 * a) - 7.8) + cos((6.0 * a) - 1.4));
    result = sdfSmoothUnion(result, sundialSand, sandySmooth);
    
    return sdfRound(result, 0.05);
}

// sundial
objdist sdfSundial(vec3 pos, int obj) {
    objdist result;
    result = objdist(max(abs(pos.z) - 0.1, max(pos.x + pos.y - 0.1, -pos.x)), obj); // gnomon bounds
    result = sdfDifference(result, sdfCylinder((pos - vec3(-0.5, -1.0, 0)).xzy, 1.0, 0.4, obj)); // cylinder cut
    result = sdfUnion(result, sdfCylinder(pos - vec3(0, -1, 0), 1.0, 0.2, obj)); // dial

    vec3 cylindrical = toCylindrical(pos);
    cylindrical.y = mod(cylindrical.y + PI / 12.0, PI / 6.0) - PI / 12.0;
    
    vec3 newPos = fromCylindrical(cylindrical);
    
    result = sdfUnion(result, sdfSphere(newPos - vec3(0.85, -0.8, 0.0), 0.08, obj));
    return result;
}
