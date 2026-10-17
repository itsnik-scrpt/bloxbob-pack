#version 330
#extension GL_ARB_separate_shader_objects : require

// 26.3 port of the mythicarmors (objmc) entity shader: vanilla 26.3 core/entity.fsh plus the 3D armor shading
// and BloxBob's glow (texture alpha 252 = full bright).

#define OC_EMISSIVE_INTENSITY 1.1

#include <minecraft:globals.glsl>
#include <minecraft:fog.glsl>
#if defined(PER_FACE_LIGHTING) || !defined(NO_CARDINAL_LIGHTING)
#include <minecraft:light.glsl>
#endif
#include <minecraft:dynamictransforms.glsl>
#include <minecraft:oit.glsl>

uniform sampler2D Sampler0;

#ifdef DISSOLVE
uniform sampler2D DissolveMaskSampler;
#endif

#ifdef GLINT
uniform sampler2D GlintSampler;
#endif

layout(location = 0) in float sphericalVertexDistance;
layout(location = 1) in float cylindricalVertexDistance;
#ifdef PER_FACE_LIGHTING
layout(location = 2) in vec4 vertexPerFaceColorBack;
layout(location = 3) in vec4 vertexPerFaceColorFront;
#else
layout(location = 2) in vec4 vertexColor;
#endif

layout(location = 4) in vec4 lightColor;
layout(location = 5) in vec4 overlayColor;
layout(location = 6) in vec2 texCoord0;
#ifdef GLINT
layout(location = 7) in vec2 texCoordGlint;
#endif
layout(location = 8) in vec2 texCoord2;
layout(location = 9) in vec3 Pos;
layout(location = 10) in float transition;
layout(location = 11) flat in ivec4 ocFlags;
layout(location = 12) flat in vec4 ocTint;
layout(location = 13) flat in vec2 ocMasks;

#ifndef OIT_ALPHA_ONLY
layout(location = 0) out vec4 fragColor;
#endif

#define texCoord texCoord0
#define isCustom ocFlags.x
#define noshadow ocFlags.y
#define ocLayerFlags ocFlags.z
#define ocEmissMaskV ocMasks.x
#define ocTintMaskV ocMasks.y

void main() {
#ifndef OC_NO_INVERTED_CUBES
    if (isCustom == 1 && !gl_FrontFacing) discard;
#endif
    vec4 tex = transition > 0.0
        ? mix(texture(Sampler0, texCoord), texture(Sampler0, texCoord2), transition)
        : texture(Sampler0, texCoord);
    // BloxBob glow: texture pixels with alpha exactly 252 are emissive (full bright)
    bool bloxGlow = isCustom == 0 && abs(tex.a * 255.0 - 252.0) < 0.5;
    if (bloxGlow) tex.a = 1.0;
    vec4 color = tex;
    bool ocEmissive = (isCustom == 1) && tex.a > 0.0 && (
        ((ocLayerFlags & 1) != 0) ||
        (ocEmissMaskV > 0.0 && texture(Sampler0, vec2(texCoord.x, texCoord.y + ocEmissMaskV)).a > 0.0)
    );
    bool ocTintable = (isCustom == 1) && tex.a > 0.0 && (
        ((ocLayerFlags & 2) != 0) ||
        (ocTintMaskV  > 0.0 && texture(Sampler0, vec2(texCoord.x, texCoord.y + ocTintMaskV )).a > 0.0)
    );
    vec3 ocBase = ocTintable ? tex.rgb * ocTint.rgb : tex.rgb;
    if (ocTintable) { color.rgb = ocBase; color.a = 1.0; }

#ifdef OIT_ADDITIVE
    color.a = min(0.99, color.a);
#endif

#ifdef DISSOLVE
    vec4 dissolveColor;
#ifdef PER_FACE_LIGHTING
    dissolveColor = gl_FrontFacing ? vertexPerFaceColorFront : vertexPerFaceColorBack;
#else
    dissolveColor = vertexColor;
#endif
    if (dissolveColor.a < texture(DissolveMaskSampler, texCoord0).a) discard;
#endif

    #define ENTITY
    #include <minecraft:mythicarmors_light.glsl>
#ifdef DISSOLVE
    // The dissolve effect entirely replaces translucency
    color.a = tex.a;
#endif
    if (bloxGlow) color = vec4(tex.rgb, 1.0) * ColorModulator;
    if (ocEmissive) { color.rgb = ocBase * OC_EMISSIVE_INTENSITY; color.a = 1.0; }
#ifdef ALPHA_CUTOUT
    if (color.a < ALPHA_CUTOUT) discard;
#endif
#ifndef NO_OVERLAY
    color.rgb = mix(overlayColor.rgb, color.rgb, overlayColor.a);
#endif

#ifdef GLINT
    color.a = max(color.a, GlintAlpha);
#endif

#ifdef OIT_ALPHA_ONLY
    executeAlphaOnlyPhase(gl_FragCoord.z, color.a);
#else
#ifdef GLINT
    vec4 glintColor = GlintAlpha * texture(GlintSampler, texCoordGlint);
    // Matches BlendFuntion.GLINT
    color.rgb += glintColor.rgb * glintColor.rgb;
#endif
#ifdef OIT_ACCUMULATE
    color = sampleColorForAccumulation(color);
    vec4 fogColor = vec4(FogColor.rgb * color.a, FogColor.a);
#else
    vec4 fogColor = FogColor;
#endif
    fragColor = apply_fog(color, sphericalVertexDistance, cylindricalVertexDistance, FogEnvironmentalStart, FogEnvironmentalEnd, FogRenderDistanceStart, FogRenderDistanceEnd, fogColor);
#endif
}
