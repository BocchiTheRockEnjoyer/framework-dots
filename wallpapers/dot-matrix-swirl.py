import numpy as np,sys,subprocess
P=16; GW,GH=180,120; W,H=GW*P,GH*P; FPS=30; SEC=24; N=FPS*SEC
rng=np.random.default_rng(7)
M=2600
cx,cy=.27*GW,.50*GH
# each particle lives one loop (or 2-3 shorter lives), drifting outward while orbiting; fades at both ends so the loop is seamless
life=rng.integers(1,4,M); ph=rng.random(M)
r0=14+rng.gamma(2.2,17,M); dr=8+rng.random(M)*26
th=rng.random(M)*2*np.pi
w=(1.15+rng.random(M)*.35)*np.pi*(34/(r0+16))**.75/ (life**.35)*1.7
tilt=-.32; sq=.62
wob=rng.random(M)*2*np.pi; amp=.35+.65*rng.random(M)**1.6
def pos(u):
    r=r0+dr*u; a=th+w*u*2
    x=r*np.cos(a); y=r*np.sin(a)*sq+1.6*np.sin(wob+2*np.pi*u)
    c,s=np.cos(tilt),np.sin(tilt)
    return cx+x*c-y*s*1.05, cy+x*s+y*c, r
yy,xx=np.mgrid[0:GH,0:GW]
# template lookup: 32 brightness levels -> 16x16 RGB dot
L=40; c=(np.arange(P)+.5-P/2); d=np.hypot(*np.meshgrid(c,c)); T=np.zeros((L,P,P,3),np.uint8)
for i in range(L):
    v=i/(L-1); rad=1.5+5.6*v**.6
    cov=np.clip(rad+.5-d,0,1)[...,None]
    stops=np.array([[26,24,24],[92,26,8],[243,83,26],[255,140,84]],float); t=np.array([0,.22,.68,1])
    col=np.array([np.interp(v,t,stops[:,k]) for k in range(3)])
    T[i]=np.clip(np.array([9,9,9])*(1-cov)+col*cov,0,255)
def frame(f):
    G=np.zeros((GH+4)*(GW+4))
    for k,g in ((0,1),(1,.62),(2,.38),(3,.22),(4,.12)):      # short trail
        u=(ph+life*((f-k*1.6)/N))%1
        x,y,r=pos(u)
        b=amp*g*np.clip(np.sin(np.pi*u),0,1)**.7*np.clip((r-9)/10,0,1)
        b*=np.clip(1.15-x/GW*.62,.25,1)
        ix=np.floor(x).astype(int); iy=np.floor(y).astype(int); fx=x-ix; fy=y-iy
        for dx,wx in((0,1-fx),(1,fx)):
            for dy,wy in((0,1-fy),(1,fy)):
                X=ix+dx+2; Y=iy+dy+2; ok=(X>=0)&(X<GW+4)&(Y>=0)&(Y<GH+4)
                np.add.at(G,(Y[ok]*(GW+4)+X[ok]),(b*wx*wy)[ok])
    G=G.reshape(GH+4,GW+4)[2:-2,2:-2]
    V=1-np.exp(-1.9*G)
    q=np.clip((V*(L-1)).round(),0,L-1).astype(int)
    return T[q].transpose(0,2,1,3,4).reshape(H,W,3)
if sys.argv[1]=='still':
    from subprocess import run
    a=frame(int(sys.argv[2])); open(sys.argv[3],'wb').write(b'P6 %d %d 255\n'%(W,H)+a.tobytes())
else:
    p=subprocess.Popen(['ffmpeg','-loglevel','error','-y','-f','rawvideo','-pix_fmt','rgb24','-s',f'{W}x{H}','-r',str(FPS),'-i','-','-vf','scale=out_color_matrix=bt709:out_range=tv','-c:v','libx264','-preset','medium','-crf','17','-pix_fmt','yuv420p','-colorspace','bt709','-color_primaries','bt709','-color_trc','bt709','-g','60','-movflags','+faststart',sys.argv[2]],stdin=subprocess.PIPE)
    for f in range(N): p.stdin.write(frame(f).tobytes())
    p.stdin.close(); sys.exit(p.wait())
