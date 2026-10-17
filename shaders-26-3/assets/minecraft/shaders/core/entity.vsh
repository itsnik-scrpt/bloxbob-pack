#version 450
#extension GL_ARB_separate_shader_objects : require
#extension GL_KHR_shader_subgroup_quad : enable
#extension GL_KHR_shader_subgroup_basic : enable
#extension GL_ARB_shader_draw_parameters : enable

// 26.3 port of the mythicarmors (objmc) entity shader: vanilla 26.3 core/entity.vsh plus the 3D armor decode.

#if defined(PER_FACE_LIGHTING) || !defined(NO_CARDINAL_LIGHTING)
#include <minecraft:light.glsl>
#endif
#include <minecraft:fog.glsl>
#include <minecraft:dynamictransforms.glsl>
#include <minecraft:projection.glsl>
#include <minecraft:globals.glsl>
#include <minecraft:sample_lightmap.glsl>

layout(location = 0) in vec3 Position;
layout(location = 1) in vec4 Color;
layout(location = 2) in vec2 UV0;
layout(location = 3) in ivec2 UV1;
layout(location = 4) in ivec2 UV2;
layout(location = 5) in vec3 Normal;

uniform sampler2D Sampler0;

#if !defined(NO_OVERLAY) && !defined(OIT_ALPHA_ONLY)
uniform sampler2D Sampler1;
#endif

#if !defined(EMISSIVE) && !defined(OIT_ALPHA_ONLY)
uniform sampler2D Sampler2;
#endif

layout(location = 0) out float sphericalVertexDistance;
layout(location = 1) out float cylindricalVertexDistance;

#ifdef PER_FACE_LIGHTING
layout(location = 2) out vec4 vertexPerFaceColorBack;
layout(location = 3) out vec4 vertexPerFaceColorFront;
#else
layout(location = 2) out vec4 vertexColor;
#endif

layout(location = 4) out vec4 lightColor;
layout(location = 5) out vec4 overlayColor;
layout(location = 6) out vec2 texCoord0;
#ifdef GLINT
layout(location = 7) out vec2 texCoordGlint;
#endif
layout(location = 8) out vec2 texCoord2;
layout(location = 9) out vec3 Pos;
layout(location = 10) out float transition;
// x = isCustom, y = noshadow, z = ocLayerFlags
layout(location = 11) flat out ivec4 ocFlags;
layout(location = 12) flat out vec4 ocTint;
// x = emissive mask offset, y = tint mask offset
layout(location = 13) flat out vec2 ocMasks;

vec2 texCoord;
int isCustom;
int noshadow;
int ocLayerFlags;
float ocEmissMaskV;
float ocTintMaskV;

#include <minecraft:mythicarmors_tools.glsl>

void main() {
    Pos = Position;
    texCoord = UV0;
    ocTint = Color;
    lightColor = vec4(1.0);
    overlayColor = vec4(1.0);
#ifdef APPLY_TEXTURE_MATRIX
    texCoord = (TextureMat * vec4(UV0, 0.0, 1.0)).xy;
#endif
#ifdef GLINT
    texCoordGlint = (TextureMat * vec4(UV0, 0.0, 1.0)).xy;
#endif

    #define ENTITY
    #include <minecraft:mythicarmors_main.glsl>

    texCoord0 = texCoord;
    ocFlags = ivec4(isCustom, noshadow, ocLayerFlags, 0);
    ocMasks = vec2(ocEmissMaskV, ocTintMaskV);

    // Hidden carrier quads collapse to a point outside the view volume and emit no fragments.
    if (!ocHidden) {
#ifdef PER_FACE_LIGHTING
        vec2 light = minecraft_compute_light(Light0_Direction, Light1_Direction, Normal);
        vertexPerFaceColorBack = minecraft_mix_light_separate(-light, Color);
        vertexPerFaceColorFront = minecraft_mix_light_separate(light, Color);
#elif defined(NO_CARDINAL_LIGHTING)
        vertexColor = Color;
#else
        vertexColor = minecraft_mix_light(Light0_Direction, Light1_Direction, Normal, Color);
#endif

#if !defined(EMISSIVE) && !defined(OIT_ALPHA_ONLY)
        lightColor = sample_lightmap(Sampler2, UV2);
#endif

#if !defined(NO_OVERLAY) && !defined(OIT_ALPHA_ONLY)
        overlayColor = texelFetch(Sampler1, UV1, 0);
#endif

        gl_Position = ProjMat * ModelViewMat * vec4(Pos, 1.0);
        sphericalVertexDistance = fog_spherical_distance(Pos);
        cylindricalVertexDistance = fog_cylindrical_distance(Pos);
    } else {
#ifdef PER_FACE_LIGHTING
        vertexPerFaceColorBack = vec4(0.0);
        vertexPerFaceColorFront = vec4(0.0);
#else
        vertexColor = vec4(0.0);
#endif
        sphericalVertexDistance = 0.0;
        cylindricalVertexDistance = 0.0;
        gl_Position = vec4(-3.0, -3.0, -3.0, 1.0);
    }
}
