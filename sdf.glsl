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