//objmc
//https://github.com/Godlander/objmc


float ocEntityScale(vec3 p0, vec3 p1, vec3 p3, vec2 uv0, vec2 uv1, vec2 uv3) {
    float wW = length(p1 - p0) * 16.0;
    float wH = length(p3 - p0) * 16.0;
    float tW = length((uv1 - uv0) * vec2(64.0, 32.0));
    float tH = length((uv3 - uv0) * vec2(64.0, 32.0));
    if (tW < 0.001 || tH < 0.001) return 1.0;
    if (abs(wW - wH) < 0.001) return wW / (tW + 2.0);
    float inflate = (wH * tW - wW * tH) / (2.0 * (wW - wH));
    return wW / (tW + 2.0 * inflate);
}
ivec4 getmeta(ivec2 topleft, int offset) {
    return ivec4(texelFetch(Sampler0, topleft + ivec2(offset,0), 0) * 255.0 + 0.5);
}
vec3 getpos(ivec2 topleft, int w, int h, int index) {
    int i = index*3;
    vec4 x = texelFetch(Sampler0, topleft + ivec2((i  )%w,h+((i  )/w)), 0);
    vec4 y = texelFetch(Sampler0, topleft + ivec2((i+1)%w,h+((i+1)/w)), 0);
    vec4 z = texelFetch(Sampler0, topleft + ivec2((i+2)%w,h+((i+2)/w)), 0);
    return vec3(
        (x.r*256)+(x.g)+(x.b/256),
        (y.r*256)+(y.g)+(y.b/256),
        (z.r*256)+(z.g)+(z.b/256)
    )*(255./256.) - vec3(128);
}
vec2 getuv(ivec2 topleft, int w, int h, int index) {
    int i = index*2;
    vec4 x = texelFetch(Sampler0, topleft + ivec2((i  )%w,h+((i  )/w)), 0);
    vec4 y = texelFetch(Sampler0, topleft + ivec2((i+1)%w,h+((i+1)/w)), 0);
    return vec2(
        ((x.g*65280)+(x.b*255))/65535,
        ((y.g*65280)+(y.b*255))/65535
    );
}
ivec2 getvert(ivec2 topleft, int w, int h, int index) {
    int i = index*2;
    ivec4 a = ivec4(texelFetch(Sampler0, topleft + ivec2((i  )%w,h+((i  )/w)), 0)*255.0+0.5);
    ivec4 b = ivec4(texelFetch(Sampler0, topleft + ivec2((i+1)%w,h+((i+1)/w)), 0)*255.0+0.5);
    return ivec2(
        ((a.r*65536)+(a.g*256)+a.b),
        ((b.r*65536)+(b.g*256)+b.b)
    );
}
bool getb(int i, int b) {
    return bool((i>>b)&1);
}
int getb(int i, int b, int s) {
    return (i>>b)&((1<<s)-1);
}
vec3 bezb(vec3 a, vec3 b, vec3 c, vec3 d, float t) {
    float t2 = t * t;
    float t3 = t2 * t;
    return (d-3*c+3*b-a)*t3 + (3*c-6*b+3*a)*t2 + (3*b-3*a)*t + a;
}
vec3 bezier(vec3 a, vec3 b, vec3 c, vec3 d, float t) {
    return bezb(b,b+(c-a)/6,c-(d-b)/6,c,t);
}
