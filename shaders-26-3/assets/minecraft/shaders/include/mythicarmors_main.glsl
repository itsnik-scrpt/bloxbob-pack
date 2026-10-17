//objmc
//https://github.com/Godlander/objmc


// PackBuilder rewrites these two literals from the render-distance config.
#define OC_LOD_DISTANCE 32.0
#define OC_LOD_DISTANCE_LOW 16.0   // small-subgroup GPUs (Intel iGPU + ARC)
isCustom = 0;
transition = 0;
ocLayerFlags = 0;
ocEmissMaskV = 0.0;
ocTintMaskV  = 0.0;
noshadow = 0;
texCoord2 = vec2(0.0);
// Hidden carrier quads collapse to a point and emit no fragments, so the
// importer may skip fragment-only work.
bool ocHidden = false;
#ifdef ENTITY
#define OC_VARIANT_SKELETON 254
if (isCustom == 0) {
    ivec4 am = ivec4(texelFetch(Sampler0, ivec2(0,0), 0)*255.0+0.5);
    if (am.rgb == ivec3(12,34,56) && (am.a == 254 || am.a == 253)) {
        isCustom = 1;
#if defined(GL_KHR_shader_subgroup_quad)
        // Staged by fetch cost: LOD (0 fetches) -> slot (1) -> face key (1-2)
        // -> full decode. Every branch condition is identical across a carrier
        // quad's 4 lanes, keeping subgroupQuadBroadcast quad-uniform.
        vec3 ocRef = subgroupQuadBroadcast(Position, 0u);
        float ocScale = ocEntityScale(
            ocRef, subgroupQuadBroadcast(Position, 1u), subgroupQuadBroadcast(Position, 3u),
            subgroupQuadBroadcast(UV0, 0u), subgroupQuadBroadcast(UV0, 1u), subgroupQuadBroadcast(UV0, 3u)
        );
        float ocDist = length((ModelViewMat * vec4(ocRef, 1.0)).xyz);
        float ocLod = ((gl_SubgroupSize <= 16u) ? OC_LOD_DISTANCE_LOW : OC_LOD_DISTANCE) * ocScale;
        // GUI PiP passes (the only orthographic ProjMat) ignore the LOD so
        // inventory previews stay 3D at any configured distance.
        if (ProjMat[2][3] != 0.0 && ocDist >= ocLod) {
            Pos = vec3(9999.0);
            ocHidden = true;
        } else {
        ivec2 ao = ivec2(0);
        ivec4 t8 = getmeta(ao, 8);
        int nboxes = max(t8.a, 1);
        int amod = nboxes * 24;
        int aid = ((gl_VertexIndex - gl_BaseVertexARB) % amod + amod) % amod;
        int aface = aid / 4;
        int abody = aface / 6;
        int ocVariant = int(Color.r * 255.0 + 0.5);
        if (ocVariant == OC_VARIANT_SKELETON && nboxes >= 3) {
            if (abody == 1) abody = 2;
            else if (abody == 2) abody = 1;
        }
        int ac = aid % 4;
        int f6 = aface % 6;
        bool hide = (f6 == 1) || (abody >= nboxes);
        int atarget = 0;
        int afk = 65535;
        if (!hide) {
            ivec4 tb = (abody == 0) ? t8 : getmeta(ao, 8 + abody);
            atarget = tb.b;
            if (atarget < 0 || atarget > 7) atarget = 0;
            if      (f6 == 3) afk = tb.r * 256 + tb.g;
            else if (f6 == 5) { ivec4 m = getmeta(ao, 11 + abody); afk = m.r * 256 + m.g; }
            else if (f6 == 2) { ivec4 m = getmeta(ao, 14 + abody); afk = m.r * 256 + m.g; }
            else if (f6 == 4) { ivec4 m = getmeta(ao, 17 + abody); afk = m.r * 256 + m.g; }
            else if (f6 == 0) { ivec4 m = getmeta(ao, 23 + abody); afk = m.r * 256 + m.g; }
            hide = (afk == 65535) || (f6 == 0 && atarget != 0);
        }
        if (hide) {
            Pos = vec3(9999.0);
            ocHidden = true;
        } else {
            ivec4 t[8];
            for (int i = 1; i < 8; i++) t[i] = getmeta(ao, i);
            ivec2 as = ivec2(t[1].r*256+t[1].g, t[1].b*256+t[7].r);
            int anv = t[2].r*16777216+t[2].g*65536+t[2].b*256+t[7].g;
            int anf = max(t[3].r*65536+t[3].g*256+t[3].b, 1);
            int ant = max(t[3].a, 1);
            float adur = max(float(t[4].r*65536+t[4].g*256+t[4].b), 1.0);
            bool aap = getb(t[4].a, 6);
            int avph = t[5].r*256+t[5].g;
            int avth = t[5].b*256+t[7].b;
            noshadow = getb(t[6].r, 7, 1);
            float at = GameTime * 24000.0;
            at = aap ? at + adur : 0.0;
            int afr = int(at * float(anf) / adur) % anf;
            ivec2 atlasSize = textureSize(Sampler0, 0);
            vec2 onepixel = 1./atlasSize;
            ivec4 em = getmeta(ao, 20 + abody);
            ivec4 df = getmeta(ao, 26 + abody);
            int ocEOff = df.r * 256 + df.g;
            int ocTOff = df.b * 256 + df.a;
            if      (ocEOff == 65535) ocLayerFlags |= 1;
            else if (ocEOff  > 0)     ocEmissMaskV = float(ocEOff) / float(atlasSize.y);
            if      (ocTOff == 65535) ocLayerFlags |= 2;
            else if (ocTOff  > 0)     ocTintMaskV  = float(ocTOff) / float(atlasSize.y);
            int aemis = (f6 == 3) ? em.r
                      : (f6 == 5) ? em.g
                      : (f6 == 2) ? em.b
                      : (f6 == 4) ? em.a
                      : 0;
            int f6geo = (gl_BaseVertexARB == 0 && (f6 == 2 || f6 == 4)) ? (6 - f6) : f6;
            bool aleft = (atarget == 3 || atarget == 5 || atarget == 7);
            const vec3 AOFF[8] = vec3[8](
                vec3(0.2925, -0.785,  -0.175),
                vec3(0.2925, -0.045, -0.2925),
                vec3(0.2375,  -0.66,  -0.175),
                vec3(0.2375,  0.16,   -0.175),
                vec3(0.14,   -0.765,   -0.14),
                vec3(0.14,   -0.015,   -0.14),
                vec3(0.17,   -0.804, -0.17),
                vec3(0.17,   0.004,  -0.17)
            );
            const float ADWs[8] = float[8]( 2.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0 );
            const float ADHs[8] = float[8]( -1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 );
            const float ADWe[8] = float[8]( 0.5, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0 );
            const float ADHe[8] = float[8]( 0.5, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 );
            if (aemis > 0) noshadow = 1;
            int avid = (afk * 4 + ac) % anv;
            avid += afr * anv;
            int ahh = 2 + int(ceil(float(anv)*0.25/float(as.x)));
            int ah = ahh + (as.y * ant);
            ivec2 ai = getvert(ao, as.x, ah+avph+avth, avid);
            vec3 posoffset = getpos(ao, as.x, ah, ai.x);
            ivec2 aeasing = ivec2(getb(t[4].a, 4, 2), getb(t[4].a, 2, 2));
            if (anf > 1 && aeasing.x > 0) {
                int avbase = (afk * 4 + ac) % anv;
                float atr = fract(at * float(anf) / adur);
                vec3 po2 = getpos(ao, as.x, ah, getvert(ao, as.x, ah+avph+avth, avbase + ((afr + 1) % anf) * anv).x);
                if (aeasing.x == 3) {
                    vec3 po3 = getpos(ao, as.x, ah, getvert(ao, as.x, ah+avph+avth, avbase + ((afr + 2) % anf) * anv).x);
                    vec3 po4 = getpos(ao, as.x, ah, getvert(ao, as.x, ah+avph+avth, avbase + ((afr + 3) % anf) * anv).x);
                    posoffset = bezier(posoffset, po2, po3, po4, atr);
                } else {
                    if (aeasing.x == 2) atr = atr < 0.5 ? 4.0 * atr * atr * atr : 1.0 - pow(-2.0 * atr + 2.0, 3.0) * 0.5;
                    posoffset = mix(posoffset, po2, atr);
                }
            }
            vec2 auv = getuv(ao, as.x, ah+avph, ai.y);
            vec2 ajit = vec2(onepixel.x*0.0001*float(ac), onepixel.y*0.0001*float((ac+1)%4));
            texCoord = (vec2(0, ahh) + auv*vec2(as))/vec2(atlasSize) + ajit;
            if (ant > 1) {
                ivec4 texmeta  = ivec4(texelFetch(Sampler0, ao + ivec2(4,1), 0)*255.0+0.5);
                ivec4 texflags = ivec4(texelFetch(Sampler0, ao + ivec2(5,1), 0)*255.0+0.5);
                float texFrametime = max(float(texmeta.r*65536 + texmeta.g*256 + texmeta.b), 1.0);
                float texTime = GameTime * 24000.0;
                int texframe = int(texTime / texFrametime) % ant;
                int texnext  = (texframe + 1) % ant;
                texCoord  = (vec2(0, ahh + texframe*as.y) + auv*vec2(as))/vec2(atlasSize) + ajit;
                texCoord2 = (vec2(0, ahh + texnext *as.y) + auv*vec2(as))/vec2(atlasSize) + ajit;
                transition = bool(texflags.r) ? fract(texTime / texFrametime) : 0.0;
            }
            if (aleft) posoffset.x = -posoffset.x;
            posoffset -= AOFF[atarget];
            if (aleft) posoffset.y -= 0.05;
            if (atarget == 0) posoffset.x -= 0.02;
            if (atarget == 0) {
                bool aLegLayer = false;
                for (int b = 0; b < nboxes; b++) {
                    int bp = ((b == 0) ? t8 : getmeta(ao, 8 + b)).b;
                    if (bp == 4 || bp == 5) { aLegLayer = true; break; }
                }
                if (aLegLayer) posoffset -= vec3(-0.0293, 0.0293, 0.0293);
            }
            vec3 a0 = ocRef;
            vec3 a1 = subgroupQuadBroadcast(Pos, 1u);
            vec3 a2 = subgroupQuadBroadcast(Pos, 2u);
            vec3 a3 = subgroupQuadBroadcast(Pos, 3u);
            vec3 e1 = normalize(a0 - a1);
            vec3 e2 = normalize(a0 - a3);
            e2 = normalize(e2 - dot(e2, e1) * e1);
            // GUI picture-in-picture passes are the only orthographic ProjMat
            // (m23 == 0; world is perspective, m23 == -1) and bake a mirrored
            // pose into Position; cross() flips under a mirror, so correct its
            // sign there. Winding still matches: the ortho y-flip cancels the
            // pose's z-mirror on screen.
            vec3 cr = cross(e1, e2);
            if (ProjMat[2][3] == 0.0) cr = -cr;
            // Columns of abasis * CF written out directly: the per-face frame
            // matrices are signed axis permutations, so the product is a column
            // pick with sign flips, exactly equal to the multiply it replaces.
            vec3 se2 = aleft ? -e2 : e2;
            mat3 abasisBox = (f6geo == 5) ? mat3( e1, se2,  cr)
                           : (f6geo == 2) ? mat3( cr, se2, -e1)
                           : (f6geo == 4) ? mat3(-cr, se2,  e1)
                           : (f6geo == 0) ? mat3(-e1,  cr, se2)
                           :                mat3(-e1, se2, -cr);
            posoffset = abasisBox * posoffset;
            vec3 n = cr;
            float lenW = length(a0 - a1);
            float lenH = length(a0 - a3);
            vec3 anchor;
            if      (f6geo == 3) anchor = a2;
            else if (f6geo == 0) anchor = a2 - 1.40 * lenW * n;
            else if (f6geo == 2) anchor = a2 + (a0 - a1);
            else if (f6geo == 5) anchor = a2 + (a0 - a1)
                              - (ADWs[atarget]*lenW + ADHs[atarget]*lenH) * n;
            else              anchor = a2
                              - (ADWe[atarget]*lenW + ADHe[atarget]*lenH) * n;
            Pos = anchor + posoffset * ocScale;
            }
        }
#else
        Pos = vec3(9999.0);
        ocHidden = true;
#endif
    }
#if defined(GL_KHR_shader_subgroup_quad)
    else if (am.rgb == ivec3(12,34,56) && am.a == 252) {
        vec3 ocRef = subgroupQuadBroadcast(Position, 0u);
        float ocScale = ocEntityScale(
            ocRef, subgroupQuadBroadcast(Position, 1u), subgroupQuadBroadcast(Position, 3u),
            subgroupQuadBroadcast(UV0, 0u), subgroupQuadBroadcast(UV0, 1u), subgroupQuadBroadcast(UV0, 3u)
        );
        float ocDist = length((ModelViewMat * vec4(ocRef, 1.0)).xyz);
        float ocLod = ((gl_SubgroupSize <= 16u) ? OC_LOD_DISTANCE_LOW : OC_LOD_DISTANCE) * ocScale;
        if (ProjMat[2][3] == 0.0 || ocDist < ocLod) {
            Pos = vec3(9999.0);
            ocHidden = true;
        }
    }
#endif
}
#endif
