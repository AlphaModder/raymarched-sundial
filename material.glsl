struct material {
    vec3 color; // the diffuse color of the object
    float diffuse; // how much of the incoming light undergoes diffuse reflection
	float specular; // how much of the incoming light undergoes specular reflection
    float alpha; // the specular exponent of the material
};