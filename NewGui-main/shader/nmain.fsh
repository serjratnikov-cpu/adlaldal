/*
 * Original shader from: https://www.shadertoy.com/view/WtyyRR
 */

#ifdef GL_ES
precision mediump float;
#endif

// glslsandbox uniforms
uniform float time;
uniform vec2 resolution;

// shadertoy emulation
#define iTime time
#define iResolution resolution

// --------[ Original ShaderToy begins here ]---------- //
// Author: paperu
// Title: cubes on background

#define PRC .0005
#define MAX_IT 70

#define P 3.14159265359
#define US 1./6.
#define UT 1./3.

float t = 0., fmode = 0.;
bool mode = false;
vec3 colorA = vec3(0.), colorB = vec3(0.);

mat2 rot(in float a) { return mat2(cos(a),sin(a),-sin(a),cos(a)); }
float rcub(in vec3 p, in float s, in float r) { return length(max(abs(p) - s, 0.)) - r; }
float cub(in vec3 p, in float s) { float sm = 0.05 - .049999*fmode; return rcub(p,s - sm,sm); }
float anim1(in float x, in float s) { x += .5; return smoothstep(-s,s,mod(x, 1.) - .5) + floor(x); }
float anim2(in float x, in float y, in float s) { return  smoothstep(-s,s,abs(mod(x,y) - y*.5) - y*.25); }

float df(in vec3 p) {
    float a = anim1(t,.45)*P;
    p.xy *= rot(mode ? 0. : P*.5);
    p.yz *= rot(a*.5);
    p.xz *= rot(a*1.);
    return mode
        ? min(min(cub(vec3(abs(p.x) - UT,p.yz - UT), US), cub(vec3(abs(p.x) - UT,p.yz + UT), US)),cub(p, US))
        : min(cub(vec3(abs(p.x) - UT,p.yz), US), min(cub(vec3(p.y - UT,p.x,p.z + UT), US), cub(vec3(p.y + UT,p.x,p.z - UT), US)));
}

vec3 normal(in vec3 p) { vec2 u = vec2(0., PRC); float d = df(p); return normalize(vec3(df(p + u.yxx), df(p + u.xyx), df(p + u.xxy)) - d); }

struct rmres { vec3 p; bool h; int i; };
rmres rm(in vec3 c, in vec3 r, in float maxD) {
    rmres res;
    vec3 p = c;
    bool h = false;
    for(int i = 0; i < MAX_IT; i++) {
        float d = df(p);
        if(d < PRC) { h = true; break; }
        if(distance(c, p) > maxD) { res.i = i; break; }
        p += r*d;
    }
    res.p = p;
    res.h = h;
    return res;
}

vec3 material(in vec3 r, in vec3 n, in vec3 l) {
    float diff = clamp(dot(n,l),.0,1.);
    float spec = min(pow(max(dot(reflect(r,n),l),0.),50.),1.);

    vec3 color = mix(colorA, colorB, .5*(diff + spec));
    color += vec3(pow(1.-dot(-r,n),3.));
    
    return color;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 st = (fragCoord.xy - .5*iResolution.xy)/iResolution.x;
    
    t = iTime*.25;
    
    mode = cos(t*P) > 0.;
    fmode = pow(anim2(t+.5,1.,.25),2.);
    
    float foc = 40. - 39.*(1.-pow(1.-anim2(t,1.,.25),30.));
    vec3 c = vec3(0.,0.,-foc), r = normalize(vec3(st,foc));
    
    rmres res = rm(c, r, 50.);
	
    colorA = vec3(0.); colorB = vec3(1.);
    vec3 color = mode ? colorB : colorA;
    
    if(res.h) {
        vec3 n = normal(res.p);
        vec3 l = normalize(vec3(0.,0.,mode ? 1. : -1.));
        vec3 ref = reflect(r,n);
        
        if(foc > 10.) {
            color = material(r, n, l);
        } else {
            rmres res2 = rm(res.p - r*PRC*2., ref, 5.);
            if(res2.h) {
                vec3 n = normal(res2.p);
                color = material(r, n, l)*material(ref, n, l);
            } else
                color = material(r, n, l);
        }
    }
                
    float ao = float(res.i)/float(MAX_IT);
    color += ao*ao*(1.-fmode);
    
    float l = length(st);
    float d = distance(c, res.p);
    fragColor = vec4(min(color, 1.) - l*l*.8,d);
}
// --------[ Original ShaderToy ends here ]---------- //

void main(void)
{
    mainImage(gl_FragColor, gl_FragCoord.xy);
}