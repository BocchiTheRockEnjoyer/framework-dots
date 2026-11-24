import subprocess,math,sys
W,H,P=2880,1920,20
N=58; SS=8; px=N*SS   # logo spans N dots
raw=subprocess.run(['magick','-background','white','-density','1600',sys.argv[1],'-resize',f'{px}x{px}!','-colorspace','Gray','-depth','8','gray:-'],capture_output=True,check=True).stdout
cov=[[sum(255-raw[(y*SS+j)*px+x*SS+i] for j in range(SS) for i in range(SS))/(255*SS*SS) for x in range(N)] for y in range(N)]
ox=(W//P-N)//2; oy=(H//P-N)//2-1
mix=lambda a,b,t:tuple(round(a[i]+(b[i]-a[i])*t) for i in range(3))
out=[]
for j in range(H//P):
    for i in range(W//P):
        x,y=i*P+P/2,j*P+P/2; lx,ly=i-ox,j-oy
        v=cov[ly][lx] if 0<=lx<N and 0<=ly<N else 0
        if v>.35:
            t=(lx+ly)/(2*N)                     # light from the upper left
            r=(8.8-3.6*t)*(.6+.4*v)
            c=mix((255,122,62),(243,83,26),min(1,t*2.2)) if t<.45 else mix((243,83,26),(128,38,10),(t-.45)/.55)
        else:
            d=math.hypot(x-W/2,y-(oy+N/2)*P); g=math.exp(-((d-560)/230)**2) if d>560 else .55*math.exp(-((d-560)/330)**2)
            r=1.4+.9*g; c=mix((30,30,30),(92,33,12),g)
        out.append(f'<circle cx="{x}" cy="{y}" r="{r:.2f}" fill="rgb{c}"/>')
open(sys.argv[2],'w').write(f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}"><rect width="{W}" height="{H}" fill="#0c0c0c"/>{"".join(out)}</svg>')
