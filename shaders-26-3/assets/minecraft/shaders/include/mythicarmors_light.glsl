//objmc
//https://github.com/Godlander/objmc


if (isCustom == 0) {
#ifndef EMISSIVE
    color *= lightColor;
#endif
#ifdef PER_FACE_LIGHTING
    color *= (gl_FrontFacing ? vertexPerFaceColorFront : vertexPerFaceColorBack);
#else
    color *= vertexColor;
#endif
#ifdef ENTITY
#ifndef NO_OVERLAY
    color.rgb = mix(overlayColor.rgb, color.rgb, overlayColor.a);
#endif
    color *= ColorModulator;
#endif
}
else if (noshadow == 0) {
#ifdef ENTITY
#if defined(PER_FACE_LIGHTING) || !defined(NO_CARDINAL_LIGHTING)
    vec3 normal = normalize(cross(dFdx(Pos), dFdy(Pos)));
    color *= minecraft_mix_light(Light0_Direction, Light1_Direction, normal, overlayColor);
#endif
#endif
    color *= lightColor;
}
