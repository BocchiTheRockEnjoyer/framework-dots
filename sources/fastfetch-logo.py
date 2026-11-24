"""Draws the dot-matrix fastfetch logo (PNG for kitty, braille text for other terminals) from the logo's outline."""
import sys,re,subprocess
src,png,txt=sys.argv[1:]
# coverage of the vector logo, sampled finely
N=1024
raw=subprocess.run(['magick','-background','none','-density','3000',src,'-trim','+repage','-resize',f'{N}x{N}','-gravity','center','-background','none','-extent',f'{N}x{N}','-alpha','extract','-depth','8','gray:-'],stdout=subprocess.PIPE,check=True).stdout
def cov(x0,y0,x1,y1):
    X0,X1,Y0,Y1=[int(max(0,min(N,v*N))) for v in(x0,x1,y0,y1)]
    if X1<=X0 or Y1<=Y0: return 0
    st=max(1,(X1-X0)//6); n=s=0
    for y in range(Y0,Y1,st):
        for x in range(X0,X1,st): s+=raw[y*N+x]; n+=1
    return s/n/255
G=46; pad=2; P=20; W=(G+2*pad)*P
o=[]
for j in range(G+2*pad):
    for i in range(G+2*pad):
        c=cov((i-pad)/G,(j-pad)/G,(i-pad+1)/G,(j-pad+1)/G) if pad<=i<G+pad and pad<=j<G+pad else 0
        if c>=.5:
            t=j/(G+2*pad); a,b=(255,122,72),(243,83,26); k=min(1,t*1.6)
            col='#%02x%02x%02x'%tuple(round(a[q]+(b[q]-a[q])*k) for q in range(3)); r=.43
        else: col,r='#343434',.24
        o.append(f'<circle cx="{(i+.5)*P}" cy="{(j+.5)*P}" r="{r*P}" fill="{col}"/>')
# a 36x15-cell box in Space Mono is this shape, so the logo isn't stretched
H=round(W*(15*1.481)/(36*.612)); dy=(H-W)/2
svg=f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 {-dy} {W} {H}">{"".join(o)}</svg>'
subprocess.run(['magick','-background','none','svg:-','-strip','-define','png:compression-level=9',f'PNG32:{png}'],input=svg.encode(),check=True)
# braille: 2x4 dots a cell; fewer rows than columns because cells are tall
cols,rows=32,13
dw,dh=cols*2,rows*4
L=[]
B=[[0x01,0x08],[0x02,0x10],[0x04,0x20],[0x40,0x80]]
for r in range(rows):
    s=''
    for c in range(cols):
        v=0
        for y in range(4):
            for x in range(2):
                i,j=c*2+x,r*4+y
                if cov(i/dw,j/dh,(i+1)/dw,(j+1)/dh)>=.5: v|=B[y][x]
        s+=chr(0x2800+v) if v else ' '
    L.append('$1'+s.rstrip())
open(txt,'w').write('\n'.join(L)+'\n'); print('\n'.join(x[2:] for x in L))
