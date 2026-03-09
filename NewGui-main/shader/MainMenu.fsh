/*
 * Original shader from: https://www.shadertoy.com/view/XtyBWt
 */
// KNOB (more + growing) 19/12/2018

#extension GL_OES_standard_derivatives : enable

#ifdef GL_ES
precision highp float;
#endif

// glslsandbox uniforms
uniform float time;
uniform vec2 resolution;
uniform vec2 mouse;

// shadertoy globals
float iTime = 0.0;
vec3  iResolution = vec3(0.0);
vec4  iMouse = vec4(0.0);

// Emulate a black texture
#define texture(s, uv) vec4(0.0)

// --------[ Original ShaderToy begins here ]---------- //
#define EPSILON 0.0001
#define NEARCLIP 0.0001
#define FARCLIP 100.0
#define MARCHSTEPS 500

#define ALL 1
#define CUBEMAP_REFLECTION 1
#define BLINN_PHONG 1
#define AO 1
#define SHADOWS 1
#define SCENE_REFLECTION 1
#define SSS 1
#define VIGNETTE 1
#define COLOR 1

#define SSS_STEPS 25

struct Material
{
    vec3 ambient;
    vec3 diffuse;
    vec3 specular;
    float shininess;
    float reflection;
    float sss;
};

struct DirLight
{
    vec3 dir;
    vec3 color;
};

struct RayResult
{
    float dist;
    Material material;
};

const Material kNoMaterial = Material(
    vec3(0.0, 0.0, 0.0),
    vec3(0.0, 0.0, 0.0),
    vec3(0.0, 0.0, 0.0),
    0.0,
    0.0,
    0.0
);

const Material kMaterialRed = Material(
    vec3(0.2, 0.0, 0.0),
    vec3(0.7, 0.1, 0.1),
    vec3(0.8, 0.5, 0.5),
    256.0,
    0.0,
    5.0
);

const Material kMaterialGreen = Material(
    vec3(0.2, 0.0, 0.0)*0.8,
    vec3(0.7, 0.1, 0.1)*0.47,
    vec3(0.9, 0.5, 0.5)*0.8,
    512.0,
    0.0,
    5.0
);

const Material kMaterialBlue = Material(
    vec3(0.0, 0.0, 0.1),
    vec3(0.1, 0.1, 0.1),
    vec3(0.9, 1.0, 1.0),
    1024.0,
    0.4,
    9.0
);


DirLight kDirLight = DirLight(
    vec3(0.3, 0.35, 0.1),
    vec3(0.9)
);

const vec3 kAmbientColor = vec3(0.0, 0.05, 0.1);

vec3 hash( vec3 p )
{
    p = vec3( dot(p,vec3(127.1,311.7, 74.7)),
              dot(p,vec3(269.5,183.3,246.1)),
              dot(p,vec3(113.5,271.9,124.6)));

    return fract(sin(p)*43758.5453123);
}

RayResult opUnion(in RayResult a, in RayResult b)
{
    if (a.dist < b.dist) return a;
    return b;
}

RayResult opUnion2(in RayResult a, in RayResult b)
{
    if (-a.dist < b.dist) return a;
    return b;
}

float sdRoundBox( vec3 p, vec3 b, float r )
{
  vec3 d = abs(p) - b;
  return length(max(d,0.0)) - r
         + min(max(d.x,max(d.y,d.z)),0.0); // remove this line for an only partially signed sdf 
}

float sdSphere(in vec3 p, float r)
{
    return length(p) - r;
}

float sdBox( vec3 p, vec3 b )
{
  vec3 d = abs(p) - b;
  return length(max(d,0.0))
         + min(max(d.x,max(d.y,d.z)),0.0); // remove this line for an only partially signed sdf 
}

float sdTorus( vec3 p, vec2 t )
{
  vec2 q = vec2(length(p.xz)-t.x,p.y);
  return length(q)-t.y;
}

float sdPlane( vec3 p, vec4 n )
{
  // n must be normalized
  return dot(p,n.xyz) + n.w;
}

float opDisp(vec3 p)
{
    return sin(20.0*p.x)*sin(20.0*p.y)*sin(20.0*p.z);
}

void opRotate(inout vec2 v, float r)
{
    float c = cos(r);
    float s = sin(r);
    float vx = v.x * c - v.y * s;
    float vy = v.x * s + v.y * c;
    v.x = vx;
    v.y = vy;
}

#define CHS 0.2
#define PI 3.14159
#define	TAU 6.28318
#define DEG2RAD ((PI * 2.0) / 360.0)

float sdBox2(in vec2 p,in vec2 b) {vec2 d=abs(p)-b;return length(max(d,vec2(0))) + min(max(d.x,d.y),0.0);}
float line2(float d,vec2 p,vec4 l){vec2 pa=p-l.xy;vec2 ba=l.zw-l.xy;float h=clamp(dot(pa,ba)/dot(ba,ba),0.0,1.0);return min(d,length(pa-ba*h));}
float LR(vec2 p, float d){p.x=abs(p.x);return line2(d,p,vec4(2,-3.25,2,3.25)*CHS);}
float TBLR(vec2 p, float d){return min(d,abs(sdBox2(p,vec2(2,3.25)*CHS)));}
float K(vec2 p,float d){ d=line2(d,p,vec4(-2,-3.25,-2,3.25)*CHS);d=line2(d,p,vec4(-2,-0.25,-0.5,-0.25)*CHS);d=line2(d,p,vec4(2,3.25,-0.5,-0.25)*CHS);return line2(d,p,vec4(-0.5,-0.25,2,-3.25)*CHS);}
float N(vec2 p,float d){ d=LR(p,d);return line2(d,p,vec4(-2,3.25,2,-3.25)*CHS);}
float O(vec2 p,float d){ return TBLR(p,d);}
float B(vec2 p,float d){ p.y+=1.75*CHS;d=min(d,abs(sdBox2(p,vec2(2.0,1.5)*CHS)));p+=vec2(0.5,-3.25)*CHS;return min(d,abs(sdBox2(p,vec2(1.5,1.75)*CHS)));}

float message(vec3 p)
{
    float d = 100.0;
    float cw = 5.8*CHS;

	p.x += sin(time*0.9)*2.0;
	p.z -= 2.9;
	float t1 = fract(iTime*0.35) * TAU;
	p.y -= sin(t1+p.x*0.55)*0.9;
	vec2 uv = p.xy + vec2(2.0, -0.1);
	d = K(uv,d); uv.x -= cw;
	d = N(uv,d); uv.x -= cw;
	d = O(uv,d); uv.x -= cw;
	d = B(uv,d);

	d-=0.25*CHS;
	float dep = 0.2;
	vec2 e = vec2( d, abs(p.z) - dep );
	d = min(max(e.x,e.y),0.0) + length(max(e,0.0));
	d -= 0.225*CHS;
	return d;
}


    mat2 Rot2(float a ) {
        float c = cos( a );
        float s = sin( a );
        return mat2( c, -s, s, c );
    }
vec3 rotateY(vec3 p, float a)
{
  float sa = sin(a);
  float ca = cos(a);
  return vec3(ca * p.x + sa * p.z, p.y, -sa * p.x + ca * p.z);
}

vec3 rotateZ(vec3 p, float a)
{
  float sa = sin(a);
  float ca = cos(a);
  return vec3(ca * p.x - sa * p.y, sa * p.x + ca * p.y, p.z);
}

    // ========================================
    float sdCappedCylinder( vec3 p, vec2 h ) {
        vec2 d = abs(vec2(length(p.xz),p.y)) - h;
        return min(max(d.x,d.y),0.0) + length(max(d,0.0));
    }

    // iq's bend X
    // ========================================
    vec3 opCheapBend( vec3 p, float angle ) {
        mat2  m = Rot2( angle * p.y );
        vec3  q = vec3( m*p.yx, p.z );
        return q;
    }


vec3 CalcBend(vec3 bodyp)
{
    float ang = sin(time) * 8. ;
    ang += sin(time*0.31) * 4.;
    bodyp.y += 2.0;
	bodyp = opCheapBend(bodyp,(ang)*DEG2RAD);
    bodyp = rotateZ(bodyp,90.0*DEG2RAD);
    bodyp.y -= 2.0;
    return bodyp;
    
}

float smin( float a, float b )
{
    float k = 3.0;
    float res = exp( -k*a ) + exp( -k*b );
    return -log( res )/k;
}
float smin( float a, float b, float k )
{
    float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.0-h);
}

float extra = 1.0;

float displacement_t1(vec3 p)
{
    p = rotateY(p,DEG2RAD*180.0);
    float height = 0.05;
    float zn = smoothstep(0.0,1.0,p.z);
    float yn = smoothstep(-0.1,0.5,p.y);
    float _x = clamp(p.x,-0.05,0.05);
    float xn = (_x + 0.05) * 10.0;			// normalize band
    xn = sin(xn*(PI));
    xn *= zn;
    xn *= yn;
    return -height*xn;
}
float sdEllipsoid(const in  vec3 p, const in vec3 r) {
  return (length(p / r) - 1.0) * min(min(r.x, r.y), r.z);
}
float opS( float d1, float d2 )
{
    return max(-d2,d1);
}


float knob1(vec3 p,vec3 bodyp)
{
    float _h = 1.5+extra;
    float yo = (0.5+sin(time*3.63)*0.5)*0.125;
    float d1 = sdCappedCylinder(bodyp+vec3(0.0,yo,0.0),vec2(0.75,_h));
    float d6 = sdSphere(bodyp-vec3(0.7,-2.5,0.0),1.4);
    float d7 = sdSphere(bodyp-vec3(-0.7,-2.5,0.0),1.4);
    // nad displacement
    float k = dot(sin(p*70. - cos(p.yzx*0.1)), vec3(.333))*.006;
    d6+=k;	
    d7+=k;	
    d1 = smin(d1,d6,0.27);		// nut
    d1 = smin(d1,d7,0.27);		// nut
    return d1;
}

float bellend(vec3 p,vec3 bodyp)
{
    float box5 = sdEllipsoid(bodyp-vec3(0.0,1.5+extra,0.0),vec3(0.04,1.2,0.125));    
    float dome = sdEllipsoid(bodyp-vec3(0.0,1.5+extra,0.0),vec3(0.70,0.75,0.70));
    dome += displacement_t1(bodyp-vec3(0.0,1.4+extra,0.0));
    float box1 = sdBox(bodyp-vec3(0.0,0.5,0.1),vec3(5.0,0.5,5.0));
    dome = opS(dome,box5);
    dome = opS(dome,box1);
    return dome;
}

RayResult opUnion3(in RayResult a, in RayResult b)
{
    float merge = smin(a.dist,b.dist,0.425);
    if (a.dist < b.dist){a.dist = merge;return a;}
    b.dist = merge;
    return b;
}

RayResult mapScene(in vec3 p)
{   
	extra = (0.5+sin(time*1.25)*0.5)*1.4;
    p.y += 0.2;
	p.x = mod(p.x,11.0)-5.5;
    float dm = message(p);
    vec3 bodyp = p;
    bodyp = CalcBend(bodyp);
	
	p.y += 1.7;
	float d1 = knob1(p,bodyp);
	float dome = bellend(p,bodyp);
	
	float b = d1;
	float c = dome;
	
    float a = sdBox(p + vec3(0.0, 1.2, 0.0), vec3(4.0, 1.2, 4.0));
    a = smin(a,dm,0.4);
    return opUnion(RayResult(a, kMaterialBlue),opUnion3(RayResult(b, kMaterialRed), RayResult(c, kMaterialGreen)));
}

vec3 opNormal(in vec3 p)
{
    const vec2 e = vec2(0.0, EPSILON);
    return normalize(vec3(
        mapScene(p + e.yxx).dist - mapScene(p - e.yxx).dist,
        mapScene(p + e.xyx).dist - mapScene(p - e.xyx).dist,
        mapScene(p + e.xxy).dist - mapScene(p - e.xxy).dist
    ));
}

RayResult rayMarch(in vec3 ro, in vec3 rd)
{
    float total = NEARCLIP;
    
    for (int i = 0; i < MARCHSTEPS; ++i)
    {
        RayResult ray = mapScene(ro + rd * total);
        if (ray.dist < EPSILON)
        {
            return RayResult(total, ray.material);
        }
        
        total += ray.dist * 0.5;
        if (total > FARCLIP)
        {
            break;
        }
    }
    
    return RayResult(FARCLIP, kNoMaterial);
}

float opAO(in vec3 p, in vec3 n)
{
    float value = 0.0;
    float s = 1.0;
    for (int i = 0; i < 3; ++i)
    {
        float stepSize = 0.13;
        float dist = mapScene(p + n * stepSize).dist;
        value += (stepSize - dist) * s;
        s *=0.7;
    }
    value = value;
    return clamp(sqrt((0.9 - value) * sqrt(1.0)), -1.0, 1.0);
}

float opHardShadow(in vec3 p, in vec3 ld)
{
    float value = 0.0;
    float total = 0.0;
    float s = 1.0;
    for (int i = 0; i < 75; ++i)
    {
        float dist = mapScene(p + ld * total * 1.).dist;
        value += dist * s;
        total += dist;
        s *= 0.5;
    }
    value = 1.0 - value;
    vec3 h = p + ld * total;
    float occ = max(0.0, dot(h, ld));
    return clamp(value, 0.0, 1.0);
}

float opSSS(in vec3 ro, in vec3 rd, in vec3 n, float dist, float factor);

vec3 opReflection(float dist, in vec3 p, in vec3 dir, in vec3 n)
{
    vec3 color = vec3(0.2);
    vec3 rd = normalize(reflect(dir, n));
    float ft = max(0.0, dot(rd, n));
    RayResult ray = rayMarch(p, rd);
   
    if (ray.dist < FARCLIP && ft > 0.0)
    {
        Material material = ray.material;
        vec3 hitPoint = p + rd * ray.dist;
        vec3 n = opNormal(hitPoint);
        vec3 nld = normalize(kDirLight.dir);
        vec3 h = normalize(n + nld);
        float diffuse = max(0.0, dot(n, nld));
        float specular = pow(max(0.0, dot(h, n)), material.shininess);
        vec3 sss = opSSS(hitPoint, nld, n, dist, material.sss) * material.diffuse;
        
        if (material.shininess == 0.0) specular = 0.0;
        
        vec3 color = (material.ambient) / 2.0;
        
        #if defined(BLINN_PHONG) && defined(ALL)
        color += 
            ((material.diffuse + kDirLight.color) / 2.0) * diffuse +
            ((material.specular * specular));
        #endif
        
        #if defined(SSS) && defined(ALL)
        color += sss * clamp(material.sss, 0.0, 1.0);
        #endif
            
        return color;
    }
    return kAmbientColor.rgb;
}

float opSSS(in vec3 ro, in vec3 rd, in vec3 n, float dist, float factor)
{
    #if 1
    float value = 0.0;
    vec3 nrd = refract(rd, n, 1.0);
    float s = 1.0;
    #if __VERSION__ == 100
    const int steps = SSS_STEPS;
    #else
    int steps = int(factor);
    #endif
    for (int i = 0; i < steps; ++i)
    {
        float stepSize = (float(i) / float(steps));
        float d = mapScene(ro + nrd * stepSize).dist;
        value += (stepSize - d) * s;
        s *= 0.6;
    }
    value = pow(value, 0.2);
    value = clamp(abs(1.0 - value), 0.0, 1.0000001);
    return value;
    
    #else
    float value = 0.0;
    vec3 nrd = refract(rd, n, 1.0);
    float s = 1.0;
    #if __VERSION__ == 100
    const int steps = SSS_STEPS;
    #else
    int steps = int(factor);
    #endif
    for (int i = 0; i < steps; ++i)
    {
        float stepSize = float(i) / factor;
        float d = mapScene(ro + nrd * stepSize).dist;
        value += (stepSize - d) * s;
        s *=0.75;
    }
    value = pow(value, 0.2);
    value = clamp(1.0 - value, 0.0, 1.0);
    return value;
    #endif
}

float opShadow(in vec3 ro, in vec3 rd, in float mint, in float tmax )
{
    float res = 1.0;
    float t = mint;
    for( int i=0; i<32; i++ )
    {
        float h = mapScene( ro + rd * t ).dist;
        res = min( res, 2.0*h/t );
        t += clamp( h, 0.02, 0.10 );
        if( h<0.001 || t>tmax ) break;
    }
    return clamp( res, 0.0, 1.0 );
}

vec3 shade(float dist, in vec3 ro, in vec3 rd, in vec3 hitPoint, in Material material)
{
    vec3 n = opNormal(hitPoint);
    vec3 nld = normalize(kDirLight.dir);
    vec3 h = normalize(n + nld);
    float diffuse = max(0.0, dot(n, nld));
    float specular = pow(max(0.0, dot(h, n)), material.shininess);
    float ao = opAO(hitPoint, n);
    float shadow = opShadow(hitPoint, nld, 0.1, 0.9);
//    float shadow = opHardShadow(hitPoint, nld);
    vec3 reflectionColor = opReflection(dist, hitPoint, rd, n);
    vec3 sss = opSSS(hitPoint, nld, n, dist, material.sss) * (material.diffuse * 1.2);
    vec3 color = n;
    
    if (material.shininess == 0.0) specular = 0.0;
    
    #if defined(BLINN_PHONG) && defined(ALL)
    color = (material.ambient + kAmbientColor.rgb) / 2.0 +
        ((material.diffuse + kDirLight.color) / 2.0) * diffuse +
        ((material.specular * specular));
    #endif
    #if defined(SCENE_REFLECTION) && defined(ALL)
    color = mix(color, clamp(reflectionColor, vec3(0.0), vec3(1.0)),  clamp(material.reflection, 0.0, 1.0));
    #endif
    #if defined(CUBEMAP_REFLECTION) && defined(ALL)
    color = mix(color, texture(iChannel0, reflect(rd, n)).rgb, material.reflection);
    #endif
    #if defined(AO) && defined(ALL)
    color *= ao;
    #endif
    #if defined(SHADOWS) && defined(ALL)
    color *= shadow * 0.2 + 0.7;
    #endif
    #if defined(SSS) && defined(ALL)
    color += sss * clamp(material.sss, 0.0, 1.0);
    #endif
    return color;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    float ar = iResolution.x / iResolution.y;
    vec3 color = kAmbientColor.rgb;
    vec2 uv = (fragCoord.xy / iResolution.xy - 0.5) * vec2(ar, 1.0);
    vec3 ro = vec3(0.0, 4.0, -9.5);
    vec3 rd = normalize(vec3(uv, 1.0));
    opRotate(ro.xz, (iMouse.x / iResolution.x * 2.0 - 1.0) * 0.75);
    opRotate(rd.xz, (iMouse.x / iResolution.x * 2.0 - 1.0) * 0.75);
    opRotate(rd.yz, 0.4);
    opRotate(kDirLight.dir.xz, 3.6);//iTime * 1.5);
    
    RayResult ray = rayMarch(ro, rd);
    
    if (ray.dist < FARCLIP)
    {
        vec3 hitPoint = ro  + rd * ray.dist;
        color = shade(ray.dist, ro, rd, hitPoint, ray.material);
    }

    #if defined(COLOR)
    color = pow(color, vec3(1.0/1.6));
    #endif
    
    #if defined(VIGNETTE)
    color = mix(color, color * 0.2, max(0.0, pow(length(1.0 * uv / vec2(ar, 1.0)), 2.9)));
    #endif
    
    fragColor = vec4(color, 1.0);
}
// --------[ Original ShaderToy ends here ]---------- //

void main(void)
{
    iTime = time;
    iResolution = vec3(resolution, 0.0);
    iMouse = vec4(mouse * resolution, 0.0, 0.0);

    mainImage(gl_FragColor, gl_FragCoord.xy);
}
