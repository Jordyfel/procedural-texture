// https://iquilezles.org/articles/distfunctions2d/

float sdCircle( vec2 p, float r )
{
	return length(p) - r;
}

float sdRoundedBox( in vec2 p, in vec2 b, in vec4 r )
{
	r.xy = (p.x>0.0)?r.xy : r.zw;
	r.x  = (p.y>0.0)?r.x  : r.y;
	vec2 q = abs(p)-b+r.x;
	return min(max(q.x,q.y),0.0) + length(max(q,0.0)) - r.x;
}

float sdChamferBox( in vec2 p, in vec2 b, in float chamfer )
{
	p = abs(p)-b;

	p = (p.y>p.x) ? p.yx : p.xy;
	p.y += chamfer;

	const float k = 1.0-sqrt(2.0);
	if( p.y<0.0 && p.y+p.x*k<0.0 )
		return p.x;

	if( p.x<p.y )
		return (p.x+p.y)*sqrt(0.5);

	return length(p);
}

float sdBox( in vec2 p, in vec2 b )
{
	vec2 d = abs(p)-b;
	return length(max(d,0.0)) + min(max(d.x,d.y),0.0);
}

float sdRhombus( in vec2 p, in vec2 b )
{
	b.y = -b.y;
	p = abs(p);
	float h = clamp( (dot(b,p)+b.y*b.y)/dot(b,b), 0.0, 1.0 );
	p -= b*vec2(h,h-1.0);
	return length(p)*sign(p.x);
}

float dot2(in vec2 v ) { return dot(v,v); }

float sdTrapezoid( in vec2 p, in float r1, float r2, float he )
{
	vec2 k1 = vec2(r2,he);
	vec2 k2 = vec2(r2-r1,2.0*he);
	p.x = abs(p.x);
	vec2 ca = vec2(p.x-min(p.x,(p.y<0.0)?r1:r2), abs(p.y)-he);
	vec2 cb = p - k1 + k2*clamp( dot(k1-p,k2)/dot2(k2), 0.0, 1.0 );
	float s = (cb.x<0.0 && ca.y<0.0) ? -1.0 : 1.0;
	return s*sqrt( min(dot2(ca),dot2(cb)) );
}

float sdParallelogram( in vec2 p, float wi, float he, float sk )
{
	vec2 e = vec2(sk,he);
	p = (p.y<0.0)?-p:p;
	vec2  w = p - e; w.x -= clamp(w.x,-wi,wi);
	vec2  d = vec2(dot(w,w), -w.y);
	float s = p.x*e.y - p.y*e.x;
	p = (s<0.0)?-p:p;
	vec2  v = p - vec2(wi,0); v -= e*clamp(dot(v,e)/dot(e,e),-1.0,1.0);
	d = min( d, vec2(dot(v,v), wi*he-abs(s)));
	return sqrt(d.x)*sign(-d.y);
}

float sdEquilateralTriangle( in vec2 p, in float r )
{
	const float k = sqrt(3.0);
	p.x = abs(p.x);
	p -= vec2(0.5,0.5*k)*max(p.x+k*p.y,0.0);
	p -= vec2(clamp(p.x,-0.5*r*k,0.5*r*k),-0.5*r);
	return length(p)*sign(-p.y);
}

float sdTriangle( in vec2 p, in vec2 p0, in vec2 p1, in vec2 p2 )
{
	vec2 e0 = p1-p0, e1 = p2-p1, e2 = p0-p2;
	vec2 v0 = p -p0, v1 = p -p1, v2 = p -p2;
	vec2 pq0 = v0 - e0*clamp( dot(v0,e0)/dot(e0,e0), 0.0, 1.0 );
	vec2 pq1 = v1 - e1*clamp( dot(v1,e1)/dot(e1,e1), 0.0, 1.0 );
	vec2 pq2 = v2 - e2*clamp( dot(v2,e2)/dot(e2,e2), 0.0, 1.0 );
	float s = sign( e0.x*e2.y - e0.y*e2.x );
	vec2 d = min(min(vec2(dot(pq0,pq0), s*(v0.x*e0.y-v0.y*e0.x)),
					 vec2(dot(pq1,pq1), s*(v1.x*e1.y-v1.y*e1.x))),
					 vec2(dot(pq2,pq2), s*(v2.x*e2.y-v2.y*e2.x)));
	return -sqrt(d.x)*sign(d.y);
}

float sdUnevenCapsule( vec2 p, float r1, float r2, float h )
{
	p.x = abs(p.x);
	float b = (r1-r2)/h;
	float a = sqrt(1.0-b*b);
	float k = dot(p,vec2(-b,a));
	if( k < 0.0 ) return length(p) - r1;
	if( k > a*h ) return length(p-vec2(0.0,h)) - r2;
	return dot(p, vec2(a,b) ) - r1;
}

float sdStar( in vec2 p, in float r, in int n, in float m)
{
	// next 4 lines can be precomputed for a given shape
	float an = 3.141593/float(n);
	float en = 3.141593/m;  // m is between 2 and n
	vec2  acs = vec2(cos(an),sin(an));
	vec2  ecs = vec2(cos(en),sin(en)); // ecs=vec2(0,1) for regular polygon

	float bn = mod(atan(p.x,p.y),2.0*an) - an;
	p = length(p)*vec2(cos(bn),abs(sin(bn)));
	p -= r*acs;
	p += ecs*clamp( -dot(p,ecs), 0.0, r*acs.y/ecs.y);
	return length(p)*sign(p.x);
}

float sdPie( in vec2 p, in vec2 c, in float r )
{
	p.x = abs(p.x);
	float l = length(p) - r;
	float m = length(p-c*clamp(dot(p,c),0.0,r)); // c=sin/cos of aperture
	return max(l,m*sign(c.y*p.x-c.x*p.y));
}

float sdCutDisk( in vec2 p, in float r, in float h )
{
	float w = sqrt(r*r-h*h); // constant for any given shape
	p.x = abs(p.x);
	float s = max( (h-r)*p.x*p.x+w*w*(h+r-2.0*p.y), h*p.x-w*p.y );
	return (s<0.0) ? length(p)-r :
		   (p.x<w) ? h - p.y     :
					 length(p-vec2(w,h));
}

float sdVesica(vec2 p, float w, float h)
{
	float d = 0.5*(w*w-h*h)/h;
	p = abs(p);
	vec3 c = (w*p.y<d*(p.x-w)) ? vec3(0.0,w,0.0) : vec3(-d,0.0,d+h);
	return length(p-c.yx) - c.z;
}

float sdMoon(vec2 p, float d, float ra, float rb )
{
	p.y = abs(p.y);
	float a = (ra*ra - rb*rb + d*d)/(2.0*d);
	float b = sqrt(max(ra*ra-a*a,0.0));
	if( d*(p.x*b-p.y*a) > d*d*max(b-p.y,0.0) )
		  return length(p-vec2(a,b));
	return max( (length(p          )-ra),
			   -(length(p-vec2(d,0))-rb));
}

float sdRoundedCross( in vec2 p, in float h )
{
	float k = 0.5*(h+1.0/h);
	p = abs(p);
	return ( p.x<1.0 && p.y<p.x*(k-h)+h ) ?
			 k-sqrt(dot2(p-vec2(1,k)))  :
		   sqrt(min(dot2(p-vec2(0,h)),
					dot2(p-vec2(1,0))));
}

float sdHeart( in vec2 p )
{
	p.x = abs(p.x);

	if( p.y+p.x>1.0 )
		return sqrt(dot2(p-vec2(0.25,0.75))) - sqrt(2.0)/4.0;
	return sqrt(min(dot2(p-vec2(0.00,1.00)),
					dot2(p-0.5*max(p.x+p.y,0.0)))) * sign(p.x-p.y);
}

const int N = 10;
float sdPolygon( in vec2[N] v, in vec2 p )
{
	float d = dot(p-v[0],p-v[0]);
	float s = 1.0;
	for( int i=0, j=N-1; i<N; j=i, i++ )
	{
		vec2 e = v[j] - v[i];
		vec2 w =    p - v[i];
		vec2 b = w - e*clamp( dot(w,e)/dot(e,e), 0.0, 1.0 );
		d = min( d, dot(b,b) );
		bvec3 c = bvec3(p.y>=v[i].y,p.y<v[j].y,e.x*w.y>e.y*w.x);
		if( all(c) || all(not(c)) ) s*=-1.0;
	}
	return s*sqrt(d);
}

float sdTunnel( in vec2 p, in vec2 wh )
{
	p.x = abs(p.x); p.y = -p.y;
	vec2 q = p - wh;

	float d1 = dot2(vec2(max(q.x,0.0),q.y));
	q.x = (p.y>0.0) ? q.x : length(p)-wh.x;
	float d2 = dot2(vec2(q.x,max(q.y,0.0)));
	float d = sqrt( min(d1,d2) );

	return (max(q.x,q.y)<0.0) ? -d : d;
}
