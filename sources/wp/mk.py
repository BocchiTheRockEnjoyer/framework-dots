import math,sys
W,H,P=2880,1920,20
out=[]
cx,cy,R=2060,1010,640
def sm(a,b,x):
    t=max(0,min(1,(x-a)/(b-a))); return t*t*(3-2*t)
def mix(a,b,t): return tuple(round(a[i]+(b[i]-a[i])*t) for i in range(3))
for j in range(H//P):
    for i in range(W//P):
        x=i*P+P/2; y=j*P+P/2
        d=math.hypot(x-cx,y-cy)
        # halftone sphere lit from the upper left
        v=0
        if d<R:
            nx,ny=(x-cx)/R,(y-cy)/R; nz=math.sqrt(max(0,1-nx*nx-ny*ny))
            v=max(0,-.62*nx-.55*ny+.56*nz); v=v**1.15*sm(R,R-30,d)
        # rim ring
        ring=math.exp(-((d-R-95)/16)**2)*(.5+.5*math.cos(math.atan2(y-cy,x-cx)-2.3))**1.5
        # rolling wave across the bottom left
        base=1500+150*math.sin(x/420+.6)+70*math.sin(x/170)
        wv=0
        if y>base: wv=math.exp(-(y-base)/190)*(.95-.75*sm(300,2500,x))
        if d<R+150: wv*=sm(R+60,R+150,d)
        v=max(v,ring*.9,wv*.9)
        if v>.05:
            r=1.5+8*min(1,v)**.8
            c=mix((70,22,6),(243,83,26),min(1,v*1.5)); 
            if v>.8: c=mix(c,(255,130,70),(v-.8)/.2*.7)
        else: r,c=1.4,(30,30,30)
        out.append(f'<circle cx="{x}" cy="{y}" r="{r:.2f}" fill="rgb{c}"/>')
open(sys.argv[1],'w').write(f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}"><rect width="{W}" height="{H}" fill="#0c0c0c"/>{"".join(out)}</svg>')
