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
objdist sdfSphere(vec3 pos, float radius, int obj) { 
    return objdist(length(pos) - radius, obj); 
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

// sundial
objdist sdfSundial(vec3 pos, int obj) {
    objdist result;
    result = objdist(max(abs(pos.z) - 0.1, max(pos.x + pos.y, -pos.x)), obj); // gnomon bounds
    result = sdfDifference(result, sdfCylinder((pos - vec3(-0.5, -1.1, 0)).xzy, 1.0, 0.4, obj)); // cylinder cut
    result = sdfUnion(result, sdfCylinder(pos - vec3(0, -1, 0), 1.0, 0.1, obj)); // dial

    vec3 cylindrical = toCylindrical(pos);
    cylindrical.y = mod(cylindrical.y + PI / 12.0, PI / 6.0) - PI / 12.0;
    vec3 newPos = fromCylindrical(cylindrical);
    
    result = sdfUnion(result, sdfSphere(newPos - vec3(0.85, -0.9, 0.0), 0.1, obj));
    return result;
}
